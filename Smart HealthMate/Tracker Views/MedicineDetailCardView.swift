////
////  MedicineDetailCardView.swift
////  Smart HealthMate
////
////  Created by Moin on 6/18/25.
////

import SwiftUI
import SwiftData

struct MedicineDetailCardView: View {
    // ⚠️ IMPORTANT CHANGE: Use @Bindable for direct property modification and SwiftData tracking
    @Bindable var medicine: Medicine

    // Closures for actions related to the entire Medicine object (edit, delete)
    // These still notify the parent view (e.g., MedicineListView) to perform context operations.
    var onEdit: ((_ medicine: Medicine) -> Void)?
    var onDelete: ((_ medicineId: UUID) -> Void)?

    // Formatter for short time display (e.g., "8:00 AM")
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    // Formatter for date display (e.g., "Jul 1, 2025")
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
                .clipShapeWithRoundedCorners(12, corners: [.topLeft, .bottomLeft])

            VStack(alignment: .leading, spacing: 10) {
                // MARK: Header Section
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

                    // Missed dose indicator - This will be calculated in the Medicine Model or parent
                    // if medicine.hasMissedDoseToday {
                    //     Image(systemName: "exclamationmark.triangle.fill")
                    //         .foregroundColor(.red)
                    //         .font(.headline)
                    //         .accessibilityLabel("Missed dose today")
                    // }

                    // Edit Button
                    Button(action: {
                        onEdit?(medicine) // Pass the @Bindable medicine object
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                    .padding(.trailing, 5)

                    // Delete Button (still using callback to delete the entire medicine)
                    Button(action: {
                        onDelete?(medicine.id) // Pass the Medicine ID
                    }) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                    }
                }
                .padding(.bottom, 5)

                // Purpose Tag
                Text(medicine.purpose)
                    .font(.footnote)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(5)

                // Period and Frequency Details
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

                // Status Pill (Active/Inactive)
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
                        Text("Since: \(inactiveDate, formatter: MedicineDetailCardView.itemFormatter)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    } else if !medicine.isActive && medicine.startDate > Date() {
                        Text("Starts: \(medicine.startDate, formatter: MedicineDetailCardView.itemFormatter)")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.bottom, 5)

                // MARK: Scheduled Doses Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scheduled Doses:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    // Ensure scheduledDoses is not nil and sort for display
                    if let sortedDoses = medicine.scheduledDoses?.sorted(by: { $0.time < $1.time }) {
                        ForEach(sortedDoses) { dose in
                            HStack {
                                Text(dose.time, style: .time)
                                    .font(.subheadline)
                                    // Use dose.isTaken and dose.isPending directly from ScheduledDose model
                                    .foregroundColor(dose.isTaken ? .primary : (dose.isPending ? .primary : .red))

                                Spacer()

                                // Display status text and icon based on dose properties
                                if dose.isTaken {
                                    HStack(spacing: 5) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.subheadline)
                                        Text("Taken")
                                            .font(.subheadline)
                                            .foregroundColor(.green)
                                    }
                                } else if dose.isPending {
                                    HStack(spacing: 5) {
                                        Image(systemName: "hourglass")
                                            .foregroundColor(.orange)
                                            .font(.subheadline)
                                        Text("Pending")
                                            .font(.subheadline)
                                            .foregroundColor(.orange)
                                    }
                                } else { // Dose not taken and not pending, so it's missed
                                    HStack(spacing: 5) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.subheadline)
                                        Text("Missed")
                                            .font(.subheadline)
                                            .foregroundColor(.red)
                                    }
                                }

                                // Mark Taken/Untake Button
                                Button(action: {
                                    // ⚠️ IMPORTANT CHANGE: Directly toggle isTaken on the @Bindable dose object.
                                    // SwiftData automatically saves this change.
                                    dose.isTaken.toggle()
                                    // No need to call 'onTakenStatusChanged' closure here anymore,
                                    // as the change is applied directly to the managed object.
                                }) {
                                    Text(dose.isTaken ? "Untake" : "Mark Taken")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(dose.isTaken ? Color.orange : Color.blue)
                                        .cornerRadius(6)
                                }
                                // Disable if the dose time has not yet arrived
                                .disabled(dose.isPending)
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
}



// MARK: - Medicine Struct (Data model for MedicineListView)
import Foundation
import SwiftUI // Only for Color.darker() example, remove if not needed here

// MARK: - Medicine Struct (Data model for MedicineListView)
// Add Codable conformance for easy saving/loading (e.g., to UserDefaults or a database)

// MARK: - Medicine Model
@Model
final class Medicine: Equatable { // Equatable for comparison as requested

    // 📦 Stored Properties
    @Attribute(.unique) var id: UUID // Unique identifier for the medicine. Automatically Identifiable for SwiftData views.
    var name: String // Medicine ka naam (e.g., "Panadol").
    var purpose: String // Kis purpose ke liye hai (e.g., "Fever").
    var dosage: String // Dosage detail (e.g., "500mg").
    var timingString: String // Human-readable time string (e.g., "8:00 AM, 8:00 PM").
    var startDate: Date // Kab se medicine lena start karna hai.
    var endDate: Date // Kab tak lena hai.
    var isActive: Bool // Abhi active hai ya nahi.
    var inactiveDate: Date? // Kab inactive hua (agar hua toh).
    var lastModifiedDate: Date // Last time kab edit/update hua tha.

