import SwiftUI
import SwiftData

struct AdherenceDataView: View {
    @Environment(\.modelContext) private var modelContext
       @EnvironmentObject var authManager: AuthManager // 🆕 Inject AuthManager
       
       @Query private var reminders: [Reminder]
       @Query(sort: \Medicine.lastModifiedDate, order: .reverse)
       private var allMedicines: [Medicine]

       @Query
       private var allDoseLogEvents: [DoseLogEvent]

       

      
       // 👇 Filtered versions for logic
       var medicines: [Medicine] {
           allMedicines.filter { medicine in
               medicine.userSettings?.userID == authManager.currentUserUID &&
               medicine.isActive &&
               medicine.isCurrentlyActiveBasedOnDates &&
               !medicine.hasPeriodEnded()
           }
       }

       var doseLogEvents: [DoseLogEvent] {
           allDoseLogEvents.filter { event in
               event.dateRecorded >= todayStart &&
               event.dateRecorded < tomorrowStart &&
               event.medicine?.userSettings?.userID == authManager.currentUserUID
           }
       }

       @State private var overallDailyMedicineAdherence: Int = 0
       @State private var refreshID = UUID()

       // Compute date boundaries outside the predicate
       private let todayStart = Calendar.current.startOfDay(for: Date())
       private let tomorrowStart = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!


    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.green)

            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(overallDailyMedicineAdherence)%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Daily Adherence")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
            .padding()
        }
        .fixedSize(horizontal: false, vertical: true)
        .id(refreshID)
        .onAppear {
            print("🔍 AdherenceDataView appeared at \(Date())")
            checkForMissedDoses()
            recalculateAdherence()
        }
        .onChange(of: medicines) {
            print("🔍 Medicines changed, recalculating adherence")
            checkForMissedDoses()
            recalculateAdherence()
        }
        .onChange(of: reminders) {
            print("🔍 Reminders changed, recalculating adherence")
            recalculateAdherence()
        }
        .onChange(of: doseLogEvents) {
            print("🔍 DoseLogEvents changed: \(doseLogEvents.map { "\($0.medicine?.name ?? "nil"): \($0.isTaken ? "Taken" : "Missed")" })")
            recalculateAdherence()
        }
        .onChange(of: authManager.currentUserUID) {
            print("🔍 User UID changed to \(authManager.currentUserUID), recalculating adherence")
            checkForMissedDoses()
            recalculateAdherence()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { notification in
            print("🔍 Received NSManagedObjectContextDidSave: \(notification.userInfo ?? [:])")
            recalculateAdherence()
        }
        .onReceive(Timer.publish(every: 10, on: .main, in: .common).autoconnect()) { _ in
            print("🔍 Timer fired at \(Date()), checking for missed doses")
            checkForMissedDoses()
            recalculateAdherence()
        }
    }

    private func checkForMissedDoses() {
        let calendar = Calendar.current
        let today = Date()
        let todayStartOfDay = calendar.startOfDay(for: today)
        var changed = false

        print("🔍 Checking for missed doses at \(today) for \(medicines.count) medicines")

        for med in medicines {
            if let scheduledDoses = med.scheduledDoses {
                for dose in scheduledDoses {
                    let components = calendar.dateComponents([.hour, .minute], from: dose.time)
                    guard let doseTimeToday = calendar.date(bySettingHour: components.hour!,
                                                            minute: components.minute!,
                                                            second: 0,
                                                            of: today) else {
                        print("⚠️ Invalid dose time for \(med.name), dose \(dose.id)")
                        continue
                    }
                    
                    // Check if dose is overdue (past its time and not pending)
                    if doseTimeToday <= today && !dose.isPending {
                        // Check if a DoseLogEvent exists for this dose today
                        let existingEvent = doseLogEvents.first { event in
                            event.medicine?.id == med.id &&
                            event.scheduledDose?.id == dose.id &&
                            calendar.isDate(event.dateRecorded, inSameDayAs: todayStartOfDay)
                        }
                        
                        // If no event exists, create a missed dose event
                        if existingEvent == nil {
                            let newEvent = DoseLogEvent(
                                id: UUID(),
                                timestamp: doseTimeToday,
                                isTaken: false,
                                scheduledDose: dose,
                                medicine: med,
                                dateRecorded: todayStartOfDay
                            )
                            newEvent.userSettings = med.userSettings
                            med.doseLogEvents = med.doseLogEvents ?? []
                            med.doseLogEvents?.append(newEvent)
                            modelContext.insert(newEvent)
                            changed = true
                            print("✅ Created missed DoseLogEvent for \(med.name) at \(MedicineDetailCardView.timeFormatter.string(from: dose.time))")
                        }
                    }
                }
            }
        }

        if changed {
            do {
                try modelContext.save()
                NotificationCenter.default.post(name: .NSManagedObjectContextDidSave, object: modelContext)
                refreshID = UUID() // Force view refresh
                print("✅ Saved missed dose events")
            } catch {
                print("⚠️ Error saving missed dose events: \(error)")
            }
        } else {
            print("🔍 No new missed doses found")
        }
    }

    private func recalculateAdherence() {
        var totalDosesDueToday = 0
        var totalDosesTakenToday = 0

        let calendar = Calendar.current
        let today = Date()
        let todayStartOfDay = calendar.startOfDay(for: today)

        print("🔍 Recalculating adherence for \(medicines.count) medicines")

        for med in medicines {
            med.ensureDoseLogEvents(in: modelContext)
            med.deleteOldDoseLogEvents(in: modelContext)

            if let scheduledDoses = med.scheduledDoses {
                // Count doses due today
                let dosesDueToday = scheduledDoses.filter { dose in
                    let components = calendar.dateComponents([.hour, .minute], from: dose.time)
                    guard let doseTimeToday = calendar.date(bySettingHour: components.hour!,
                                                            minute: components.minute!,
                                                            second: 0,
                                                            of: today) else { return false }
                    return doseTimeToday <= today
                }

                totalDosesDueToday += dosesDueToday.count

                // Count taken doses for today's scheduled doses
                for dose in dosesDueToday {
                    let takenEvent = doseLogEvents.first { event in
                        event.medicine?.id == med.id &&
                        event.scheduledDose?.id == dose.id &&
                        calendar.isDate(event.dateRecorded, inSameDayAs: todayStartOfDay) &&
                        event.isTaken
                    }
                    if takenEvent != nil {
                        totalDosesTakenToday += 1
                    }
                }

                print("🔍 Medicine: \(med.name), Doses due: \(dosesDueToday.count), Taken: \(doseLogEvents.filter { $0.medicine?.id == med.id && $0.isTaken }.count)")
            }
        }

        // Ensure taken doses don't exceed due doses
        totalDosesTakenToday = min(totalDosesTakenToday, totalDosesDueToday)
        overallDailyMedicineAdherence = totalDosesDueToday > 0 ? Int(Double(totalDosesTakenToday) / Double(totalDosesDueToday) * 100) : 100
        print("🔍 Adherence calculated: \(overallDailyMedicineAdherence)% (Taken: \(totalDosesTakenToday), Due: \(totalDosesDueToday))")

        for reminder in reminders {
            reminder.resetCompletedTimesIfNeeded()
        }

        do {
            try modelContext.save()
            refreshID = UUID()
        } catch {
            print("⚠️ Error saving model context: \(error)")
        }
    }
}
