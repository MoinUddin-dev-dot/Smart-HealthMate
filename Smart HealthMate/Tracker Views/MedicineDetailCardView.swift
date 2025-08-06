////
////  MedicineDetailCardView.swift
////  Smart HealthMate
////
////  Created by Moin on 6/18/25.
////

import SwiftUI
import SwiftData

import SwiftUI
import SwiftData


//
//  MedicineDetailCardView.swift
//  Smart HealthMate
//
//  Created by Moin on 6/18/25.
import SwiftUI
import SwiftData

struct MedicineDetailCardView: View {
    @Bindable var medicine: Medicine
    @Environment(\.modelContext) private var modelContext

    var onEdit: ((Medicine) -> Void)?
    var onDelete: ((UUID) -> Void)?

     static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private static let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(medicine.isActive ? Color.blue : Color.gray)
                .frame(width: 6)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Image(systemName: "pill.fill")
                        .font(.title2)
                        .foregroundColor(medicine.isActive ? Color.blue : Color.gray)
                        .frame(width: 40, height: 40)
                        .background(medicine.isActive ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                        .cornerRadius(8)

                    VStack(alignment: .leading) {
                        Text(medicine.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(1)

                        Text(medicine.dosage)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Button(action: {
                        onEdit?(medicine)
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                    .padding(.trailing, 5)

                    Button(action: {
                        onDelete?(medicine.id)
                    }) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                    }
                }
                .padding(.bottom, 5)

                Text(medicine.purpose)
                    .font(.footnote)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(5)

                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Period: \(medicine.startDate, formatter: Self.itemFormatter) - \(medicine.endDate, formatter: Self.itemFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(medicine.displayTimingFrequency)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 5)

                HStack {
                    if medicine.isActive {
                        Text("Active")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(5)
                    } else {
                        Text("Inactive")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(5)
                    }
                    if !medicine.isActive, let inactiveDate = medicine.inactiveDate {
                        Text("Since: \(inactiveDate, formatter: Self.itemFormatter)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    } else if !medicine.isActive && medicine.startDate > Date() {
                        Text("Starts: \(medicine.startDate, formatter: Self.itemFormatter)")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.bottom, 5)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Scheduled Doses:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    if let sortedDoses = medicine.scheduledDoses?.sorted(by: { $0.time < $1.time }) {
                        ForEach(sortedDoses) { scheduledDose in
                            HStack {
                                Text(scheduledDose.time, formatter: Self.timeFormatter)
                                    .font(.subheadline)
                                    .foregroundColor(getDoseStatusToday(for: scheduledDose).color)

                                Spacer()

                                getDoseStatusToday(for: scheduledDose).view

                                Button(action: {
                                    toggleDoseStatus(for: scheduledDose)
                                }) {
                                    Text(isDoseTakenToday(for: scheduledDose) ? "Untake" : "Mark Taken")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(isDoseTakenToday(for: scheduledDose) ? Color.orange : Color.blue)
                                        .cornerRadius(6)
                                }
                                .accessibilityIdentifier("taken")
                                .disabled(scheduledDose.isPending && !isDoseTakenToday(for: scheduledDose))
                            }
                        }
                    } else {
                        Text("No scheduled doses for this medicine.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 10)
            }
            .padding()
            .background(Color.white)
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func isDoseTakenToday(for scheduledDose: ScheduledDose) -> Bool {
        let calendar = Calendar.current
        let todayStartOfDay = calendar.startOfDay(for: Date())
        
        return medicine.doseLogEvents?.contains(where: { event in
            calendar.isDate(event.dateRecorded, inSameDayAs: todayStartOfDay) &&
            event.scheduledDose?.id == scheduledDose.id &&
            event.isTaken
        }) ?? false
    }

    private func getDoseStatusToday(for scheduledDose: ScheduledDose) -> (color: Color, view: some View) {
        let calendar = Calendar.current
        let today = Date()
        let todayStartOfDay = calendar.startOfDay(for: today)
        let components = calendar.dateComponents([.hour, .minute], from: scheduledDose.time)
        guard let doseTimeToday = calendar.date(bySettingHour: components.hour!,
                                                minute: components.minute!,
                                                second: 0,
                                                of: today) else {
            return (.gray, HStack(spacing: 5) {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundStyle(.gray)
                Text("Unknown")
                    .foregroundStyle(.gray)
            })
        }

        if scheduledDose.isPending {
            return (
                .primary,
                HStack(spacing: 5) {
                    Image(systemName: "hourglass")
                        .foregroundStyle(.orange)
                    Text("Pending")
                        .foregroundStyle(.orange)
                }
            )
        } else if isDoseTakenToday(for: scheduledDose) {
            return (
                .green,
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Taken")
                        .foregroundStyle(.green)
                }
            )
        } else {
            return (
                .red,
                HStack(spacing: 5) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                    Text("Missed")
                        .foregroundStyle(.red)
                }
            )
        }
    }

    private func toggleDoseStatus(for scheduledDose: ScheduledDose) {
        let calendar = Calendar.current
        let today = Date()
        let todayStartOfDay = calendar.startOfDay(for: today)

        if let existingEvent = medicine.doseLogEvents?.first(where: { event in
            calendar.isDate(event.dateRecorded, inSameDayAs: todayStartOfDay) && event.scheduledDose?.id == scheduledDose.id
        }) {
            existingEvent.isTaken.toggle()
            existingEvent.timestamp = today
            print("hqhq\(existingEvent.timestamp)")
        } else {
            let components = calendar.dateComponents([.hour, .minute], from: scheduledDose.time)
            let doseTimeToday = calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: today) ?? today
            let newEvent = DoseLogEvent(
                id: UUID(),
                timestamp: doseTimeToday,
                isTaken: true,
                scheduledDose: scheduledDose,
                medicine: medicine,
                dateRecorded: todayStartOfDay
            )
            newEvent.userSettings = medicine.userSettings
            medicine.doseLogEvents = medicine.doseLogEvents ?? []
            medicine.doseLogEvents?.append(newEvent)
            modelContext.insert(newEvent)
        }

        do {
            try modelContext.save()
            NotificationCenter.default.post(name: .NSManagedObjectContextDidSave, object: modelContext)
            print("✅ Toggled dose status for \(medicine.name) at \(Self.timeFormatter.string(from: scheduledDose.time)) to \(isDoseTakenToday(for: scheduledDose) ? "Taken" : "Not Taken")")
        } catch {
            print("⚠️ Error saving dose log event: \(error)")
        }
    }
}

// MARK: - Medicine Struct (Data model for MedicineListView)
import Foundation
import SwiftUI // Only for Color.darker() example, remove if not needed here

// MARK: - Medicine Struct (Data model for MedicineListView)
// Add Codable conformance for easy saving/loading (e.g., to UserDefaults or a database)

// MARK: - Medicine Model
// MARK: - Medicine Model
import Foundation
import SwiftUI // Only for Color.darker() example, remove if not needed here
import SwiftData

@Model
final class Medicine: Equatable {
    @Attribute(.unique) var id: UUID
    var name: String
    var purpose: String
    var dosage: String
    var startDate: Date
    var endDate: Date
    var isActive: Bool
    var inactiveDate: Date?
    var lastModifiedDate: Date

    var userSettings: UserSettings? // Assuming UserSettings model exists

    // Relation to ScheduledDose (templates).
    // .cascade means if a Medicine is deleted, all its associated ScheduledDoses are also deleted.
    @Relationship(deleteRule: .cascade, inverse: \ScheduledDose.medicine)
    var scheduledDoses: [ScheduledDose]? // List of all dose *templates* for this medicine.

    // NEW Relation to DoseLogEvent.
    // .cascade means if a Medicine is deleted, all its associated DoseLogEvents are also deleted.
    @Relationship(deleteRule: .cascade, inverse: \DoseLogEvent.medicine)
    var doseLogEvents: [DoseLogEvent]? // All actual dose log events (taken or missed) for this medicine

    // 🧠 Computed Properties

    /// Aaj ki date startDate...endDate mein hai toh true.
    var isCurrentlyActiveBasedOnDates: Bool {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        let normalizedStartDate = calendar.startOfDay(for: startDate)
        let normalizedEndDate = calendar.startOfDay(for: endDate)

        return normalizedStartDate <= startOfToday && normalizedEndDate >= startOfToday
    }

    /// Aaj se future mein start hoga.
    var isFutureMedicine: Bool {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let normalizedStartDate = calendar.startOfDay(for: startDate)

        return normalizedStartDate > startOfToday
    }

    /// Agar endDate aaj se pehle hai, tou return true.
    func hasPeriodEnded() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let normalizedEndDate = calendar.startOfDay(for: endDate)

        return normalizedEndDate < startOfToday
    }

    /// Checks if any dose for today was missed (no corresponding DoseLogEvent by now marked as taken)
    var hasMissedDoseToday: Bool {
        let calendar = Calendar.current
        let now = Date()
        let todayStartOfDay = calendar.startOfDay(for: now)

        guard let scheduledDoses = scheduledDoses else { return false }

        for scheduledDose in scheduledDoses {
            // Get the scheduled time for today
            let doseTimeComponents = calendar.dateComponents([.hour, .minute], from: scheduledDose.time)
            guard let scheduledDateTimeToday = calendar.date(bySettingHour: doseTimeComponents.hour!,
                                                             minute: doseTimeComponents.minute!,
                                                             second: 0,
                                                             of: now) else { continue }

            // If the scheduled time has passed
            if scheduledDateTimeToday < now {
                // Check if a DoseLogEvent exists for this scheduledDose on today, marked as taken
                let doseWasTakenToday = doseLogEvents?.contains(where: { event in
                    calendar.isDate(event.dateRecorded, inSameDayAs: todayStartOfDay) &&
                    event.scheduledDose?.id == scheduledDose.id &&
                    event.isTaken == true
                }) ?? false

                if !doseWasTakenToday {
                    return true // Missed dose found for today (past due and not taken)
                }
            }
        }
        return false // No missed doses found for today
    }

    /// "Once a day", "No specific times", or "X times a day".
    var displayTimingFrequency: String {
        guard let doses = scheduledDoses else { return "No specific times" }
        if doses.isEmpty {
            return "No specific times"
        } else if doses.count == 1 {
            return "Once a day"
        } else {
            return "\(doses.count) times a day"
        }
    }

    // 🔧 Initializers

    /// Full designated init. scheduledDoses are set externally after creation.
    init(id: UUID = UUID(),
         name: String,
         purpose: String,
         dosage: String,
         startDate: Date = Date(),
         endDate: Date,
         isActive: Bool = true,
         inactiveDate: Date? = nil,
         lastModifiedDate: Date = Date(),
         scheduledDoses: [ScheduledDose]? = nil) { // Allow passing doses directly
        self.id = id
        self.name = name
        self.purpose = purpose
        self.dosage = dosage
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.inactiveDate = inactiveDate
        self.lastModifiedDate = lastModifiedDate
        self.scheduledDoses = scheduledDoses
    }

    /// Convenience initializer: Now takes an array of Date for timings directly.
    convenience init(name: String,
                     purpose: String,
                     dosage: String,
                     timings: [Date], // Changed from timingString to [Date]
                     startDate: Date = Date(),
                     endDate: Date,
                     isActive: Bool = true,
                     inactiveDate: Date? = nil) {
        self.init(id: UUID(),
                  name: name,
                  purpose: purpose,
                  dosage: dosage,
                  startDate: startDate,
                  endDate: endDate,
                  isActive: isActive,
                  inactiveDate: inactiveDate,
                  lastModifiedDate: Date()) // Set lastModifiedDate to now

        // Create ScheduledDose objects from the provided Date array
        self.scheduledDoses = timings.sorted().map { time in
            let newDose = ScheduledDose(time: time)
            newDose.medicine = self // Set the inverse relationship
            return newDose
        }
    }

    // Equatable conformance
    static func == (lhs: Medicine, rhs: Medicine) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - ScheduledDose Model
@Model
final class ScheduledDose: Identifiable, Equatable {
    @Attribute(.unique) var id: UUID
    var time: Date // The time this dose is scheduled for *each day*.

    // Inverse relationship to Medicine.
    var medicine: Medicine? // Which Medicine object this dose template belongs to.

    // NEW: Relation to DoseLogEvent. A ScheduledDose can have many DoseLogEvents over time.
    @Relationship(deleteRule: .cascade, inverse: \DoseLogEvent.scheduledDose)
    var doseLogEvents: [DoseLogEvent]? // Renamed from doseTakenEvents

    // 🧠 Computed Property
    /// Agar dose ka time abhi baaki hai (future mein), tou true.
    var isPending: Bool {
        let calendar = Calendar.current
        let now = Date()

        // Get only hour and minute components from the scheduled dose time
        let doseTimeComponents = calendar.dateComponents([.hour, .minute], from: self.time)
        guard let doseTimeOnToday = calendar.date(bySettingHour: doseTimeComponents.hour!,
                                                 minute: doseTimeComponents.minute!,
                                                 second: 0,
                                                 of: now) else { return false }

        // A dose is pending if its time today is in the future relative to 'now'
        return calendar.compare(doseTimeOnToday, to: now, toGranularity: .minute) == .orderedDescending
    }

    // 🔧 Initializer
    init(id: UUID = UUID(), time: Date) {
        self.id = id
        self.time = time
    }

    // Equatable conformance
    static func == (lhs: ScheduledDose, rhs: ScheduledDose) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - DoseLogEvent Model
@Model
final class DoseLogEvent: Identifiable, Equatable {
    @Attribute(.unique) var id: UUID
    var timestamp: Date          // The exact time the dose was taken OR the scheduled time if missed/pending.
    var isTaken: Bool            // TRUE if dose was taken, FALSE if missed or pending.
    var dateRecorded: Date       // The calendar day (start of day) this event pertains to. Useful for daily grouping.

    
    // Inverse relationships
    var scheduledDose: ScheduledDose? // Which scheduled dose template this event is for.
    var medicine: Medicine?           // Which medicine this event belongs to (for easier queries).
    var userSettings: UserSettings? 

    // Initializer
    init(id: UUID = UUID(), timestamp: Date, isTaken: Bool, scheduledDose: ScheduledDose? = nil, medicine: Medicine? = nil, dateRecorded: Date) {
        self.id = id
        self.timestamp = timestamp
        self.isTaken = isTaken
        self.scheduledDose = scheduledDose
        self.medicine = medicine
        self.dateRecorded = dateRecorded // Store the start of the day
    }

    static func == (lhs: DoseLogEvent, rhs: DoseLogEvent) -> Bool {
        lhs.id == rhs.id
    }
}


// MARK: - Medicine Extension (for adherence and logging logic)
import Foundation
import SwiftData

extension Medicine {
    // 🆕 Function to ensure all past-due doses for active period are logged.
    // This should be called regularly, e.g., on app launch or when a medicine is viewed.
    func ensureDoseLogEvents(in context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        guard self.isActive && self.isCurrentlyActiveBasedOnDates else { return } // Only process active medicines

        guard let scheduledDoses = self.scheduledDoses, !scheduledDoses.isEmpty else { return }

        // Calculate the maximum number of days to look back for logging missed doses
        // Max 31 days to align with deletion policy
        guard let thirtyOneDaysAgo = calendar.date(byAdding: .day, value: -30, to: startOfToday) else { return }

        // Iterate from the medicine's start date (or 31 days ago, whichever is later) up to today
        var currentDate = max(calendar.startOfDay(for: self.startDate), thirtyOneDaysAgo)

        while currentDate <= startOfToday {
            for scheduledDose in scheduledDoses {
                let doseTimeComponents = calendar.dateComponents([.hour, .minute, .second], from: scheduledDose.time)
                guard let scheduledDoseDateTime = calendar.date(bySettingHour: doseTimeComponents.hour ?? 0,
                                                                 minute: doseTimeComponents.minute ?? 0,
                                                                 second: doseTimeComponents.second ?? 0,
                                                                 of: currentDate) else { continue }

                // Determine the reference time for "past due"
                let referenceTimeForDose = (calendar.isDateInToday(currentDate)) ? now : scheduledDoseDateTime.addingTimeInterval(1) // Just past the scheduled time if it's a past day

                // Only log if the scheduled time has passed and the medicine was active on that day
                if scheduledDoseDateTime < referenceTimeForDose {
                    // Check if a DoseLogEvent already exists for this scheduledDose on this specific `currentDate`
                    let existingLog = self.doseLogEvents?.first(where: { event in
                        calendar.isDate(event.dateRecorded, inSameDayAs: currentDate) && event.scheduledDose?.id == scheduledDose.id
                    })

                    if existingLog == nil {
                        // If no log exists, create a new DoseLogEvent marked as missed (isTaken: false)
                        let missedLog = DoseLogEvent(timestamp: scheduledDoseDateTime, isTaken: false, scheduledDose: scheduledDose, medicine: self, dateRecorded: currentDate)
                        context.insert(missedLog)
                    }
                }
            }
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDay
        }
    }

    // 🆕 Function to delete DoseLogEvents older than 31 days
    func deleteOldDoseLogEvents(in context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        guard let thirtyOneDaysAgo = calendar.date(byAdding: .day, value: -31, to: now) else { return }
        let cutoffDate = calendar.startOfDay(for: thirtyOneDaysAgo) // Events for this day and before should be deleted

        // Filter and delete events older than 31 days from today
        self.doseLogEvents?
            .filter { $0.dateRecorded < cutoffDate }
            .forEach { oldEvent in
                context.delete(oldEvent)
            }
    }

    /// Calculates the adherence for this specific medicine over a given date range.
    /// - Parameters:
    ///   - startDate: The beginning of the date range (inclusive).
    ///   - endDate: The end of the date range (inclusive).
    /// - Returns: A Double representing the adherence percentage (0.0 to 1.0), or nil if no doses were due.
    func calculateAdherence(from startDate: Date, to endDate: Date) -> Double? {
        guard let scheduledDoses = scheduledDoses, !scheduledDoses.isEmpty else { return nil }
        guard let doseLogEvents = doseLogEvents else { return nil } // Use doseLogEvents

        let calendar = Calendar.current
        let normalizedStartDate = calendar.startOfDay(for: startDate)
        let normalizedEndDate = calendar.startOfDay(for: endDate)
        let now = Date() // For checking if today's doses are past due

        var dosesDue = 0
        var dosesTaken = 0

        // Iterate through each day in the range
        var currentDate = normalizedStartDate
        while currentDate <= normalizedEndDate {
            // Check if the medicine itself was active on this specific date
            let medicineStartsTodayOrBefore = calendar.compare(self.startDate, to: currentDate, toGranularity: .day) != .orderedDescending
            let medicineEndsTodayOrAfter = calendar.compare(self.endDate, to: currentDate, toGranularity: .day) != .orderedAscending

            if self.isActive && medicineStartsTodayOrBefore && medicineEndsTodayOrAfter {
                for scheduledDose in scheduledDoses {
                    // Create a full Date object for the scheduled dose on `currentDate`
                    let doseTimeComponents = calendar.dateComponents([.hour, .minute, .second], from: scheduledDose.time)
                    guard let scheduledDoseDateTime = calendar.date(bySettingHour: doseTimeComponents.hour ?? 0,
                                                                     minute: doseTimeComponents.minute ?? 0,
                                                                     second: doseTimeComponents.second ?? 0,
                                                                     of: currentDate) else { continue }

                    // Only count doses that were due by the end of 'currentDate'
                    // or, if 'currentDate' is 'now', only count doses due up to 'now'
                    let referenceDateForComparison = (calendar.isDateInToday(currentDate)) ? now : calendar.date(bySettingHour: 23, minute: 59, second: 59, of: currentDate) ?? currentDate

                    if scheduledDoseDateTime <= referenceDateForComparison {
                        dosesDue += 1
                        // Check if a DoseLogEvent exists for this scheduledDose on this specific currentDate, marked as taken
                        let wasTaken = doseLogEvents.contains { event in
                            calendar.isDate(event.dateRecorded, inSameDayAs: currentDate) && event.scheduledDose?.id == scheduledDose.id && event.isTaken == true
                        }
                        if wasTaken {
                            dosesTaken += 1
                        }
                    }
                }
            }
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDay
        }

        guard dosesDue > 0 else { return nil } // Avoid division by zero if no doses were due
        return Double(dosesTaken) / Double(dosesDue)
    }

    /// Calculates the daily adherence for this medicine.
    /// - Returns: A Double representing the adherence percentage (0.0 to 1.0), or nil if no doses were due today.
    var dailyAdherence: Double? {
        let calendar = Calendar.current
        let today = Date()
        let todayStartOfDay = calendar.startOfDay(for: today)

        // Check if the medicine is active and its period covers today
        if !self.isActive || self.hasPeriodEnded() || self.isFutureMedicine {
            return nil // Not applicable for today
        }

        guard let scheduledDoses = scheduledDoses, !scheduledDoses.isEmpty else { return nil }
        guard let doseLogEvents = doseLogEvents else { return nil } // Use doseLogEvents

        var dosesDueToday = 0
        var dosesTakenToday = 0

        for scheduledDose in scheduledDoses {
            let doseTimeComponents = calendar.dateComponents([.hour, .minute, .second], from: scheduledDose.time)
            guard let scheduledDoseDateTime = calendar.date(bySettingHour: doseTimeComponents.hour ?? 0,
                                                             minute: doseTimeComponents.minute ?? 0,
                                                             second: doseTimeComponents.second ?? 0,
                                                             of: today) else { continue }

            // Only count doses that were due by 'now'
            if scheduledDoseDateTime <= today {
                dosesDueToday += 1
                // Check if a DoseLogEvent exists for this scheduledDose on today, marked as taken
                let wasTaken = doseLogEvents.contains { event in
                    calendar.isDate(event.dateRecorded, inSameDayAs: todayStartOfDay) && event.scheduledDose?.id == scheduledDose.id && event.isTaken == true
                }
                if wasTaken {
                    dosesTakenToday += 1
                }
            }
        }

        guard dosesDueToday > 0 else { return nil }
        return Double(dosesTakenToday) / Double(dosesDueToday)
    }

    func calculateWeeklyAdherence() -> Double? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today) else { return nil } // Today + 6 previous days = 7 days
        return calculateAdherence(from: sevenDaysAgo, to: today)
    }

    /// Calculates adherence for the last 31 days (including today).
    func calculateMonthlyAdherence() -> Double? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let thirtyOneDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) else { return nil } // Today + 30 previous days = 31 days
        return calculateAdherence(from: thirtyOneDaysAgo, to: today)
    }
    
    /// Counts the number of doses due today based on scheduledDoses.
    var dosesDueToday: Int {
        guard let scheduledDoses = scheduledDoses else { return 0 }
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        return scheduledDoses.filter { dose in
            let doseTimeComponents = calendar.dateComponents([.hour, .minute], from: dose.time)
            guard let doseTimeToday = calendar.date(bySettingHour: doseTimeComponents.hour!,
                                                   minute: doseTimeComponents.minute!,
                                                   second: 0,
                                                   of: now) else { return false }
            return doseTimeToday <= now // Count only doses due by now
        }.count
    }

    /// Counts the number of doses taken today based on doseLogEvents.
    var dosesTakenToday: Int {
        guard let doseLogEvents = doseLogEvents else { return 0 }
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        return doseLogEvents.filter { event in
            calendar.isDate(event.dateRecorded, inSameDayAs: startOfToday) && event.isTaken
        }.count
    }
}
