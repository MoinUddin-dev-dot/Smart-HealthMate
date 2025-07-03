import SwiftUI

// MARK: - PanelType Enum (Defines which main screen/tab is active)
enum PanelType: Identifiable, Equatable, CaseIterable { // Make CaseIterable for easier iteration
    case medicines
    case reminders
    case vitalsMonitoring
    case healthReports
    case smartHealthAnalytics
    case aiChatbot
    case emailAlerts

    var id: Self { self }

    // Helper for display name and icon
    var displayName: String {
        switch self {
        case .medicines: return "Medicines"
        case .reminders: return "Reminders"
        case .vitalsMonitoring: return "Vitals"
        case .healthReports: return "Reports"
        case .smartHealthAnalytics: return "Analytics"
        case .aiChatbot: return "Chatbot"
        case .emailAlerts: return "Alerts"
        }
    }

    var systemImageName: String {
        switch self {
        case .medicines: return "pills.fill"
        case .reminders: return "bell.fill"
        case .vitalsMonitoring: return "waveform.path.ecg"
        case .healthReports: return "doc.text.fill"
        case .smartHealthAnalytics: return "brain.head.profile"
        case .aiChatbot: return "bubble.right.fill"
        case .emailAlerts: return "envelope.fill"
        }
    }
}

// MARK: - MedicineTracker (Main App Entry Point with Custom Bottom Navigator)
struct MedicineTracker: View {
    @State private var activePanel: PanelType = .medicines // Controls which main content view is active
    
    // Top-level state for medicines and reminders, passed down as Bindings
    @State private var medicines: [Medicine] = [
        Medicine(name: "Amlodipine", purpose: "Blood Pressure Control", dosage: "5mg", timingString: "9:00 AM, 9:00 PM",
                 startDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
                 endDate: Calendar.current.date(byAdding: .day, value: 60, to: Date())!),
        Medicine(name: "Metformin", purpose: "Diabetes Management", dosage: "500mg", timingString: "8:00 AM, 12:00 PM, 6:00 PM",
                 startDate: Calendar.current.date(byAdding: .year, value: -1, to: Date())!,
                 endDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!), // Example of an inactive medicine
        Medicine(name: "Lisinopril", purpose: "Hypertension", dosage: "10mg", timingString: "7:00 AM",
                 startDate: Date(), endDate: Calendar.current.date(byAdding: .month, value: 3, to: Date())!)
    ]
    @State private var reminders: [Reminder] = [
            // MARK: - Example Health Checkup Reminder (Morning BP & Sugar Check)
            Reminder(title: "Morning BP & Sugar Check",
                     type: .checkup,
                     times: [
                        Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!,  // 8:00 AM
                        Calendar.current.date(bySettingHour: 18, minute: 30, second: 0, of: Date())! // 6:30 PM
                     ],
                     startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
                     endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!,
                     active: true,
                     nextDue: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!,
                     // Assuming 8:00 AM slot was completed earlier today
                     completedTimes: [Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!],
                     lastResetDate: Calendar.current.startOfDay(for: Date())), // Reset today

            // MARK: - Example Health Checkup Reminder (Weekly Weight Check)
            Reminder(title: "Weekly Weight Check",
                     type: .checkup,
                     times: [
                        Calendar.current.date(bySettingHour: 9, minute: 30, second: 0, of: Date())! // 9:30 AM
                     ],
                     startDate: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
                     endDate: Calendar.current.date(byAdding: .month, value: 2, to: Date())!,
                     active: true,
                     nextDue: Calendar.current.date(bySettingHour: 9, minute: 30, second: 0, of: Date())!,
                     completedTimes: [], // Not completed yet for today
                     lastResetDate: Calendar.current.startOfDay(for: Date())), // Reset today

            // MARK: - Example Overdue Health Checkup (Past Due BP Measurement)
            Reminder(title: "Past Due BP Measurement",
                     type: .checkup,
                     times: [
                        Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())! // 10:00 AM - Overdue
                     ],
                     startDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                     endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!,
                     active: true,
                     nextDue: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!,
                     completedTimes: [], // Not completed for today
                     lastResetDate: Calendar.current.startOfDay(for: Date())), // Reset today

