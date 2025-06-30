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
        Medicine(name: "Amlodipine", purpose: "Blood Pressure Control", dosage: "5mg", timingString: "9:00 AM, 9:00 PM"),
        Medicine(name: "Metformin", purpose: "Diabetes Management", dosage: "500mg", timingString: "8:00 AM, 12:00 PM, 6:00 PM")
    ]
    @State private var reminders: [Reminder] = [
        Reminder(title: "Take Amlodipine", type: .medicine, time: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!, frequency: .daily, active: true, nextDue: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!),
        Reminder(title: "Take Metformin", type: .medicine, time: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!, frequency: .daily, active: true, nextDue: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!),
        Reminder(title: "Blood Pressure Check", type: .checkup, time: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!, frequency: .daily, active: true, nextDue: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!),
        Reminder(title: "Doctor Appointment", type: .appointment, time: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!, frequency: .weekly, active: true, nextDue: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date().addingTimeInterval(7 * 24 * 3600))!)
    ]
    
    // Top-level state for vitals (NEW)
    @State private var vitals: [VitalReading] = [
        VitalReading(type: .bp, systolic: 120, diastolic: 80, date: Date(), time: "9:00 AM"),
        VitalReading(type: .sugar, sugarLevel: 140, date: Date(), time: "8:30 AM"),
        VitalReading(type: .bp, systolic: 125, diastolic: 82, date: Date().addingTimeInterval(-3600 * 24), time: "9:00 AM"),
        VitalReading(type: .sugar, sugarLevel: 135, date: Date().addingTimeInterval(-3600 * 24), time: "8:30 AM")
    ]

    @ViewBuilder
    var activePanelView: some View {
        switch activePanel {
        case .medicines:
            MedicineListView(medicines: $medicines, allMedicinesCount: medicines.count)
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

// MARK: - MedicineListView (First Tab Content)
struct MedicineListView: View {
    @Binding var medicines: [Medicine]
    let allMedicinesCount: Int
    @State private var showingAddMedicineSheet = false

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        SMAMedicineTrackerHeader()

                        SMAMedicineTrackerStats(medicinesCount: allMedicinesCount)

                        LazyVStack(spacing: 15) {
                            ForEach($medicines) { $medicine in
                                MedicineDetailCardView(medicine: medicine) { medicineId, doseId, newIsTakenStatus in
                                    if let medIndex = medicines.firstIndex(where: { $0.id == medicineId }) {
                                        if let doseIndex = medicines[medIndex].scheduledDoses.firstIndex(where: { $0.id == doseId }) {
                                            medicines[medIndex].scheduledDoses[doseIndex].isTaken = newIsTakenStatus
                                            print("Updated \(medicines[medIndex].name) dose at \(MedicineListView.timeFormatter.string(from: medicines[medIndex].scheduledDoses[doseIndex].time)) to Taken: \(newIsTakenStatus)")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 60)
                }
            }
            .navigationTitle("Medicine Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddMedicineSheet = true
                    }) {
                        Label("Add Medicine", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMedicineSheet) {
                AddNewMedicineSheetView { newMedicine in
                    medicines.append(newMedicine)
                }
            }
        }
    }
}



#Preview {
    MedicineTracker()
}
