////
////  MedicineDetailCardView.swift
////  Smart HealthMate
////
////  Created by Moin on 6/18/25.
////

import SwiftUI

// MedicineDetailCardView (No Change)
struct MedicineDetailCardView: View {
    let medicine: Medicine
    // Closure to notify parent when taken status changes
    var onTakenStatusChanged: ((_ medicineId: UUID, _ doseId: UUID, _ newIsTakenStatus: Bool) -> Void)?
    // NEW: Closure to notify parent when edit button is tapped
    var onEdit: ((_ medicine: Medicine) -> Void)?
    // NEW: Closure to notify parent when delete button is tapped
    var onDelete: ((_ medicineId: UUID) -> Void)?

    // @State private var internalScheduledDoses: [Medicine.ScheduledDose] // REMOVE THIS LINE
    // Instead of internal state, directly use medicine.scheduledDoses for display.
    // Changes to isTaken will be propagated UP to the parent via onTakenStatusChanged closure.

    init(medicine: Medicine,
         onTakenStatusChanged: ((_ medicineId: UUID, _ doseId: UUID, _ newIsTakenStatus: Bool) -> Void)? = nil,
         onEdit: ((_ medicine: Medicine) -> Void)? = nil,
         onDelete: ((_ medicineId: UUID) -> Void)? = nil) {
        self.medicine = medicine
        // _internalScheduledDoses = State(initialValue: medicine.scheduledDoses) // REMOVE THIS LINE
        self.onTakenStatusChanged = onTakenStatusChanged
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    private func isDoseMissed(dose: Medicine.ScheduledDose) -> Bool {
        // Only consider a dose missed if its time for today has passed and it's not taken
        let now = Date()
        let calendar = Calendar.current
        // Get dose time components and apply them to today's date
        let doseTimeComponents = calendar.dateComponents([.hour, .minute], from: dose.time)
        guard let doseTimeOnToday = calendar.date(bySettingHour: doseTimeComponents.hour!,
                                                   minute: doseTimeComponents.minute!,
                                                   second: 0,
                                                   of: now) else { return false }
        
        // A dose is missed if its time on today's date is in the past AND it's not taken.
        return calendar.compare(doseTimeOnToday, to: now, toGranularity: .minute) == .orderedAscending && !dose.isTaken
    }

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(medicine.isActive ? Color.blue : Color.gray)
                .frame(width: 6)
                .clipShapeWithRoundedCorners(12, corners: [.topLeft, .bottomLeft]) // Use the corrected extension name

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
                    
                    // NEW: Edit Button
                    Button(action: {
                        onEdit?(medicine)
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                    .padding(.trailing, 5)

                    // Existing Delete Button
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
                    Text("Period: \(medicine.startDate, formatter: MedicineDetailCardView.itemFormatter) - \(medicine.endDate, formatter: MedicineDetailCardView.itemFormatter)")
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
                
                // NEW: Status pill (Active/Inactive)
                HStack {
                    if medicine.isActive {
                        Text("Active")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green.darker())
                            .cornerRadius(5)
                    } else {
                        Text("Inactive")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red.darker())
                            .cornerRadius(5)
                    }
                    if !medicine.isActive, let inactiveDate = medicine.inactiveDate {
                        Text("Since \(inactiveDate, formatter: MedicineDetailCardView.itemFormatter)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    } else if !medicine.isActive && medicine.startDate > Date() {
                         Text("Starts \(medicine.startDate, formatter: MedicineDetailCardView.itemFormatter)")
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

                    // Iterate over 'medicine.scheduledDoses' as values, not bindings
                    // And make sure to sort it here for display consistency.
                    ForEach(medicine.scheduledDoses.sorted { $0.time < $1.time }) { dose in
                        HStack {
                            Text(dose.time, style: .time)
                                .font(.subheadline)
                                .foregroundColor(isDoseMissed(dose: dose) ? .red : .primary)

                            Spacer()

                            if dose.isTaken {
                                HStack(spacing: 5) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.subheadline)
                                    Text("Taken")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                }
                            } else if isDoseMissed(dose: dose) {
                                HStack(spacing: 5) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.subheadline)
                                    Text("Missed")
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                }
                            } else {
                                HStack(spacing: 5) {
                                    Image(systemName: "hourglass")
                                        .foregroundColor(.orange)
                                        .font(.subheadline)
                                    Text("Pending")
                                        .font(.subheadline)
                                        .foregroundColor(.orange)
                                }
                            }

                            Button(action: {
                                // Call the closure to update the parent's source of truth
                                // Don't try to toggle dose.isTaken directly here, as 'dose' is not a binding.
                                onTakenStatusChanged?(medicine.id, dose.id, !dose.isTaken)
                            }) {
                                Text(dose.isTaken ? "Untake" : "Mark Taken")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(dose.isTaken ? Color.orange : Color.blue)
                                    .cornerRadius(6)
                            }
                            // NEW: Mark Taken Validation
                            .disabled(dose.isPending) // Disable if the dose time has not yet arrived
                        }
                    }
                }
                .padding(.bottom, 10)
            }
            .padding()
            .background(Color.white)
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        // .onChange(of: medicine) { newMedicine in ... } // REMOVE THIS .onChange, it's no longer needed
    }
    
    // Formatter for start/end dates
    private static let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium // e.g., "Jul 1, 2025"
        formatter.timeStyle = .none // No time for date display
        return formatter
    }()
}


