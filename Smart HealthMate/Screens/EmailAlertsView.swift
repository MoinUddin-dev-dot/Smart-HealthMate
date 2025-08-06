import SwiftUI
import SwiftData
import FirebaseAuth
import UserNotifications
import BackgroundTasks // Keep if background tasks are used elsewhere, otherwise can be removed.

// MARK: - SMAAlert Model
@Model
final class SMAAlert: Identifiable {
    let id: UUID
    @Attribute(.allowsCloudEncryption) var type: SMAAlertType
    var recipient: String
    var subject: String
    var status: SMAAlertStatus
    let sentAt: Date
    var content: String
    
    enum SMAAlertType: String, Codable, CaseIterable {
        case emergency = "Emergency"
        case reminder = "Reminder"
        case report = "Report"
        case unknown
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self = SMAAlertType(rawValue: rawValue) ?? .unknown
        }
    }
    
    enum SMAAlertStatus: String, Codable {
        case sent = "Sent"
        case failed = "Failed"
        case pending = "Pending"
    }
    
    init(id: UUID = UUID(), type: SMAAlertType, recipient: String, subject: String, status: SMAAlertStatus, sentAt: Date, content: String) {
        self.id = id
        self.type = type
        self.recipient = recipient
        self.subject = subject
        self.status = status
        self.sentAt = sentAt
        self.content = content
    }
}



// MARK: - DateFormatter Extension (for SMAMedicine and SMAAlerts)
extension DateFormatter {
    static let yearMonthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

// MARK: - Reusable UI Components (Unique Naming - UNCHANGED)
struct SMACustomCards<Content: View>: View {
    let content: Content
    var backgroundColor: Color = .white
    var borderColor: Color = .clear
    var gradient: LinearGradient? = nil
    var shadowColor: Color = .black.opacity(0.05)
    var shadowRadius: CGFloat = 4
    
    init(backgroundColor: Color = .white, borderColor: Color = .clear, gradient: LinearGradient? = nil, shadowColor: Color = .black.opacity(0.05), shadowRadius: CGFloat = 4, @ViewBuilder content: () -> Content) {
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.gradient = gradient
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.content = content()
    }
    
    var body: some View {
        if let gradient = gradient {
            content
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(gradient)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1))
                )
                .cornerRadius(12)
                .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 2)
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(backgroundColor)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1))
                )
                .cornerRadius(12)
                .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 2)
        }
    }
}

struct SMACustomCardContents<Content: View>: View {
    let content: Content
    var paddingValue: CGFloat = 16
    
    init(paddingValue: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.paddingValue = paddingValue
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(paddingValue)
    }
}

struct SMACustomCardHeaders<Content: View>: View {
    let content: Content
    var paddingBottom: CGFloat = 12
    var showBorder: Bool = false
    
    init(paddingBottom: CGFloat = 12, showBorder: Bool = false, @ViewBuilder content: () -> Content) {
        self.paddingBottom = paddingBottom
        self.showBorder = showBorder
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
                .padding(.bottom, paddingBottom)
            if showBorder {
                Divider()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

struct SMACustomCardTitles: View {
    let text: String
    var fontSize: CGFloat = 18
    var textColor: Color = .primary
    
    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundColor(textColor)
    }
}

struct SMACustomCardDescriptions: View {
    let text: String
    var textColor: Color = .gray
    
    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(textColor)
    }
}

struct SMACustomBadges: View {
    let text: String
    var variant: String = "secondary"
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeBackgroundColor)
            .foregroundColor(badgeForegroundColor)
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(borderColor, lineWidth: variant == "outline" ? 1 : 0)
            )
    }
    
    private var badgeBackgroundColor: Color {
        switch variant {
        case "destructive": return Color.red.opacity(0.15)
        case "outline": return Color.clear
        default: return Color.gray.opacity(0.15)
        }
    }
    
    private var badgeForegroundColor: Color {
        switch variant {
        case "destructive": return Color.red.opacity(0.9)
        case "outline": return Color.primary
        default: return Color.primary.opacity(0.8)
        }
    }
    
    private var borderColor: Color {
        switch variant {
        case "outline": return Color.gray.opacity(0.4)
        default: return .clear
        }
    }
}