            // MARK: - Example of a completed Health Checkup (Morning Exercise Routine)
            Reminder(title: "Morning Exercise Routine",
                     type: .checkup,
                     times: [
                        Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date())! // 7:00 AM
                     ],
                     startDate: Calendar.current.date(byAdding: .day, value: -20, to: Date())!,
                     endDate: Calendar.current.date(byAdding: .month, value: 3, to: Date())!,
                     active: true,
                     nextDue: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!,
                     // Marked as completed for today
                     completedTimes: [Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!],
                     lastResetDate: Calendar.current.startOfDay(for: Date())),

            // MARK: - Example Medicine Reminder (Morning Antibiotics) - Comes from other screen, not editable from here
            Reminder(title: "Morning Antibiotics",
                     type: .medicine,
                     times: [
                        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())! // 9:00 AM - Overdue
                     ],
                     startDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
                     endDate: Calendar.current.date(byAdding: .day, value: 4, to: Date())!,
                     active: true,
                     nextDue: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
                     completedTimes: [],
                     lastResetDate: Calendar.current.startOfDay(for: Date())),
            
            // MARK: - Example Medicine Reminder (Evening Pain Reliever)
            Reminder(title: "Evening Pain Reliever",
                     type: .medicine,
                     times: [
                        Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date())!, // 7:00 PM - Pending
                        Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date())!  // 11:00 PM - Pending
                     ],
                     startDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                     endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
                     active: true,
                     nextDue: Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date())!,
                     completedTimes: [],
                     lastResetDate: Calendar.current.startOfDay(for: Date())),

            // MARK: - Example of a reminder that will be filtered out due to endDate passing
            Reminder(title: "Old Dental Checkup Reminder",
                     type: .checkup,
                     times: [
                        Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date())!
                     ],
                     startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())!,
                     endDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, // End date was 2 days ago (June 30, 2025)
                     active: true,
                     nextDue: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date().addingTimeInterval(-86400 * 3))!,
                     completedTimes: [Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date().addingTimeInterval(-86400 * 3))!], // Example completed in the past
                     lastResetDate: Calendar.current.startOfDay(for: Date().addingTimeInterval(-86400 * 3)))
        ]
    
    // Top-level state for vitals (NEW)
    @State private var vitals: [VitalReading] = [
            VitalReading(type: .bp, systolic: 120, diastolic: 80, date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, time: Date()),
            VitalReading(type: .sugar, sugarLevel: 110, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, time: Date()),
            VitalReading(type: .bp, systolic: 135, diastolic: 85, date: Date(), time: Date())
        ]

    @ViewBuilder
    var activePanelView: some View {
        switch activePanel {
        case .medicines:
            // Pass the medicines binding for CRUD operations
            MedicineListView(medicines: $medicines)
        case .reminders:
            RemindersScreen(medicinesCount: medicines.count, reminders: $reminders)
        case .vitalsMonitoring:
            VitalsMonitoringScreen(vitals: $vitals, medicinesCount: medicines.count)
        case .healthReports:
            HealthReportsScreen(medicinesCount: medicines.count)
        case .smartHealthAnalytics:
            SmartHealthAnalyticsView()
        case .aiChatbot:
            HealthChatbotView()
        case .emailAlerts:
            SMAEmailAlertsView(medicines: medicines.count)
        }
    }

    var body: some View {
        // Use a ZStack to layer content and the fixed bottom bar
        ZStack(alignment: .bottom) {
            // Main content area - switches views based on activePanel
            VStack(spacing: 0) {
                // Conditional view display
                activePanelView
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Make content take all available space
            }

            // Custom Fixed Bottom Horizontal Navigator
            HorizontalScrollNavigator(activePanel: $activePanel)
                .background(Color.white.opacity(0.95)) // Add a subtle background for the bar
                .shadow(radius: 5, x: 0, y: -2) // Shadow at the top of the bar
                .ignoresSafeArea(.keyboard, edges: .bottom) // Ensure it doesn't move with keyboard
        }
    }
}

// MARK: - SMAMedicineTrackerHeader (Universal - remains fixed at top)
struct SMAMedicineTrackerHeader: View {
    var body: some View {
        Text("Manage your medications and track adherence")
            .font(.subheadline)
            .foregroundColor(.gray)
            .padding(.horizontal)
    }
}

// MARK: - SMAMedicineTrackerStats (Universal - appears in each screen's scroll view)
// MARK: - SMAMedicineTrackerStats (Responsive Layout)
struct SMAMedicineTrackerStats: View {
    let medicinesCount: Int