    // Relation to ScheduledDose.
    // .cascade means if a Medicine is deleted, all its associated ScheduledDoses are also deleted.
    @Relationship(deleteRule: .cascade, inverse: \ScheduledDose.medicine)
    var scheduledDoses: [ScheduledDose]? // List of all doses scheduled for this medicine.

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

    /// Aaj koi dose reh gaya (missed + not taken) tou true.
    var hasMissedDoseToday: Bool {
        let calendar = Calendar.current
        let now = Date()

        guard let doses = scheduledDoses else { return false } // Ensure doses array is not nil

        for dose in doses {
            // Get only hour and minute components from the scheduled dose time
            let doseTimeComponents = calendar.dateComponents([.hour, .minute], from: dose.time)

            // Construct a date for today using the dose's hour and minute
            guard let doseTimeOnToday = calendar.date(bySettingHour: doseTimeComponents.hour!,
                                                      minute: doseTimeComponents.minute!,
                                                      second: 0,
                                                      of: now) else { continue }

            // If the dose time on today has passed 'now' and the dose has not been taken
            if calendar.compare(doseTimeOnToday, to: now, toGranularity: .minute) == .orderedAscending && !dose.isTaken {
                return true // A missed dose is found
            }
        }
        return false // No missed doses found for today
    }

    /// "Once a day", "No specific times", or "X times a day".
    var displayTimingFrequency: String {
        guard let doses = scheduledDoses else { return "No specific times" } // Ensure doses array is not nil

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
         timingString: String,
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
        self.timingString = timingString
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.inactiveDate = inactiveDate
        self.lastModifiedDate = lastModifiedDate
        self.scheduledDoses = scheduledDoses
    }

    /// Convenience initializer: Just use timingString, it auto-generates [ScheduledDose] using time parsing.
    convenience init(name: String,
                     purpose: String,
                     dosage: String,
                     timingString: String,
                     startDate: Date = Date(),
                     endDate: Date,
                     isActive: Bool = true,
                     inactiveDate: Date? = nil) {
        self.init(id: UUID(),
                  name: name,
                  purpose: purpose,
                  dosage: dosage,
                  timingString: timingString,
                  startDate: startDate,
                  endDate: endDate,
                  isActive: isActive,
                  inactiveDate: inactiveDate,
                  lastModifiedDate: Date()) // Set lastModifiedDate to now

        // Auto-generate scheduledDoses from timingString
        // ⚠️ FIX: Assign the result of the static function to self.scheduledDoses
        self.scheduledDoses = Medicine.parseTimingStringToScheduledDoses(timingString: timingString, medicine: self)
    }

    // Equatable conformance
    static func == (lhs: Medicine, rhs: Medicine) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Helper function for Medicine (parsing timingString)
    // ⚠️ FIX: Move this function INSIDE the Medicine class and declare it as `static`
    static func parseTimingStringToScheduledDoses(timingString: String, medicine: Medicine) -> [ScheduledDose] {
        let components = timingString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        var doses: [ScheduledDose] = []
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a" // Example: "8:00 AM"

        for component in components {
            if let date = dateFormatter.date(from: String(component)) {
                // Create a ScheduledDose with the parsed time
                let newDose = ScheduledDose(time: date, isTaken: false)
                newDose.medicine = medicine // Set the inverse relationship
                doses.append(newDose)
            } else {
                // Handle cases where parsing fails (e.g., "morning", "after meals")
                // For these, you might need a more complex parsing or a different property.
                // For now, we'll just skip them if they don't match the time format.
                print("Warning: Could not parse time from timingString component: \(component)")
            }
        }
        return doses
    }
}

@Model
final class ScheduledDose: Identifiable, Equatable { // Identifiable and Equatable as requested

    // 📦 Stored Properties
    @Attribute(.unique) var id: UUID // Unique ID per dose.
    var time: Date // Kis time pe dose lena hai.
    var isTaken: Bool // User ne dose le liya ya nahi (true/false).

    // Inverse relationship to Medicine.
    var medicine: Medicine? // Kis Medicine object se belong karta hai.

    // 🧠 Computed Property
    /// Agar dose ka time abhi baaki hai (future mein), tou true.
    var isPending: Bool {
        let calendar = Calendar.current
        let now = Date()
        
        // Get only hour and minute for comparison today
        let doseTimeComponents = calendar.dateComponents([.hour, .minute], from: self.time)
        guard let doseTimeOnToday = calendar.date(bySettingHour: doseTimeComponents.hour!,
                                                  minute: doseTimeComponents.minute!,
                                                  second: 0,
                                                  of: now) else { return false }
        
        // A dose is pending if its time today is in the future relative to 'now'
        return calendar.compare(doseTimeOnToday, to: now, toGranularity: .minute) == .orderedDescending
    }

    // 🔧 Initializer
    init(id: UUID = UUID(),
         time: Date,
         isTaken: Bool = false) {
        self.id = id
        self.time = time
        self.isTaken = isTaken
    }

    // Equatable conformance
    static func == (lhs: ScheduledDose, rhs: ScheduledDose) -> Bool {
        lhs.id == rhs.id
    }
}




//#Preview {
//    MedicineDetailCardView(medicine: Medicine(name: "Amlodipine", purpose: "Blood Pressure Control", dosage: "5mg", timingString: "9:00 AM, 9:00 PM"))
//        .padding()
//}
