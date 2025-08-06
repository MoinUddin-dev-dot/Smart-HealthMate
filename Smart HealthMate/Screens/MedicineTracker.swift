import SwiftUI
import SwiftData // Import SwiftData
import Firebase
import FirebaseAuth
import PhotosUI // For Photo Library access
import UIKit // For UIImagePickerController
import UserNotifications // Import for notifications
import FirebaseFunctions

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
    
    var accessibilityID: String {
          switch self {
          case .medicines: return "medicinesButton"
          case .reminders: return "remindersButton"
          case .vitalsMonitoring: return "vitalsMonitoringButton"
          case .healthReports: return "healthReportsButton"
          case .smartHealthAnalytics: return "smartHealthAnalyticsButton"
          case .aiChatbot: return "aiChatbotButton"
          case .emailAlerts: return "emailAlertsButton"
          }
      }
}

// MARK: - NotificationDelegate (Handles foreground notifications)
final class NotificationDelegate: NSObject, ObservableObject, UNUserNotificationCenterDelegate { // Added ObservableObject
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification,
                                 withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // This method is called when a notification is delivered while the app is in the foreground.
        // We can choose to display it as a banner, play a sound, or update the badge.
        print("🔔 Foreground notification received: \(notification.request.content.title) (ID: \(notification.request.identifier))")
        completionHandler([.banner, .sound, .badge]) // Show banner, play sound, update badge
        
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 didReceive response: UNNotificationResponse,
                                 withCompletionHandler completionHandler: @escaping () -> Void) {
        // This method is called when the user interacts with a notification.
        print("🔔 User interacted with notification: \(response.notification.request.content.title) (ID: \(response.notification.request.identifier))")
        // You can add logic here to navigate to a specific part of your app
        // based on the notification's userInfo or identifier.
        completionHandler()
    }
}

import SwiftUI
import SwiftData
import Firebase
import FirebaseAuth
import FirebaseFunctions
import UserNotifications

// MARK: - MedicineTracker
struct MedicineTracker: View {
    @State private var activePanel: PanelType = .medicines
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettingsQuery: [UserSettings]
    @Query private var userItems: [UserDataItem]
    @State private var isShowingProfilePanel: Bool = false
    @State private var newItemTitle: String = ""
    @StateObject private var notificationDelegate = NotificationDelegate()
    @StateObject private var missedDoseService: MissedDoseService

    // Initialize with the modelContext from the environment
    init() {
        // Use the environment's modelContext for MissedDoseService
        // Since modelContext is accessed via @Environment, we'll initialize missedDoseService in onAppear
        _missedDoseService = StateObject(wrappedValue: MissedDoseService(authManager: AuthManager()))
    }

    @ViewBuilder
    var activePanelView: some View {
        switch activePanel {
        case .medicines:
            MedicineListView(isShowingProfilePanel: $isShowingProfilePanel)
        case .reminders:
            RemindersScreen()
        case .vitalsMonitoring:
            VitalsMonitoringScreen()
        case .healthReports:
            HealthReportsScreen(medicinesCount: 3)
        case .smartHealthAnalytics:
            SmartHealthAnalyticsView(authManager: authManager)
        case .aiChatbot:
            HealthChatbotView()
        case .emailAlerts:
            SMAEmailAlertsView()
        }
    }

    private var currentUserSettings: UserSettings {
        if let settings = userSettingsQuery.first(where: { $0.userID == authManager.currentUserUID }) {
            return settings
        } else {
            let newSettings = UserSettings(userID: authManager.currentUserUID ?? "unknown", userName: authManager.currentUserDisplayName)
            modelContext.insert(newSettings)
            return newSettings
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                activePanelView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            HorizontalScrollNavigator(activePanel: $activePanel)
                .background(Color.white.opacity(0.95))
                .shadow(radius: 5, x: 0, y: -2)
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .overlay(alignment: .leading) {
            if isShowingProfilePanel {
                UserProfileView(
                    isShowingProfilePanel: $isShowingProfilePanel,
                    authManager: authManager,
                    userSettings: currentUserSettings
                )
                .frame(width: UIScreen.main.bounds.width * 0.75)
                .transition(.move(edge: .leading))
                .background(Color.white)
                .edgesIgnoringSafeArea(.vertical)
                .shadow(radius: 10)
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.width < -50 || value.translation.width > 50 {
                                withAnimation(.easeInOut) {
                                    isShowingProfilePanel = false
                                }
                            }
                        }
                )
            }
        }
        .onAppear {
            requestNotificationPermission()
            UNUserNotificationCenter.current().delegate = notificationDelegate
            // Pass the modelContext to missedDoseService and schedule the daily check
            missedDoseService.setModelContext(modelContext)
            missedDoseService.scheduleDailyMissedDoseCheck()
        }
        .environmentObject(missedDoseService)
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission denied: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - MissedDoseService
class MissedDoseService: ObservableObject {
    private let authManager: AuthManager
    private let notificationCenter = UNUserNotificationCenter.current()
    private var modelContext: ModelContext?