struct SMAFlowLayout: Layout {
    var spacing: CGFloat = 0
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            if currentX + subviewSize.width > containerWidth {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            currentX += subviewSize.width + spacing
            rowHeight = max(rowHeight, subviewSize.height)
            totalHeight = max(totalHeight, currentY + rowHeight)
        }
        return CGSize(width: containerWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let containerWidth = bounds.width
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            if currentX + subviewSize.width > bounds.maxX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), anchor: .topLeading, proposal: .init(subviewSize))
            currentX += subviewSize.width + spacing
            rowHeight = max(rowHeight, subviewSize.height)
        }
    }
}

// MARK: - MedicineNotificationManager (NEW)
// This class handles scheduling and canceling local notifications for medicines.
class MedicineNotificationManager: ObservableObject {
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

// MARK: - NotificationDelegate (NEW)
//// This class handles foreground notification presentation and user interaction.
//final class NotificationDelegate: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
//    func userNotificationCenter(_ center: UNUserNotificationCenter,
//                                 willPresent notification: UNNotification,
//                                 withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        // This method is called when a notification is delivered while the app is in the foreground.
//        print("🔔 Foreground notification received: \(notification.request.content.title) (ID: \(notification.request.identifier))")
//        completionHandler([.banner, .sound, .badge]) // Show banner, play sound, update badge
//    }
//
//    func userNotificationCenter(_ center: UNUserNotificationCenter,
//                                 didReceive response: UNNotificationResponse,
//                                 withCompletionHandler completionHandler: @escaping () -> Void) {
//        // This method is called when the user interacts with a notification.
//        print("🔔 User interacted with notification: \(response.notification.request.content.title) (ID: \(response.notification.request.identifier))")
//        // You can add logic here to navigate to a specific part of your app
//        // based on the notification's userInfo or identifier.
//        completionHandler()
//    }
//}

// MARK: - SMAEmailAlertsView (Main View for Alerts Tab - 5th Screen)
struct SMAEmailAlertsView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State for Dynamic Queries
    @State private var currentUserID: String = "no-user"
    @State private var currentDayStart: Date = Calendar.current.startOfDay(for: Date())
    @State private var currentDayEnd: Date = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!
    
    // MARK: - Queries
    @Query private var alerts: [SMAAlert]
    @Query private var userSettingsQuery: [UserSettings]
    @Query private var medicines: [Medicine]
    @Query private var vitalReadings: [VitalReading]
    
    // Computed property to get current user's settings
    private var currentUserSettings: UserSettings? {
        userSettingsQuery.first { $0.userID == authManager.currentUserUID }
    }
    
    // Initializer to set up dynamic query predicates
    init() {
        let userID = Auth.auth().currentUser?.uid ?? "no-user"
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        _currentUserID = State(initialValue: userID)
        _currentDayStart = State(initialValue: startOfDay)
        _currentDayEnd = State(initialValue: endOfDay)
        
        // Query for alerts (no userID filter here, filter in body)
        let alertPredicate = #Predicate<SMAAlert> { alert in
            alert.sentAt >= startOfDay && alert.sentAt < endOfDay
        }
        _alerts = Query(filter: alertPredicate, sort: \.sentAt, order: .reverse)
        