    var body: some View {
        GeometryReader { geometry in
            let isWide = geometry.size.width > 700
            let columnCount = isWide ? 4 : 2
            let totalSpacing = CGFloat((columnCount - 1) * 16)
            let itemWidth = (geometry.size.width - 32 - totalSpacing) / CGFloat(columnCount)

            let columns = Array(
                repeating: GridItem(.flexible(minimum: itemWidth), spacing: 16),
                count: columnCount
            )

            LazyVGrid(columns: columns, alignment: .center, spacing: 16) {
                AdherenceDataView(adherencePercentage: 85)
                MedicinesDataView(count: medicinesCount)
                BPDataView(systolic: 120, diastolic: 80)
                SugarDataView(value: 140)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, isWide ? 0 : 16) // 👈 Remove bottom gap if it's one-row layout
        }
        .frame(minHeight: 200) // Optional — remove this if not needed
    }
}

#Preview {
    MedicineTracker()
}

// MARK: - Helper Extensions (You can put these in a separate file like 'Extensions.swift')

extension Color {
    // A simple way to darken a color
    func darker(by percentage: CGFloat = 30.0) -> Color {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        // CORRECTED: Ensure 'green' parameter is assigned to '&green' and 'blue' to '&blue'
        if UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return Color(red: max(red - percentage / 100, 0.0),
                         green: max(green - percentage / 100, 0.0),
                         blue: max(blue - percentage / 100, 0.0),
                         opacity: alpha)
        }
        return self
    }
}