    init(authManager: AuthManager) {
        self.authManager = authManager
    }

    // Set modelContext after initialization
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // Function to identify missed doses for the current user
    func getMissedDoses(for medicines: [Medicine], date: Date = Date()) -> [(medicine: Medicine, missedTimes: [Date])] {
        guard let userID = authManager.currentUserUID else {
            print("🚫 MissedDoseService: No authenticated user. Skipping missed dose check.")
            return []
        }
        guard let modelContext = modelContext else {
            print("🚫 MissedDoseService: ModelContext not set. Skipping missed dose check.")
            return []
        }

        let calendar = Calendar.current
        let todayStartOfDay = calendar.startOfDay(for: date)
        var missedDoses: [(medicine: Medicine, missedTimes: [Date])] = []

        // Filter medicines for the current user and check for missed doses
        let userMedicines = medicines.filter { $0.userSettings?.userID == userID && $0.isActive && $0.isCurrentlyActiveBasedOnDates }

        for medicine in userMedicines {
            // Ensure dose log events are up-to-date
            medicine.ensureDoseLogEvents(in: modelContext)

            var missedTimes: [Date] = []
            for dose in medicine.scheduledDoses ?? [] {
                // Get the scheduled time for today
                let components = calendar.dateComponents([.hour, .minute], from: dose.time)
                guard let hour = components.hour, let minute = components.minute,
                      let scheduledTimeToday = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) else {
                    continue
                }

                // Check if the dose was taken today
                let wasTaken = medicine.doseLogEvents?.contains { event in
                    calendar.isDate(event.dateRecorded, inSameDayAs: todayStartOfDay) &&
                    event.scheduledDose?.id == dose.id &&
                    event.isTaken == true
                } ?? false

                if !wasTaken && scheduledTimeToday < date {
                    missedTimes.append(scheduledTimeToday)
                }
            }

            if !missedTimes.isEmpty {
                missedDoses.append((medicine: medicine, missedTimes: missedTimes))
            }
        }

        return missedDoses
    }

    // Function to schedule the daily missed dose check and email
    func scheduleDailyMissedDoseCheck() {
        guard let userID = authManager.currentUserUID else {
            print("🚫 MissedDoseService: No authenticated user. Cannot schedule daily check.")
            return
        }

        // Remove any existing scheduled notifications for missed dose reports
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["MissedDoseReport-\(userID)"])

        // Get the user's time zone
        let timeZone = TimeZone.current
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = 23 // 11:00 PM
        components.minute = 0
        components.timeZone = timeZone

