import SwiftUI
import SwiftData // Import SwiftData


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
            MedicineListView()
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



// MARK: - MedicineListView (First Tab Content)

struct MedicineListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Medicine.lastModifiedDate, order: .reverse) private var medicines: [Medicine]
    @State private var showingAddMedicineSheet = false
    @State private var medicineToEdit: Medicine?
    @State private var showingInactiveMedicinesSheet = false
    @State private var refreshID = UUID()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private var activeMedicines: [Medicine] {
        let filtered = filterActiveMedicines(medicines: medicines)
        let sorted = sortMedicines(filteredMedicines: filtered)
        return sorted
    }

    private func onEditAction(_ medicine: Medicine) {
        medicineToEdit = medicine
        showingAddMedicineSheet = true
    }

    private var mainContent: some View {
        MainContentScrollView(
            activeMedicines: activeMedicines,
            refreshID: $refreshID,
            onEdit: onEditAction,
            onDelete: deleteMedicine
        )
    }

    private var addMedicineSheet: some View {
        AddNewMedicineSheetView(medicineToEdit: $medicineToEdit) { savedMedicine in
            print("✅ MedicineListView: Add/Edit sheet completed for '\(savedMedicine.name)' (id: \(savedMedicine.id))")
        }
    }

    private var inactiveMedicinesSheet: some View {
        InactiveMedicinesListView { activatedMedicine in
            print("Medicine '\(activatedMedicine.name)' activated from inactive list. Parent will re-filter.")
            refreshID = UUID()
        }
    }

    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Medicine Tracker")
                .toolbar {
                    MedicineListToolbar(
                        showingInactiveMedicinesSheet: $showingInactiveMedicinesSheet,
                        showingAddMedicineSheet: $showingAddMedicineSheet,
                        medicineToEdit: $medicineToEdit
                    )
                }
                .sheet(isPresented: $showingAddMedicineSheet, onDismiss: {
                    print("Add/Edit sheet dismissed. Forcing refresh...")
                    refreshID = UUID()
                }, content: { addMedicineSheet })
                .sheet(isPresented: $showingInactiveMedicinesSheet, content: { inactiveMedicinesSheet })
                .onChange(of: medicines) { _, newMedicines in
                    Task {
                        await autoInactivateMedicines(newMedicines)
                    }
                }
        }
    }

    private func autoInactivateMedicines(_ newMedicines: [Medicine]) async {
        var changedSomething = false
        for medicine in newMedicines {
            if medicine.isActive && (medicine.hasPeriodEnded() || medicine.isFutureMedicine) {
                let currentMedicineID = medicine.id
                do {
                    let descriptor = FetchDescriptor<Medicine>(predicate: #Predicate { m in
                        m.id == currentMedicineID
                    })
                    if let mutableMedicine = try modelContext.fetch(descriptor).first {
                        mutableMedicine.isActive = false
                        mutableMedicine.inactiveDate = mutableMedicine.hasPeriodEnded() ? (mutableMedicine.inactiveDate ?? Date()) : nil
                        mutableMedicine.lastModifiedDate = Date()
                        changedSomething = true
                        print("Auto-inactivated: \(mutableMedicine.name)")
                    }
                } catch {
                    print("Error fetching medicine for auto-inactivation: \(error)")
                }
            }
        }
        if changedSomething {
            refreshID = UUID()
            print("Medicine list updated after auto-inactivation and UI refreshed.")
        }
    }

    private func filterActiveMedicines(medicines: [Medicine]) -> [Medicine] {
        return medicines.filter { medicine in
            let isActiveFlag = medicine.isActive
            let isDateCurrentlyActive = medicine.isCurrentlyActiveBasedOnDates
            let shouldBeActive = isActiveFlag && isDateCurrentlyActive
            return shouldBeActive
        }
    }

    private func sortMedicines(filteredMedicines: [Medicine]) -> [Medicine] {
        return filteredMedicines.sorted { (med1, med2) in
            let lastModifiedComparison = med1.lastModifiedDate.compare(med2.lastModifiedDate)
            if lastModifiedComparison != .orderedSame {
                return lastModifiedComparison == .orderedDescending
            }
            let missedDoseComparison = (med1.hasMissedDoseToday && !med2.hasMissedDoseToday)
            if missedDoseComparison { return true }
            if (!med1.hasMissedDoseToday && med2.hasMissedDoseToday) { return false }
            return med1.name < med2.name
        }
    }

    private func deleteMedicine(medicineId: UUID) {
        Task {
            do {
                let descriptor = FetchDescriptor<Medicine>(predicate: #Predicate { $0.id == medicineId })
                if let medicineToDelete = try modelContext.fetch(descriptor).first {
                    modelContext.delete(medicineToDelete)
                    try modelContext.save()
                    print("Medicine deleted with ID: \(medicineId)")
                    refreshID = UUID()
                }
            } catch {
                print("Error fetching medicine for deletion: \(error)")
            }
        }
    }
}