extension View {
    // Renamed to avoid ambiguity with SwiftUI's built-in .cornerRadius()
    func clipShapeWithRoundedCorners(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

//struct RoundedCorner: Shape {
//    var radius: CGFloat = .infinity
//    var corners: UIRectCorner = .allCorners
//
//    func path(in rect: CGRect) -> Path {
//        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
//        return Path(path.cgPath)
//    }
//}

// MARK: - MedicineListView (First Tab Content)
struct MedicineListView: View {
    @Binding var medicines: [Medicine]
    @State private var showingAddMedicineSheet = false
    @State private var medicineToEdit: Medicine?
    @State private var showingInactiveMedicinesSheet = false
    @State private var refreshID = UUID() // To force redraws if SwiftUI misses something

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    // Computed property for active medicines, based on the main 'medicines' array
    private var activeMedicines: [Medicine] {
        medicines.filter { medicine in
            let isActiveFlag = medicine.isActive // State from the toggle in the sheet
            let isDateCurrentlyActive = medicine.isCurrentlyActiveBasedOnDates // State based on dates
            
            // A medicine is truly "active" if its isActive flag is true AND its dates are currently valid.
            let shouldBeActive = isActiveFlag && isDateCurrentlyActive
            print("🔍 Filter Check: \(medicine.name) | Toggle isActive: \(isActiveFlag), isCurrentlyActiveBasedOnDates: \(isDateCurrentlyActive) => Result: \(shouldBeActive ? "ACTIVE" : "INACTIVE")")
            
            return shouldBeActive
        }
        .sorted { (med1, med2) in
            // Your existing sorting logic
            if med1.lastModifiedDate > med2.lastModifiedDate { return true }
            if med1.lastModifiedDate < med2.lastModifiedDate { return false }
            if med1.hasMissedDoseToday && !med2.hasMissedDoseToday { return true }
            if !med1.hasMissedDoseToday && med2.hasMissedDoseToday { return false }
            return med1.name < med2.name
        }
    }


    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        SMAMedicineTrackerHeader()
                        SMAMedicineTrackerStats(medicinesCount: activeMedicines.count) // Use the new computed property
                        
                        LazyVStack(spacing: 15) {
                            if activeMedicines.isEmpty {
                                Text("No active medicines added yet. Tap '+' to add one!")
                                    .foregroundColor(.gray)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                            } else {
                                ForEach(activeMedicines) { medicine in // Iterate directly over activeMedicines
                                    MedicineDetailCardView(
                                        medicine: medicine, // Pass the filtered medicine
                                        onTakenStatusChanged: { medicineId, doseId, newIsTakenStatus in
                                            if let medIndex = medicines.firstIndex(where: { $0.id == medicineId }),
                                               let doseIndex = medicines[medIndex].scheduledDoses.firstIndex(where: { $0.id == doseId }) {
                                                medicines[medIndex].scheduledDoses[doseIndex].isTaken = newIsTakenStatus
                                                print("Updated \(medicines[medIndex].name) dose at \(MedicineListView.timeFormatter.string(from: medicines[medIndex].scheduledDoses[doseIndex].time)) to Taken: \(newIsTakenStatus)")
                                                // Trigger a refresh only if needed (usually direct @State changes are enough)
                                                refreshID = UUID()
                                            }
                                        },
                                        onEdit: { medicine in
                                            medicineToEdit = medicine
                                            showingAddMedicineSheet = true
                                        },
                                        onDelete: { medicineId in
                                            medicines.removeAll(where: { $0.id == medicineId })
                                            print("Deleted medicine with ID: \(medicineId)")
                                            // Trigger a refresh only if needed
                                            refreshID = UUID()
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                        .id(refreshID) // Key to forcing redraws
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 60)
                }
            }
            .navigationTitle("Medicine Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingInactiveMedicinesSheet = true
                    }) {
                        Label("Inactive", systemImage: "archivebox.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        medicineToEdit = nil
                        showingAddMedicineSheet = true
                    }) {
                        Label("Add Medicine", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMedicineSheet, onDismiss: {
                print("Add/Edit sheet dismissed. Forcing refresh...")
                // The onSave closure should handle the main array update,
                // this onDismiss just ensures the UI updates after the sheet closes.
                refreshID = UUID()
            }) {
                AddNewMedicineSheetView(medicineToEdit: $medicineToEdit) { savedMedicine in
                    // MARK: - THE CRITICAL UPDATE LOGIC
                    if let index = medicines.firstIndex(where: { $0.id == savedMedicine.id }) {
                        // Found existing medicine, update it
                        medicines[index] = savedMedicine
                        print("✅ MedicineListView: Updated existing medicine '\(savedMedicine.name)' (id: \(savedMedicine.id)) with isActive: \(savedMedicine.isActive)")
                    } else {
                        // New medicine, add it
                        medicines.append(savedMedicine)
                        print("✅ MedicineListView: Added new medicine '\(savedMedicine.name)' (id: \(savedMedicine.id)) with isActive: \(savedMedicine.isActive)")
                    }
                    // No need to dismiss the sheet here if AddNewMedicineSheetView handles its own dismissal
                }
            }
            .sheet(isPresented: $showingInactiveMedicinesSheet) {
                // When InactiveMedicinesListView updates a medicine (making it active),
                // its internal call to AddNewMedicineSheetView's onSave will modify the main 'medicines' array directly.
                // The onActivate callback in InactiveMedicinesListView is mostly for informational side effects.
                InactiveMedicinesListView(medicines: $medicines) { activatedMedicine in
                    print("Medicine '\(activatedMedicine.name)' activated from inactive list. Parent will re-filter.")
                    refreshID = UUID() // Force refresh here too, to be safe, as InactiveMedicinesListView is dismissing
                }
            }
            .onChange(of: medicines) { oldMedicines, newMedicines in
                // This block handles automatic inactivation based on dates.
                // It's good to keep this, but ensure it doesn't fight with manual changes.
                var updatedMedicines = newMedicines
                var changed = false
                for i in 0..<updatedMedicines.count {
                    let currentMedicine = updatedMedicines[i]
                    // If it's currently active AND its dates indicate it should be inactive
                    if currentMedicine.isActive && (currentMedicine.hasPeriodEnded() || currentMedicine.isFutureMedicine) {
                        updatedMedicines[i].isActive = false
                        updatedMedicines[i].inactiveDate = currentMedicine.hasPeriodEnded() ? (currentMedicine.inactiveDate ?? Date()) : nil
                        updatedMedicines[i].lastModifiedDate = Date()
                        changed = true
                        print("Auto-inactivated: \(currentMedicine.name)")
                    }
                }
                if changed {
                    medicines = updatedMedicines // Assign the updated array back
                    refreshID = UUID() // Force refresh
                    print("Medicine list updated after auto-inactivation.")
                }
            }
        }
    }
}


// MARK: - InactiveMedicinesListView (New View for Inactive Medicines)
struct InactiveMedicinesListView: View {
    @Environment(\.dismiss) var dismiss // For dismissing this sheet
    @Binding var medicines: [Medicine] // The main medicines array
    var onActivate: ((Medicine) -> Void)? // Callback to parent (MedicineListView)

    @State private var showingActivateMedicineSheet = false
    @State private var medicineToActivate: Medicine?

    private var inactiveMedicines: [Medicine] {
        // MARK: SIMPLIFIED FILTER: Only check isActive directly
        medicines.filter { !$0.isActive }
            .sorted { (med1, med2) in
                // Sort by most recently inactive
                if let date1 = med1.inactiveDate, let date2 = med2.inactiveDate {
                    return date1 > date2
                }
                // Fallback to name if inactiveDate is nil or one has it and other doesn't
                // If one has inactiveDate and the other doesn't (and both are inactive)
                // prioritize the one with a date (which should be more recent deactivation)
                if med1.inactiveDate != nil && med2.inactiveDate == nil {
                    return true // med1 comes first if it has an inactiveDate
                }
                if med1.inactiveDate == nil && med2.inactiveDate != nil {
                    return false // med2 comes first if it has an inactiveDate
                }
                return med1.name < med2.name
            }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Medicines in this list are either past their treatment period, or have been manually set to inactive, or their start date is in the future.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .padding(.top, 5)

                    if inactiveMedicines.isEmpty {
                        Text("No inactive medicines found.")
                            .foregroundColor(.gray)
                            .padding()
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(inactiveMedicines) { medicine in
                            InactiveMedicineCardView(medicine: medicine) { selectedMedicine in
                                self.medicineToActivate = selectedMedicine
                                self.showingActivateMedicineSheet = true
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Inactive Medicines")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss() // Dismisses InactiveMedicinesListView
                    }
                }
            }
            .sheet(isPresented: $showingActivateMedicineSheet) {
                AddNewMedicineSheetView(medicineToEdit: $medicineToActivate) { savedMedicine in
                    // When the sheet saves, it will update the `medicines` array via onSave callback.
                    // This happens directly on the @Binding medicines array.
                    // So, MedicineListView will automatically re-evaluate its 'activeMedicines' list.
                    
                    // You might want to explicitly update the main medicines array here if you pass a copy
                    // to AddNewMedicineSheetView, but if it's a binding, it updates implicitly.
                    // For clarity, I'm explicitly updating it here as well, though the binding should handle it.
                    if let index = medicines.firstIndex(where: { $0.id == savedMedicine.id }) {
                        medicines[index] = savedMedicine
                        print("InactiveList: Updated medicine '\(savedMedicine.name)' with isActive: \(savedMedicine.isActive)")
                    }

                    onActivate?(savedMedicine) // Notify parent (MedicineListView) about activation
                    
                    // MARK: - CRITICAL FIX: Dismiss the AddNewMedicineSheetView AND InactiveMedicinesListView
                    self.showingActivateMedicineSheet = false // Dismiss the presented sheet
                    self.dismiss() // Dismiss InactiveMedicinesListView itself to trigger parent refresh
                }
            }
        }
    }
}

// MARK: - InactiveMedicineCardView (Similar to MedicineDetailCardView but for inactive ones)
struct InactiveMedicineCardView: View {
    let medicine: Medicine
    var onActivate: ((_ medicine: Medicine) -> Void)?