        let content = UNMutableNotificationContent()
        content.title = "Missed Medicine Report"
        content.body = "Missed medicine report has been emailed."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "MissedDoseReport-\(userID)", content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("🔔 Error scheduling missed dose report notification: \(error.localizedDescription)")
            } else {
                print("🔔 Scheduled missed dose report notification for 11:00 PM in user's time zone (ID: MissedDoseReport-\(userID))")
            }
        }

        // Trigger the missed dose check immediately for testing or initial setup
        Task {
            await checkAndSendMissedDoseEmail()
        }
    }

    // Function to check missed doses and send email to attendants via Firebase Cloud Functions
    func checkAndSendMissedDoseEmail() async {
        guard let userID = authManager.currentUserUID,
              let modelContext = modelContext else {
            print("🚫 MissedDoseService: No authenticated user or modelContext. Cannot send email.")
            return
        }

        do {
            // Fetch user settings to get emergency contacts
            let userSettingsDescriptor = FetchDescriptor<UserSettings>(predicate: #Predicate { settings in
                settings.userID == userID
            })
            guard let userSettings = try modelContext.fetch(userSettingsDescriptor).first else {
                print("🚫 MissedDoseService: No UserSettings found for user \(userID).")
                return
            }
            let emergencyContacts = userSettings.alertSettings.emergencyContacts
            guard !emergencyContacts.isEmpty else {
                print("🚫 MissedDoseService: No emergency contacts found for user \(userID).")
                return
            }

            // Fetch medicines for the current user
            let descriptor = FetchDescriptor<Medicine>(predicate: #Predicate { medicine in
                medicine.userSettings?.userID == userID
            })
            let medicines = try modelContext.fetch(descriptor)
            let missedDoses = getMissedDoses(for: medicines)

            if missedDoses.isEmpty {
                print("📧 No missed doses for user \(userID) today. No email sent.")
                return
            }

            // Format the email content
            var emailBody = "Dear Attendant(s),\n\n\(userSettings.userName ?? "User") missed some doses today:\n\n"
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .short

            for (medicine, missedTimes) in missedDoses {
                emailBody += "- \(medicine.name) (\(medicine.dosage)) at \(missedTimes.map { dateFormatter.string(from: $0) }.joined(separator: ", "))\n"
            }

            emailBody += "\nPlease ensure the user takes their medications as prescribed.\nBest regards,\nSmart HealthMate Team"

            // Prepare data for backend
            let data: [String: Any] = [
                "to": emergencyContacts, // Send as array for backend flexibility
                "subject": "Smart HealthMate: Missed Dose Report for \(userSettings.userName ?? "User")",
                "body": emailBody
            ]

            // Send data to your backend
            guard let url = URL(string: "http://localhost:3000/send-email") else {
                print("🚫 Invalid backend URL")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: data)
            } catch {
                print("🚫 Error serializing JSON: \(error.localizedDescription)")
                return
            }

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("🚫 Backend responded with error: \(String(describing: (response as? HTTPURLResponse)?.statusCode))")
                    return
                }
                print("📧 Successfully sent missed dose email to \(emergencyContacts.joined(separator: ", ")): \(String(data: data, encoding: .utf8) ?? "No response data")")
            } catch {
                print("📧 Error sending request to backend: \(error.localizedDescription)")
                return
            }

        } catch {
            print("🚫 Error fetching data for missed dose email: \(error.localizedDescription)")
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
// MARK: - SMAMedicineTrackerStats (Height reported via PreferenceKey)
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
                AdherenceDataView()
                MedicinesDataView(count: medicinesCount)
                BPDataView(systolic: 120, diastolic: 80)
                SugarDataView()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, isWide ? 0 : 16) // 👈 Remove bottom gap if it's one-row layout
        }
        .frame(minHeight: 200) // Optional — remove this if not needed
    }
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

import SwiftUI
import SwiftData
import Firebase // Assuming AuthManager and Firebase models are defined elsewhere
import FirebaseAuth