        // Query for user settings
        let settingsPredicate = #Predicate<UserSettings> { settings in
            settings.userID == userID
        }
        _userSettingsQuery = Query(filter: settingsPredicate)
        
        // Query for medicines
        let medicinePredicate = #Predicate<Medicine> { medicine in
            medicine.userSettings?.userID == userID
        }
        _medicines = Query(filter: medicinePredicate)
        
        // Query for vital readings
        let vitalPredicate = #Predicate<VitalReading> { reading in
            reading.userSettings?.userID == userID && reading.date >= startOfDay && reading.date < endOfDay
        }
        _vitalReadings = Query(filter: vitalPredicate, sort: \.date, order: .reverse)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    SMAEmailAlertsHeaderView(
                        sendTestAlert: {
                            if let settings = currentUserSettings {
                                let alert = SMAAlert(
                                    type: .report,
                                    recipient: settings.alertSettings.emergencyContacts.joined(separator: ", "),
                                    subject: "📢 Test Alert",
                                    status: .pending,
                                    sentAt: Date(),
                                    content: "This is a test alert from Smart HealthMate. (This alert only logs in the app; no local notification is sent from here.)"
                                )
                                modelContext.insert(alert)
                                do {
                                    try modelContext.save()
                                    print("Test alert saved: \(alert.subject), type: \(alert.type.rawValue)")
                                    // No local notification sent from here.
                                    alert.status = .sent // Simulate immediate sending for logging
                                    try modelContext.save()
                                } catch {
                                    print("Error saving test alert: \(error.localizedDescription)")
                                }
                            } else {
                                print("Cannot send test alert: No user settings found")
                            }
                        },
                        simulateEmergencyAlert: {
                            if let settings = currentUserSettings {
                                let alert = SMAAlert(
                                    type: .emergency,
                                    recipient: settings.alertSettings.emergencyContacts.joined(separator: ", "),
                                    subject: "🚨 Simulated Emergency Alert",
                                    status: .pending,
                                    sentAt: Date(),
                                    content: "This is a simulated emergency alert from Smart HealthMate. (This alert only logs in the app; no local notification is sent from here.)"
                                )
                                modelContext.insert(alert)
                                do {
                                    try modelContext.save()
                                    print("Emergency alert saved: \(alert.subject), type: \(alert.type.rawValue)")
                                    // No local notification sent from here.
                                    alert.status = .sent // Simulate immediate sending for logging
                                    try modelContext.save()
                                } catch {
                                    print("Error saving emergency alert: \(error.localizedDescription)")
                                }
                            } else {
                                print("Cannot send emergency alert: No user settings found")
                            }
                        }
                    )
                    .padding(.horizontal)
                    
                    // Alert Stats Cards
                    VStack(spacing: 16) {
                        SMAEmailAlertStatsCard(
                            title: "Emergency Alerts",
                            count: alerts.filter { $0.type == .emergency }.count,
                            icon: "exclamationmark.triangle.fill",
                            iconColor: .red,
                            cardBorderColor: .red.opacity(0.2),
                            cardGradient: LinearGradient(gradient: Gradient(colors: [.red.opacity(0.05), .red.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        SMAEmailAlertStatsCard(
                            title: "Emergency Contacts",
                            count: currentUserSettings?.alertSettings.emergencyContacts.count ?? 0,
                            icon: "envelope.fill",
                            iconColor: .blue,
                            cardBorderColor: .blue.opacity(0.2),
                            cardGradient: LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.05), .blue.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        SMAEmailAlertStatsCard(
                            title: "Delivery Rate",
                            countText: alerts.isEmpty ? "0%" : "\(Int(round(Double(alerts.filter { $0.status == .sent }.count) / Double(alerts.count) * 100)))%",
                            icon: "checkmark.circle.fill",
                            iconColor: .green,
                            cardBorderColor: .green.opacity(0.2),
                            cardGradient: LinearGradient(gradient: Gradient(colors: [.green.opacity(0.05), .green.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Recent Alerts Section or Placeholder
                    if alerts.isEmpty {
                        SMANoEmailAlertsPlaceholderView()
                            .padding(.horizontal)
                    } else {
                        SMARecentEmailAlertsSection(
                            alerts: alerts,
                            getStatusIcon: getStatusIcon,
                            getStatusIconColor: getStatusIconColor,
                            getTypeForBadge: getTypeForBadge,
                            getBadgeColors: getBadgeColors
                        )
                    }
                }
                .padding(.bottom, 80)
                .padding(.vertical)
            }
            .navigationTitle("Email Alert System")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            requestNotificationPermission() // Still request permission for the app
            cleanUpInvalidAlerts()
            updateState()
            if authManager.currentUserUID != nil {
                Task {
                    await deleteOldAlerts()
                    await checkAndSendDailyAlerts()
                }
            }
        }
        .onChange(of: authManager.currentUserUID) { _, newUID in
            updateState()
            cleanUpInvalidAlerts()
            if newUID != nil {
                Task {
                    await deleteOldAlerts()
                    await checkAndSendDailyAlerts()
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func updateState() {
        currentUserID = authManager.currentUserUID ?? "no-user"
        currentDayStart = Calendar.current.startOfDay(for: Date())
        currentDayEnd = Calendar.current.date(byAdding: .day, value: 1, to: currentDayStart)!
    }
    
    private func getStatusIcon(_ status: SMAAlert.SMAAlertStatus) -> Image {
        switch status {
        case .sent: return Image(systemName: "checkmark.circle.fill")
        case .failed: return Image(systemName: "xmark.circle.fill")
        case .pending: return Image(systemName: "hourglass.circle.fill")
        }
    }
    
    private func getStatusIconColor(_ status: SMAAlert.SMAAlertStatus) -> Color {
        switch status {
        case .sent: return .green
        case .failed: return .red
        case .pending: return .orange
        }
    }
    
    private func getTypeForBadge(_ type: SMAAlert.SMAAlertType) -> String {
        return type.rawValue
    }
    
    private func getBadgeColors(_ type: String) -> (bg: Color, text: Color, border: Color) {
        var bgColor: Color = .gray.opacity(0.1)
        var textColor: Color = .gray
        var borderColor: Color = .gray.opacity(0.2)
        
        switch type {
        case "Emergency":
            bgColor = .red.opacity(0.1)
            textColor = .red
            borderColor = .red.opacity(0.2)
        case "Reminder":
            bgColor = .blue.opacity(0.1)
            textColor = .blue
            borderColor = .blue.opacity(0.2)
        case "Report":
            bgColor = .green.opacity(0.1)
            textColor = .green
            borderColor = .green.opacity(0.2)
        case "unknown":
            bgColor = .gray.opacity(0.1)
            textColor = .gray
            borderColor = .gray.opacity(0.2)
        default:
            break
        }
        return (bgColor, textColor, borderColor)
    }
    
    // MARK: - Notification Permission
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }
    }
    
    // NEW: Helper function to send local notification for email alert confirmation
    private func sendLocalNotification(for alert: SMAAlert) {
        let content = UNMutableNotificationContent()
        content.title = "Email Alert Sent: \(alert.subject)"
        content.body = "To: \(alert.recipient). Content: \(alert.content.prefix(100))" + (alert.content.count > 100 ? "..." : "")
        content.sound = .default
        content.userInfo = ["alertID": alert.id.uuidString, "alertType": alert.type.rawValue]
        
        let request = UNNotificationRequest(identifier: "email_alert_\(alert.id.uuidString)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending local notification for email alert: \(error.localizedDescription)")
            } else {
                print("Local notification sent for email alert: \(alert.subject)")
            }
        }
    }
    
    // NEW: Helper function to simulate email sending and log it
    private func simulateAndLogEmailSend(for alert: SMAAlert) {
        print("\n--- SIMULATING EMAIL SEND ---")
        print("Type: \(alert.type.rawValue)")
        print("Recipient(s): \(alert.recipient)")
        print("Subject: \(alert.subject)")
        print("Content:\n\(alert.content)")
        print("--- END SIMULATION ---\n")
    }
    
    // MARK: - Alert Cleanup Logic
    private func cleanUpInvalidAlerts() {
        do {
            let descriptor = FetchDescriptor<SMAAlert>()
            let allAlerts = try modelContext.fetch(descriptor)
            let validTypes = SMAAlert.SMAAlertType.allCases.map { $0.rawValue }.filter { $0 != "unknown" }
            let invalidAlerts = allAlerts.filter { !validTypes.contains($0.type.rawValue) }
            
            for alert in invalidAlerts {
                print("Deleting invalid alert: ID=\(alert.id), type=\(alert.type.rawValue), subject=\(alert.subject)")
                modelContext.delete(alert)
            }
            try modelContext.save()
            print("Deleted \(invalidAlerts.count) invalid alerts")
        } catch {
            print("Error cleaning up invalid alerts: \(error.localizedDescription)")
        }
    }
    
    private func deleteOldAlerts() async {
        guard let uid = authManager.currentUserUID else { return }
        let calendar = Calendar.current
        let oneDayAgo = calendar.date(byAdding: .day, value: -1, to: Date())!
        
        do {
            let predicate = #Predicate<SMAAlert> { alert in
                alert.sentAt < oneDayAgo && alert.recipient.contains(uid)
            }
            let descriptor = FetchDescriptor<SMAAlert>(predicate: predicate)
            let oldAlerts = try modelContext.fetch(descriptor)
            
            for alert in oldAlerts {
                modelContext.delete(alert)
            }
            try modelContext.save()
            print("Deleted \(oldAlerts.count) old alerts for user \(uid).")
        } catch {
            print("Error deleting old alerts: \(error)")
        }
    }
    
    // MARK: - Alert Generation Logic (UPDATED)
    private func checkAndSendDailyAlerts() async {
        guard let uid = authManager.currentUserUID,
              let currentUserDisplayName = authManager.currentUserDisplayName,
              let settings = currentUserSettings?.alertSettings else {
            print("Cannot check and send daily alerts: User not logged in or settings unavailable.")
            return
        }
        
        let today = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        do {
            let predicate = #Predicate<SMAAlert> { alert in
                alert.sentAt >= startOfDay && alert.sentAt < endOfDay && alert.recipient.contains(uid)
            }
            let descriptor = FetchDescriptor<SMAAlert>(predicate: predicate)
            let existingAlertsToday = try modelContext.fetch(descriptor)
            
            // MARK: - Check for Missed Medicines (Daily Report)
            // Only send one daily medicine report per day
            let hasSentDailyMedicineReport = existingAlertsToday.contains(where: { $0.type == .report && $0.subject.contains("Daily Medicine Report") })
            
            if !hasSentDailyMedicineReport {
                let userMedicines = medicines.filter { $0.userSettings?.userID == uid && $0.isActive && $0.isCurrentlyActiveBasedOnDates }
                var missedMedicinesDetails: [String] = []
                
                // Ensure calendar and today are defined once outside the inner loop
                let calendar = Calendar.current
                let today = Date() // Get the current date
                
                for medicine in userMedicines {
                                                    // Ensure calendar and today are defined once outside the inner loop
                                                    let calendar = Calendar.current
                                                    let today = Date()

                                                    // Check if the medicine has any missed doses today
                                                    let missedDosesForMedicine = medicine.scheduledDoses?.filter { dose in
                                                        let doseTimeComponents = calendar.dateComponents([.hour, .minute], from: dose.time)
                                                        guard let scheduledTimeToday = calendar.date(bySettingHour: doseTimeComponents.hour!, minute: doseTimeComponents.minute!, second: 0, of: today) else { return false }
                                                        
                                                        // 1. Check if the scheduled time for this dose on today's date has passed
                                                        let isScheduledTimePast = scheduledTimeToday < today

                                                        // 2. Check if a DoseTakenEvent exists for this specific ScheduledDose on today's date
                                                        //    Use 'dose' as the parameter name here as defined by the filter closure
                                                        let doseWasTakenToday = medicine.doseLogEvents?.contains(where: { event in
                                                            calendar.isDate(event.dateRecorded, inSameDayAs: today) && event.scheduledDose?.id == dose.id
                                                        }) ?? false

                                                        // 3. A dose is "missed" if its scheduled time is past AND it has NOT been taken today
                                                        return isScheduledTimePast && !doseWasTakenToday
                                                    } ?? [] // Ensure you provide a default empty array if scheduledDoses is nil

                                                    if !missedDosesForMedicine.isEmpty {
                                                        let missedTimes = missedDosesForMedicine.map {
                                                            // FIX: Use the simplified formatted(date:time:) syntax
                                                            $0.time.formatted(.dateTime.hour().minute())                                                        }.joined(separator: ", ")
                                                        missedMedicinesDetails.append("• \(medicine.name) (\(medicine.dosage)) - Missed at: \(missedTimes)")
                                                    }
                                                }
                
                if !missedMedicinesDetails.isEmpty {
                    let recipient = settings.emergencyContacts.joined(separator: ", ")
                    let content = """
Dear Emergency Contact,

This is your daily medicine adherence report for \(currentUserDisplayName).

The following medicines were missed today:
\(missedMedicinesDetails.joined(separator: "\n"))

📅 Date: \(Date().formatted(date: .numeric, time: .shortened))

⚡ Recommended Action:
• Please follow up with \(currentUserDisplayName) regarding their medication adherence.

This report was generated automatically by Smart HealthMate.

Best regards,
Smart HealthMate System
"""
                    let reminderAlert = SMAAlert(
                        type: .report, // Changed to .report for daily reports
                        recipient: recipient,
                        subject: "💊 Daily Medicine Report: Missed Doses for \(currentUserDisplayName)",
                        status: .pending,
                        sentAt: Date(),
                        content: content
                    )
                    modelContext.insert(reminderAlert)
                    do {
                        try modelContext.save()
                        print("Daily medicine report for missed doses added to SwiftData for emergency contacts: \(recipient).")
                        simulateAndLogEmailSend(for: reminderAlert)
                        reminderAlert.status = .sent // Simulate immediate sending
                        try modelContext.save()
                        sendLocalNotification(for: reminderAlert) // Local notification for confirmation
                    } catch {
                        print("Error saving daily medicine report: \(error.localizedDescription)")
                    }
                }
            }
            
            
            // MARK: - Check for Out-of-Threshold Vital Readings (BP & Sugar)
            let userVitalReadings = vitalReadings.filter { $0.userSettings?.userID == uid && $0.date >= startOfDay && $0.date < endOfDay }
            
            // Check BP Readings
            if let latestBP = userVitalReadings.filter({ $0.type == .bp }).sorted(by: { $0.date > $1.date }).first,
               let systolic = latestBP.systolic, let diastolic = latestBP.diastolic {
                let bpThreshold = settings.bpThreshold
                var bpAlertNeeded = false
                var bpAlertContent = ""
                
                if systolic < bpThreshold.minSystolic || systolic > bpThreshold.maxSystolic {
                    bpAlertNeeded = true
                    bpAlertContent += "Systolic pressure is outside your set thresholds (\(bpThreshold.minSystolic)-\(bpThreshold.maxSystolic)). "
                }
                if diastolic < bpThreshold.minDiastolic || diastolic > bpThreshold.maxDiastolic {
                    bpAlertNeeded = true
                    bpAlertContent += "Diastolic pressure is outside your set thresholds (\(bpThreshold.minDiastolic)-\(bpThreshold.maxDiastolic))."
                }
                
                // Check if an emergency BP alert has already been sent today
                let hasSentBPAlertToday = existingAlertsToday.contains(where: { $0.type == .emergency && $0.subject.contains("BP Out of Range!") })
                
                if bpAlertNeeded && !hasSentBPAlertToday {
                    let recipient = settings.emergencyContacts.joined(separator: ", ")
                    let content = """
Dear Emergency Contact,

An emergency has been detected for \(currentUserDisplayName).

🩺 BP Reading Details:
• Reading: \(systolic)/\(diastolic) mmHg
• Time: \(latestBP.date.formatted(date: .numeric, time: .shortened))
• Status: OUT OF RANGE - Immediate attention required. \(bpAlertContent)

⚡ Recommended Actions:
1. Contact the patient immediately
2. Consider emergency medical services
3. Ensure patient is seated and calm
4. Monitor for additional symptoms

This alert was generated automatically by Smart HealthMate.

Best regards,
Smart HealthMate Emergency System
"""
                    let bpAlert = SMAAlert(
                        type: .emergency,
                        recipient: recipient,
                        subject: "🚨 Emergency Alert: BP Out of Range!",
                        status: .pending,
                        sentAt: Date(),
                        content: content
                    )
                    modelContext.insert(bpAlert)
                    do {
                        try modelContext.save()
                        print("BP alert added to SwiftData for emergency contacts: \(recipient).")
                        simulateAndLogEmailSend(for: bpAlert)
                        bpAlert.status = .sent // Simulate immediate sending
                        try modelContext.save()
                        sendLocalNotification(for: bpAlert) // Local notification for confirmation
                    } catch {
                        print("Error saving BP alert: \(error.localizedDescription)")
                    }
                }
            }
            
            // Blood Sugar Readings
            if let latestSugar = userVitalReadings.filter({ $0.type == .sugar }).sorted(by: { $0.date > $1.date }).first,
               let sugarLevel = latestSugar.sugarLevel {
                let sugarThreshold = settings.fastingSugarThreshold // Assuming fasting for simplicity here, can extend to afterMeal
                var sugarAlertNeeded = false
                var sugarAlertContent = ""
                
                if sugarLevel < sugarThreshold.min || sugarLevel > sugarThreshold.max {
                    sugarAlertNeeded = true
                    sugarAlertContent += "Blood sugar level is outside your set thresholds (\(sugarThreshold.min)-\(sugarThreshold.max))."
                }
                
                // Check if an emergency Sugar alert has already been sent today
                let hasSentSugarAlertToday = existingAlertsToday.contains(where: { $0.type == .emergency && $0.subject.contains("Blood Sugar Out of Range!") })
                
                if sugarAlertNeeded && !hasSentSugarAlertToday {
                    let recipient = settings.emergencyContacts.joined(separator: ", ")
                    let content = """
Dear Emergency Contact,

An emergency has been detected for \(currentUserDisplayName).

🩺 Blood Sugar Reading Details:
• Reading: \(sugarLevel) mg/dL
• Time: \(latestSugar.date.formatted(date: .numeric, time: .shortened))
• Status: OUT OF RANGE - Immediate attention required. \(sugarAlertContent)

⚡ Recommended Actions:
1. Contact the patient immediately
2. Consider emergency medical services
3. Monitor for additional symptoms

This alert was generated automatically by Smart HealthMate.

Best regards,
Smart HealthMate Emergency System
"""
                    let sugarAlert = SMAAlert(
                        type: .emergency,
                        recipient: recipient,
                        subject: "🚨 Emergency Alert: Blood Sugar Out of Range!",
                        status: .pending,
                        sentAt: Date(),
                        content: content
                    )
                    modelContext.insert(sugarAlert)
                    do {
                        try modelContext.save()
                        print("Blood sugar alert added to SwiftData for emergency contacts: \(recipient).")
                        simulateAndLogEmailSend(for: sugarAlert)
                        sugarAlert.status = .sent // Simulate immediate sending
                        try modelContext.save()
                        sendLocalNotification(for: sugarAlert) // Local notification for confirmation
                    } catch {
                        print("Error saving sugar alert: \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            print("Error fetching existing alerts: \(error.localizedDescription)")
        }
    }
}

// MARK: - Single Alert Stat Card Sub-View
struct SMAEmailAlertStatsCard: View {
    let title: String
    let count: Int?
    let countText: String?
    let icon: String
    let iconColor: Color
    let cardBorderColor: Color
    let cardGradient: LinearGradient
    
    init(title: String, count: Int? = nil, countText: String? = nil, icon: String, iconColor: Color, cardBorderColor: Color, cardGradient: LinearGradient) {
        self.title = title
        self.count = count
        self.countText = countText
        self.icon = icon
        self.iconColor = iconColor
        self.cardBorderColor = cardBorderColor
        self.cardGradient = cardGradient
    }
    
    var body: some View {
        SMACustomCards(borderColor: cardBorderColor, gradient: cardGradient) {
            SMACustomCardContents {
                HStack {
                    VStack(alignment: .leading) {
                        Text(countText ?? "\(count ?? 0)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(iconColor.opacity(0.7))
                        Text(title)
                            .font(.caption)
                            .foregroundColor(iconColor.opacity(0.6))
                    }
                    Spacer()
                    Image(systemName: icon)
                        .font(.title2)
                        .padding(8)
                        .background(iconColor.opacity(0.2))
                        .clipShape(Circle())
                        .foregroundColor(iconColor.opacity(0.7))
                }
            }
        }
    }
}

// MARK: - Sub-Views for Better Organization

// Header and Action Buttons Sub-View
struct SMAEmailAlertsHeaderView: View {
    let sendTestAlert: () -> Void
    let simulateEmergencyAlert: () -> Void
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Email Alert System")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.gray.opacity(0.9))
                Text("Automated health emergency and reminder notifications")
                    .font(.subheadline)
                    .foregroundColor(.gray.opacity(0.7))
            }
            Spacer()
            HStack(spacing: 8) {
                Button(action: sendTestAlert) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Send Test")
                    }
                    .font(.footnote)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
                
                Button(action: simulateEmergencyAlert) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Simulate Emergency")
                    }
                    .font(.footnote)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.red.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
    }
}


// Recent Alerts Section Sub-View
struct SMARecentEmailAlertsSection: View {
    let alerts: [SMAAlert]
    let getStatusIcon: (_ status: SMAAlert.SMAAlertStatus) -> Image
    let getStatusIconColor: (_ status: SMAAlert.SMAAlertStatus) -> Color
    let getTypeForBadge: (SMAAlert.SMAAlertType) -> String
    let getBadgeColors: (String) -> (bg: Color, text: Color, border: Color)
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Email Alerts")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ForEach(alerts, id: \.id) { alert in
                SMACustomCards {
                    VStack(alignment: .leading) {
                        SMACustomCardHeaders(paddingBottom: 12) {
                            HStack(alignment: .top) {
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                        .font(.body)
                                        .padding(8)
                                        .background(Color.gray.opacity(0.1))
                                        .clipShape(Circle())
                                        .foregroundColor(.gray.opacity(0.6))
                                    VStack(alignment: .leading) {
                                        SMACustomCardTitles(text: alert.subject, fontSize: 18)
                                        SMACustomCardDescriptions(text: "To: \(alert.recipient) on \(Self.dateFormatter.string(from: alert.sentAt)) at \(Self.timeFormatter.string(from: alert.sentAt))")
                                    }
                                }
                                Spacer()
                                HStack(spacing: 8) {
                                    let badgeType = getTypeForBadge(alert.type)
                                    let colors = getBadgeColors(badgeType)
                                    SMACustomBadges(text: badgeType.uppercased(), variant: "outline")
                                        .background(colors.bg)
                                        .foregroundColor(colors.text)
                                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(colors.border, lineWidth: 1))
                                    
                                    HStack(spacing: 4) {
                                        getStatusIcon(alert.status)
                                            .foregroundColor(getStatusIconColor(alert.status))
                                        Text(alert.status.rawValue.capitalized)
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                        
                        SMACustomCardContents {
                            Text(alert.content)
                                .font(.footnote)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(12)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}


// No Alerts Placeholder Sub-View
struct SMANoEmailAlertsPlaceholderView: View {
    var body: some View {
        SMACustomCards {
            SMACustomCardContents {
                VStack(spacing: 16) {
                    Image(systemName: "envelope.fill")
                        .font(.largeTitle)
                        .padding(16)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                        .foregroundColor(.gray.opacity(0.6))
                    
                    VStack(spacing: 4) {
                        Text("No alerts sent yet")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("Email alerts will appear here when triggered")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
    }
}