// MARK: - Medicine Struct (Data model for MedicineListView)
import Foundation
import SwiftUI // Only for Color.darker() example, remove if not needed here

// MARK: - Medicine Struct (Data model for MedicineListView)
// Add Codable conformance for easy saving/loading (e.g., to UserDefaults or a database)
struct Medicine: Identifiable, Codable, Equatable { // Ensure Equatable is here
    let id: UUID
    var name: String
    var purpose: String
    var dosage: String
    var timingString: String
    var scheduledDoses: [ScheduledDose]

    var startDate: Date
    var endDate: Date
    var isActive: Bool
    var inactiveDate: Date? // Date when it became inactive
    var lastModifiedDate: Date // For sorting and knowing last change

    // Add Equatable conformance (Xcode can often auto-generate this)
    static func == (lhs: Medicine, rhs: Medicine) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.purpose == rhs.purpose &&
        lhs.dosage == rhs.dosage &&
        lhs.timingString == rhs.timingString &&
        lhs.scheduledDoses == rhs.scheduledDoses &&
        lhs.startDate == rhs.startDate &&
        lhs.endDate == rhs.endDate &&
        lhs.isActive == rhs.isActive &&
        lhs.inactiveDate == rhs.inactiveDate &&
        lhs.lastModifiedDate == rhs.lastModifiedDate
    }

    struct ScheduledDose: Identifiable, Equatable, Codable {
        let id: UUID
        let time: Date
        var isTaken: Bool

        var isPending: Bool {
            let calendar = Calendar.current
            let now = Date()
            guard let doseTimeToday = calendar.date(bySettingHour: calendar.component(.hour, from: time),
                                                     minute: calendar.component(.minute, from: time),
                                                     second: calendar.component(.second, from: time),
                                                     of: now) else { return false }
            return doseTimeToday > now
        }
        
        static func == (lhs: ScheduledDose, rhs: ScheduledDose) -> Bool {
            lhs.id == rhs.id &&
            lhs.time == rhs.time &&
            lhs.isTaken == rhs.isTaken
        }
    }

    // MARK: - Computed Properties and Helpers

    // Determines if the medicine is currently active based on its start/end dates (CALENDAR DAYS)
    var isCurrentlyActiveBasedOnDates: Bool {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        let normalizedStartDate = calendar.startOfDay(for: startDate)
        let normalizedEndDate = calendar.startOfDay(for: endDate)

        // A medicine is 'currently active based on dates' if:
        // its start date is today or earlier AND its end date is today or later.
        return normalizedStartDate <= startOfToday && normalizedEndDate >= startOfToday
    }

    // Checks if the medicine's end date has passed (CALENDAR DAY)
    func hasPeriodEnded() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let normalizedEndDate = calendar.startOfDay(for: endDate)
        
        return normalizedEndDate < startOfToday
    }
    
    // Checks if the start date is in the future (CALENDAR DAY)
    var isFutureMedicine: Bool {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let normalizedStartDate = calendar.startOfDay(for: startDate)
        
        return normalizedStartDate > startOfToday
    }
    
    var hasMissedDoseToday: Bool {
        let calendar = Calendar.current
        let now = Date()
        
        for dose in scheduledDoses {
            let doseTimeComponents = calendar.dateComponents([.hour, .minute], from: dose.time)
            
            guard let doseTimeOnToday = calendar.date(bySettingHour: doseTimeComponents.hour!,
                                                      minute: doseTimeComponents.minute!,
                                                      second: 0,
                                                      of: now) else { continue }
            
            if calendar.compare(doseTimeOnToday, to: now, toGranularity: .minute) == .orderedAscending && !dose.isTaken {
                return true
            }
        }
        return false
    }
    
    var displayTimingFrequency: String {
        if scheduledDoses.isEmpty {
            return "No specific times"
        } else if scheduledDoses.count == 1 {
            return "Once a day"
        } else {
            return "\(scheduledDoses.count) times a day"
        }
    }


    // MARK: - Initializers

    init(id: UUID = UUID(), name: String, purpose: String, dosage: String, timingString: String, scheduledDoses: [ScheduledDose], startDate: Date, endDate: Date, isActive: Bool = true, inactiveDate: Date? = nil, lastModifiedDate: Date = Date()) {
        self.id = id
        self.name = name
        self.purpose = purpose
        self.dosage = dosage
        self.timingString = timingString
        self.scheduledDoses = scheduledDoses
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.inactiveDate = inactiveDate
        self.lastModifiedDate = lastModifiedDate
        
        // This defensive check might be redundant if views handle it, but for robustness
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        if self.isActive && !(calendar.startOfDay(for: self.startDate) <= startOfToday && calendar.startOfDay(for: self.endDate) >= startOfToday) && self.inactiveDate == nil {
            self.isActive = false
        }
    }
    
    // Convenience init (less relevant now, but update it for lastModifiedDate if you use it)
    init(id: UUID = UUID(), name: String, purpose: String, dosage: String, timingString: String, startDate: Date, endDate: Date, isActive: Bool = true, inactiveDate: Date? = nil, lastModifiedDate: Date = Date()) {
        self.id = id
        self.name = name
        self.purpose = purpose
        self.dosage = dosage
        self.timingString = timingString
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.inactiveDate = inactiveDate
        self.lastModifiedDate = lastModifiedDate

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        let components = timingString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        
        var generatedDoses: [ScheduledDose] = []
        let calendar = Calendar.current
        let now = Date()

        for timeString in components {
            if let date = formatter.date(from: timeString) {
                let timeComponents = calendar.dateComponents([.hour, .minute], from: date)
                if let scheduledTime = calendar.date(bySettingHour: timeComponents.hour!, minute: timeComponents.minute!, second: 0, of: now) {
                    generatedDoses.append(ScheduledDose(id: UUID(), time: scheduledTime, isTaken: false))
                }
            }
        }
        self.scheduledDoses = generatedDoses.sorted { $0.time < $1.time }
        
        let calendarInternal = Calendar.current // Use a different name for clarity
        let startOfTodayInternal = calendarInternal.startOfDay(for: Date())
        if self.isActive && !(calendarInternal.startOfDay(for: self.startDate) <= startOfTodayInternal && calendarInternal.startOfDay(for: self.endDate) >= startOfTodayInternal) && self.inactiveDate == nil {
            self.isActive = false
        }
    }
}



//#Preview {
//    MedicineDetailCardView(medicine: Medicine(name: "Amlodipine", purpose: "Blood Pressure Control", dosage: "5mg", timingString: "9:00 AM, 9:00 PM"))
//        .padding()
//}