struct MedicineListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authManager: AuthManager // Inject AuthManager

    // MARK: - Profile Panel State received as Binding
    @Binding var isShowingProfilePanel: Bool // <--- Now a Binding

    // Modified @Query to fetch all medicines, filtering by user will happen in activeMedicines computed property
    @Query(sort: \Medicine.lastModifiedDate, order: .reverse)
    private var medicines: [Medicine]

    @State private var showingAddMedicineSheet = false
    @State private var medicineToEdit: Medicine?
    @State private var showingInactiveMedicinesSheet = false
    @State private var refreshID = UUID() // Used to force UI refresh

    // SwiftData Query for UserSettings (needed for UserProfileView and linking new medicines)
    @Query private var userSettingsQuery: [UserSettings]

    // Computed property for current user's settings, with default if not found
    private var currentUserSettings: UserSettings {
        if let settings = userSettingsQuery.first(where: { $0.userID == authManager.currentUserUID }) {
            return settings
        } else {
            // If settings don't exist, create and insert default ones
            let newSettings = UserSettings(userID: authManager.currentUserUID ?? "unknown", userName: authManager.currentUserDisplayName)
            modelContext.insert(newSettings)
            // It might take a moment for SwiftData to reflect the insert in the query.
            // For immediate use, return the newly created one.
            return newSettings
        }
    }

    // Explicit public initializer for MedicineListView
    public init(isShowingProfilePanel: Binding<Bool>) {
        self._isShowingProfilePanel = isShowingProfilePanel
        // The @Query property wrapper handles its own initialization, no need to pass medicines here.
    }


    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private var activeMedicines: [Medicine] {
        print("🔄 activeMedicines computed property re-evaluating...")
        // Filter medicines by the current user's UID after fetching all of them
        let userFilteredMedicines = medicines.filter { medicine in
            medicine.userSettings?.userID == authManager.currentUserUID
        }
        let filtered = filterActiveMedicines(medicines: userFilteredMedicines)
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
            // Schedule notifications when a medicine is saved/updated
            scheduleNotifications(for: savedMedicine)
        }
    }

    private var inactiveMedicinesSheet: some View {
        InactiveMedicinesListView { activatedMedicine in
            print("Medicine '\(activatedMedicine.name)' activated from inactive list. Parent will re-filter.")
            refreshID = UUID()
            // Re-schedule notifications when an inactive medicine is activated
            scheduleNotifications(for: activatedMedicine)
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
                        medicineToEdit: $medicineToEdit,
                        isShowingProfilePanel: $isShowingProfilePanel // Pass the binding here
                    )
                }
                .sheet(isPresented: $showingAddMedicineSheet, onDismiss: {
                    print("Add/Edit sheet dismissed. Forcing refresh...")
                    refreshID = UUID()
                    // After dismissal, check pending notifications again for debugging
                    Task { await checkPendingNotifications() }
                }, content: { addMedicineSheet })
                .sheet(isPresented: $showingInactiveMedicinesSheet, content: { inactiveMedicinesSheet })
                .onChange(of: medicines) { _, newMedicines in
                    Task {
                        await autoInactivateMedicines(newMedicines)
                    }
                }
                // Timer to periodically refresh the UI for time-sensitive changes
                .onReceive(Timer.publish(every: 10, on: .main, in: .common).autoconnect()) { _ in
                    print("⏰ Timer fired: Forcing UI refresh.")
                    refreshID = UUID() // Invalidate the ID to force view re-render
                    // Also check pending notifications on timer for debugging
                    Task { await checkPendingNotifications() }
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
                        // Cancel notifications when a medicine is auto-inactivated
                        cancelNotifications(for: mutableMedicine)
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
            // The @Query already filters by userSettings.userID, so this check might be redundant here
            // but keeping it for robustness if the query filter somehow fails or is removed.
            return shouldBeActive && medicine.userSettings?.userID == authManager.currentUserUID
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
                    print(" par par \(medicineToDelete.userSettings?.userID)")
                    // Cancel notifications before deleting the medicine
                    cancelNotifications(for: medicineToDelete)
                    modelContext.delete(medicineToDelete)
//                    try modelContext.save()
                    print("Medicine deleted with ID: \(medicineId)")
                    refreshID = UUID()
                }
            } catch {
                print("Error fetching medicine for deletion: \(error)")
            }
        }
    }

    // MARK: - Notification Functions
    func scheduleNotifications(for medicine: Medicine) {
        print("🔔 scheduleNotifications called for medicine: \(medicine.name)")

        // First, remove all pending notifications for this medicine to avoid duplicates
        // and to update if times have changed.
        var identifiersToCancel: [String] = []
        for dose in medicine.scheduledDoses ?? [] {
            identifiersToCancel.append("\(medicine.id.uuidString)-\(dose.id.uuidString)")
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
        print("🔔 Cleared existing notifications for \(medicine.name) with identifiers: \(identifiersToCancel)")
        
        guard medicine.isActive && medicine.isCurrentlyActiveBasedOnDates else {
            print("🔔 Medicine \(medicine.name) is not active or not within its date range. No notifications scheduled.")
            return
        }

        let calendar = Calendar.current
        for dose in medicine.scheduledDoses ?? [] {
            let components = calendar.dateComponents([.hour, .minute], from: dose.time)
            
            // Check if components can form a valid date (e.g., if hour/minute are valid)
            guard let hour = components.hour, let minute = components.minute else {
                print("🔔 Error: Invalid time components for dose \(dose.id.uuidString) of \(medicine.name). Skipping notification.")
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = "Medicine Reminder: \(medicine.name)"
            content.body = "It's time to take your \(medicine.dosage) of \(medicine.name)."
            content.sound = .default
            
            // Schedule the notification to repeat daily at the specified time
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let requestIdentifier = "\(medicine.id.uuidString)-\(dose.id.uuidString)" // Unique ID for each dose
            let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("🔔 Error scheduling notification for \(medicine.name) at \(hour):\(minute) (ID: \(requestIdentifier)): \(error.localizedDescription)")
                } else {
                    print("🔔 Successfully scheduled notification for \(medicine.name) at \(hour):\(minute) (ID: \(requestIdentifier))")
                }
            }
        }
    }

    func cancelNotifications(for medicine: Medicine) {
        var identifiersToCancel: [String] = []
        for dose in medicine.scheduledDoses ?? [] {
            identifiersToCancel.append("\(medicine.id.uuidString)-\(dose.id.uuidString)")
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
        print("🔔 Cancelled notifications for medicine \(medicine.name) and its doses with identifiers: \(identifiersToCancel)")
    }

    // New helper function to check pending notifications (for debugging)
    func checkPendingNotifications() async {
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()
        
        print("🔔 --- Current Pending Notifications (\(pendingRequests.count)) ---")
        if pendingRequests.isEmpty {
            print("    No pending notifications.")
        } else {
            for request in pendingRequests {
                if let calendarTrigger = request.trigger as? UNCalendarNotificationTrigger,
                    let nextTriggerDate = calendarTrigger.nextTriggerDate() {
                    print("    - ID: \(request.identifier), Title: \(request.content.title), Next Trigger: \(nextTriggerDate)")
                } else {
                    print("    - ID: \(request.identifier), Title: \(request.content.title), Trigger Type: \(String(describing: request.trigger?.classForCoder))")
                }
            }
        }
        print("🔔 --------------------------------------------------")
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
                                    onDelete: onDelete,
                                    
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .id(refreshID) // This forces re-render when refreshID changes
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
    @Binding var isShowingProfilePanel: Bool // <--- New binding for profile panel

    var body: some ToolbarContent {
        // Profile Button - Placed at the leading (left) side of the navigation bar
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                withAnimation(.easeInOut) {
                    isShowingProfilePanel.toggle() // Toggle the profile panel visibility
                }
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.title2) // Slightly smaller than .title for toolbar
            }
        }

        // Inactive Medicines Button - Trailing side
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: {
                showingInactiveMedicinesSheet = true
            }) {
                Label("Inactive", systemImage: "archivebox.fill")
            }
        }

        // Add Medicine Button - Trailing side
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                medicineToEdit = nil // Clear any previous selection for editing
                showingAddMedicineSheet = true
            })
            {
                Label("Add Medicine", systemImage: "plus")
            }.accessibilityIdentifier("plus")
        }
    }
}