    private static let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.orange) // Distinct color for inactive cards
                .frame(width: 6)
                .clipShapeWithRoundedCorners(12, corners: [.topLeft, .bottomLeft]) // Corrected name

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Image(systemName: "pill.fill")
                        .font(.title2)
                        .foregroundColor(Color.orange)
                        .frame(width: 40, height: 40)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8) // This is SwiftUI's built-in .cornerRadius

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
                    // Activate Button
                    Button(action: {
                        onActivate?(medicine) // Pass the full medicine object
                    }) {
                        Text("Activate")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.green)
                            .cornerRadius(8) // This is SwiftUI's built-in .cornerRadius
                    }
                }
                .padding(.bottom, 5)

                Text(medicine.purpose)
                    .font(.footnote)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(5) // This is SwiftUI's built-in .cornerRadius

                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Period: \(medicine.startDate, formatter: InactiveMedicineCardView.itemFormatter) - \(medicine.endDate, formatter: InactiveMedicineCardView.itemFormatter)") // Corrected access
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                // Reason for inactivity
                if !medicine.isActive && medicine.hasPeriodEnded() {
                    Text("Status: Ended on \(medicine.endDate, formatter: InactiveMedicineCardView.itemFormatter)")
                        .font(.caption)
                        .foregroundColor(.red)
                } else if !medicine.isActive && medicine.startDate > Date() {
                    Text("Status: Starts on \(medicine.startDate, formatter: InactiveMedicineCardView.itemFormatter)")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else if !medicine.isActive && medicine.inactiveDate != nil {
                    Text("Status: Manually Inactive Since \(medicine.inactiveDate!, formatter: InactiveMedicineCardView.itemFormatter)")
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    Text("Status: Inactive (Reason Unknown)") // Fallback
                        .font(.caption)
                        .foregroundColor(.red)
                }

            }
            .padding()
            .background(Color.white)
        }
        .cornerRadius(12) // This is SwiftUI's built-in .cornerRadius for the whole card
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}



#Preview {
    MedicineTracker()
}