/// Encapsulates the main scrollable content of the MedicineListView.
/// This significantly reduces the complexity of the parent MedicineListView's body.
struct MainContentScrollView: View {
    let activeMedicines: [Medicine]
    @Binding var refreshID: UUID
    let onEdit: (Medicine) -> Void
    let onDelete: (UUID) -> Void
    // Remove onDoseTaken

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    SMAMedicineTrackerHeader()
                    SMAMedicineTrackerStats(medicinesCount: activeMedicines.count)
                    LazyVStack(spacing: 15) {
                        if activeMedicines.isEmpty {
                            Text("No active medicines added yet. Tap '+' to add one!")
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity)
                        } else {
                            ForEach(activeMedicines) { medicine in
                                MedicineDetailCardView(
                                    medicine: medicine,
                                    onEdit: onEdit,
                                    onDelete: onDelete
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .id(refreshID)
                }
                .padding(.bottom, geometry.safeAreaInsets.bottom + 60)
            }
        }
    }
}

/// Encapsulates the toolbar items for MedicineListView.
/// This also helps in reducing the complexity of the parent's toolbar modifier.
private struct MedicineListToolbar: ToolbarContent { // Conforms to ToolbarContent
    // Use @Binding for state properties that control sheet presentation or data
    @Binding var showingInactiveMedicinesSheet: Bool
    @Binding var showingAddMedicineSheet: Bool
    @Binding var medicineToEdit: Medicine?

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
                showingInactiveMedicinesSheet = true
            }) {
                Label("Inactive", systemImage: "archivebox.fill")
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                medicineToEdit = nil // Clear any previous selection for editing
                showingAddMedicineSheet = true
            }) {
                Label("Add Medicine", systemImage: "plus")
            }
        }
    }
}


// MARK: - InactiveMedicinesListView (New View for Inactive Medicines)
struct InactiveMedicinesListView: View {
    @Environment(\.dismiss) var dismiss // For dismissing this sheet
    @Environment(\.modelContext) private var modelContext // Inject ModelContext