// MARK: - InactiveMedicinesListView (New View for Inactive Medicines)
struct InactiveMedicinesListView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authManager: AuthManager

    @Query(sort: \Medicine.lastModifiedDate, order: .reverse)
    var inactiveMedicines: [Medicine]

    var onActivate: ((Medicine) -> Void)?

    @State private var showingActivateMedicineSheet = false
    @State private var medicineToActivate: Medicine?
    @State private var refreshID = UUID() // 🔁 Forcing UI refresh

    public init(onActivate: ((Medicine) -> Void)? = nil) {
        self.onActivate = onActivate
    }

    private var filteredInactiveMedicines: [Medicine] {
        inactiveMedicines.filter { medicine in
            !medicine.isActive && medicine.userSettings?.userID == authManager.currentUserUID
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

                    if filteredInactiveMedicines.isEmpty {
                        Text("No inactive medicines found.")
                            .foregroundColor(.gray)
                            .padding()
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(filteredInactiveMedicines) { medicine in
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
            .id(refreshID) // 🔁 Bind scroll view to refresh ID
            .onAppear {
                refreshID = UUID() // 🔄 Force refresh on appear
            }
            .navigationTitle("Inactive Medicines")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingActivateMedicineSheet) {
                AddNewMedicineSheetView(medicineToEdit: $medicineToActivate) { savedMedicine in
                    if let medToUpdate = medicineToActivate {
                        print("InactiveList: Updated '\(medToUpdate.name)' with isActive: \(medToUpdate.isActive)")
                        onActivate?(medToUpdate)
                    }
                    self.showingActivateMedicineSheet = false
                    self.dismiss()
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