    // ⚠️ IMPORTANT: InactiveMedicinesListView will now fetch medicines itself using @Query
    // Filter to only show inactive medicines (isActive == false)
    @Query(filter: #Predicate<Medicine> { !$0.isActive }, sort: \Medicine.lastModifiedDate, order: .reverse)
    var inactiveMedicines: [Medicine]

    var onActivate: ((Medicine) -> Void)? // Callback to parent (MedicineListView)

    @State private var showingActivateMedicineSheet = false
    @State private var medicineToActivate: Medicine?

    // The inactiveMedicines computed property is no longer needed here
    // because @Query is directly filtering and sorting them.
    // However, if you had more complex filtering/sorting logic beyond what @Query predicate/sort offers,
    // you could still use a computed property on the result of @Query.
    /*
    private var inactiveMedicines: [Medicine] {
        // Step 1: Medicines filter
        let filtered = medicines.filter { medicine in
            // Here we use the computed properties of the Medicine model
            // defined in Medicine.swift.
            return !medicine.isActive || medicine.hasPeriodEnded() || medicine.isFutureMedicine
        }

        // Step 2: Sort the filtered medicines
        let sorted = filtered.sorted { (med1, med2) in
            // Sort by most recently inactive
            if let date1 = med1.inactiveDate, let date2 = med2.inactiveDate {
                return date1 > date2
            }
            // If inactiveDate is nil or one has it and the other doesn't
            // (and both are inactive) then sort by name
            if med1.inactiveDate != nil && med2.inactiveDate == nil {
                return true // med1 comes first if it has an inactiveDate
            }
            if med1.inactiveDate == nil && med2.inactiveDate != nil {
                return false // med2 comes first if it has an inactiveDate
            }
            return med1.name < med2.name
        }
        return sorted
    }
    */

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Medicines in this list are either past their treatment period, or have been manually set to inactive, or their start date is in the future.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .padding(.top, 5)

                    if inactiveMedicines.isEmpty { // Use the @Query result directly
                        Text("No inactive medicines found.")
                            .foregroundColor(.gray)
                            .padding()
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(inactiveMedicines) { medicine in // Iterate directly over @Query result
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
                    // When the sheet saves, AddNewMedicineSheetView (assuming it uses modelContext)
                    // will handle the update/insertion in SwiftData.
                    // Because inactiveMedicines is @Query, it will automatically update.

                    // ⚠️ IMPORTANT: SwiftData handles the update/save.
                    // medicineToActivate is already a managed object, so updating its properties
                    // within AddNewMedicineSheetView (which has access to modelContext)
                    // is automatically saved by SwiftData.
                    if let medToUpdate = medicineToActivate {
                        // AddNewMedicineSheetView has already updated properties like isActive.
                        // Here we just confirm and trigger the onActivate callback.
                        print("InactiveList: Updated medicine '\(medToUpdate.name)' with isActive: \(medToUpdate.isActive)")
                        onActivate?(medToUpdate) // Notify parent (MedicineListView) about activation
                    }

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
    let medicine: Medicine // The medicine object to display
    var onActivate: ((_ medicine: Medicine) -> Void)? // Optional callback closure for activation

    // DateFormatter for displaying dates in a medium style (e.g., "Jul 9, 2025")
    private static let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none // No time component
        return formatter
    }()

    var body: some View {
        HStack(spacing: 0) {
            // Left-side colored indicator for inactive status
            Rectangle()
                .fill(Color.orange) // Distinct orange color for inactive cards
                .frame(width: 6)
                .clipShapeWithRoundedCorners(12, corners: [.topLeft, .bottomLeft]) // Custom corner rounding

            // Main content area of the card
            VStack(alignment: .leading, spacing: 10) {
                // Top row: Icon, Name, Dosage, and Activate Button
                HStack(alignment: .top) {
                    // Pill icon
                    Image(systemName: "pill.fill")
                        .font(.title2)
                        .foregroundColor(Color.orange)
                        .frame(width: 40, height: 40)
                        .background(Color.orange.opacity(0.2)) // Light orange background for the icon
                        .cornerRadius(8) // Standard corner radius for the icon background

                    // Medicine name and dosage
                    VStack(alignment: .leading) {
                        Text(medicine.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(1) // Limit name to one line

                        Text(medicine.dosage)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer() // Pushes content to the left and Activate button to the right

                    // Activate Button
                    Button(action: {
                        onActivate?(medicine) // Trigger the activation callback
                    }) {
                        Text("Activate")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.green) // Green background for activation
                            .cornerRadius(8) // Standard corner radius for the button
                    }
                }
                .padding(.bottom, 5) // Padding below the top row

                // Medicine purpose/description tag
                Text(medicine.purpose)
                    .font(.footnote)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1)) // Light gray background for the purpose
                    .cornerRadius(5) // Rounded corners for the purpose tag

                // Period display (Start Date - End Date)
                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Period: \(medicine.startDate, formatter: InactiveMedicineCardView.itemFormatter) - \(medicine.endDate, formatter: InactiveMedicineCardView.itemFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }

                // --- Reason for Inactivity ---
                // Displays why the medicine is currently inactive based on its properties
                if !medicine.isActive && medicine.hasPeriodEnded() {
                    Text("Status: Ended on \(medicine.endDate, formatter: InactiveMedicineCardView.itemFormatter)")
                        .font(.caption)
                        .foregroundColor(.red) // Indicate an ended status with red
                } else if !medicine.isActive && medicine.startDate > Date() {
                    Text("Status: Starts on \(medicine.startDate, formatter: InactiveMedicineCardView.itemFormatter)")
                        .font(.caption)
                        .foregroundColor(.orange) // Indicate a future start date with orange
                } else if !medicine.isActive && medicine.inactiveDate != nil {
                    Text("Status: Manually Inactive Since \(medicine.inactiveDate!, formatter: InactiveMedicineCardView.itemFormatter)")
                        .font(.caption)
                        .foregroundColor(.red) // Indicate manual inactivation with red
                } else {
                    // Fallback for any other inactive state
                    Text("Status: Inactive (Reason Unknown)")
                        .font(.caption)
                        .foregroundColor(.red)
                }

            }
            .padding() // Padding for the main content VStack
            .background(Color.white) // White background for the content area
        }
        .cornerRadius(12) // Apply corner radius to the entire HStack (the whole card)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2) // Subtle shadow for depth
    }
}

#Preview {
    MedicineTracker()
}
