import SwiftUI

// SMAAlert Models (for Email Alert System)
struct SMAAlert: Identifiable {
    let id = UUID()
    let type: SMAAlertType
    let recipient: String
    let subject: String
    var status: SMAAlertStatus
    let sentAt: Date
    let content: String

    enum SMAAlertType: String, CaseIterable, Codable {
        case emergency = "Emergency"
        case reminder = "Reminder"
        case report = "Report"
    }

    enum SMAAlertStatus: String, Codable {
        case sent = "Sent"
        case failed = "Failed"
        case pending = "Pending"
    }
}

struct SMAAlertSettings {
    var emergencyContacts: [String]
    var bpThreshold: SMABPThreshold
    var sugarThreshold: Int
    var enableEmergencyAlerts: Bool
    var enableReminderAlerts: Bool
    var enableReportAlerts: Bool

    struct SMABPThreshold {
        var systolic: Int
        var diastolic: Int
    }
}


// MARK: - DateFormatter Extension (for SMAMedicine and SMAAlerts)
extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
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

// MARK: - EmailAlertsView (Main View for Alerts Tab)
// This view manages and displays the email alert system.
struct SMAEmailAlertsView: View {
    let medicines: Int // Added binding
    

    @State private var alerts: [SMAAlert] = [
        SMAAlert(
            type: .emergency,
            recipient: "family@example.com",
            subject: "🚨 Emergency Alert: High BP Detected",
            status: .sent,
            sentAt: Date().addingTimeInterval(-3600 * 2), // 2 hours ago
            content: "BP Reading: 185/120 detected at 11:00 PM. Immediate attention advised."
        ),
        SMAAlert(
            type: .reminder,
            recipient: "user@example.com",
            subject: "💊 Medicine Reminder: Missed Dose Alert",
            status: .sent,
            sentAt: Date().addingTimeInterval(-3600 * 4), // 4 hours ago
            content: "You missed your evening Metformin dose. Please take it now if within 2 hours."
        )
    ]

    @State private var settings: SMAAlertSettings = SMAAlertSettings(
        emergencyContacts: ["family@example.com", "doctor@example.com"],
        bpThreshold: SMAAlertSettings.SMABPThreshold(systolic: 180, diastolic: 110),
        sugarThreshold: 250,
        enableEmergencyAlerts: true,
        enableReminderAlerts: true,
        enableReportAlerts: false
    )

    @State private var isSettingsOpen: Bool = false
    @State private var newContact: String = ""
    @State private var bpSystolicInput: String = "" // For TextField binding
    @State private var bpDiastolicInput: String = "" // For TextField binding
    @State private var sugarThresholdInput: String = "" // For TextField binding

    // MARK: - Lifecycle
    init(medicines: Int) {
        self.medicines = medicines
        
        // Initialize State variables using the settings' initial values
        _bpSystolicInput = State(initialValue: String(settings.bpThreshold.systolic))
        _bpDiastolicInput = State(initialValue: String(settings.bpThreshold.diastolic))
        _sugarThresholdInput = State(initialValue: String(settings.sugarThreshold))
    }

    // MARK: - Actions
    private func sendTestAlert() {
        let testAlert = SMAAlert(
            type: .emergency,
            recipient: settings.emergencyContacts.first ?? "test@example.com",
            subject: "🧪 Test Alert: System Check",
            status: .pending,
            sentAt: Date(),
            content: "This is a test alert to verify the email system is working properly."
        )
        alerts.insert(testAlert, at: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if let index = alerts.firstIndex(where: { $0.id == testAlert.id }) {
                alerts[index].status = .sent
            }
            print("Test alert sent successfully!")
        }
    }

    private func simulateEmergencyAlert() {
        let emergencyAlert = SMAAlert(
            type: .emergency,
            recipient: settings.emergencyContacts.first ?? "emergency@example.com",
            subject: "🚨 Emergency Alert: Critical BP Reading",
            status: .pending,
            sentAt: Date(),
            content: """
Dear Emergency Contact,

An emergency has been detected for John Doe.

🩺 Critical Reading Details:
• BP Reading: 195/125 mmHg
• Time: \(Date().formatted(date: .numeric, time: .shortened))
• Status: CRITICAL - Immediate attention required

📍 Patient Information:
• Last Known Location: Home
• Emergency Medications: Amlodipine 5mg, Metformin 500mg
• Recent Symptoms: Severe headache reported

⚡ Immediate Actions Recommended:
1. Contact patient immediately
2. Consider emergency medical services
3. Ensure patient is seated and calm
4. Monitor for additional symptoms

This alert was generated automatically by Smart HealthMate.

Best regards,
Smart HealthMate Emergency System
"""
        )
        alerts.insert(emergencyAlert, at: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if let index = alerts.firstIndex(where: { $0.id == emergencyAlert.id }) {
                alerts[index].status = .sent
            }
            print("Emergency alert sent to all contacts!")
        }
    }

    private func addEmergencyContact() {
        if !newContact.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && newContact.contains("@") {
            if !settings.emergencyContacts.contains(newContact) {
                settings.emergencyContacts.append(newContact)
                newContact = ""
                print("Emergency contact added")
            } else {
                print("Contact already exists")
            }
        } else {
            print("Please enter a valid email address")
        }
    }

    private func removeEmergencyContact(email: String) {
        settings.emergencyContacts.removeAll { $0 == email }
        print("Emergency contact removed")
    }

    // MARK: - Helper for Icons and Colors
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
        default:
            break
        }
        return (bgColor, textColor, borderColor)
    }

    // MARK: - Main Body
    var body: some View {
        NavigationView { // NavigationView se wrap kiya gaya hai
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Automated health emergency and reminder notifications")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }

                    // Medicine Tracker Stats (NEWLY ADDED SECTION)
                    SMAMedicineTrackerStats(medicinesCount: medicines)
                        .padding(.horizontal) // Apply horizontal padding for these cards

                    // Alert Stats (Now arranged vertically)
                    VStack(spacing: 16) {
                        SMAEmailAlertStatsCard(
                            title: "Emergency Alerts",
                            count: alerts.filter { $0.type == .emergency }.count,
                            icon: "exclamationmark.triangle.fill",
                            iconColor: .red,
                            cardBorderColor: .red.opacity(0.2),
                            cardGradient: LinearGradient(gradient: Gradient(colors: [Color.red.opacity(0.05), Color.red.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        SMAEmailAlertStatsCard(
                            title: "Emergency Contacts",
                            count: settings.emergencyContacts.count,
                            icon: "envelope.fill",
                            iconColor: .blue,
                            cardBorderColor: .blue.opacity(0.2),
                            cardGradient: LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.blue.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        SMAEmailAlertStatsCard(
                            title: "Delivery Rate",
                            countText: "\(alerts.isEmpty ? 0 : Int(round(Double(alerts.filter { $0.status == .sent }.count) / Double(alerts.count) * 100)))%",
                            icon: "checkmark.circle.fill",
                            iconColor: .green,
                            cardBorderColor: .green.opacity(0.2),
                            cardGradient: LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.05), Color.green.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    }
                    .padding(.horizontal, 20)
                    // Padding for the cards stack

                    // Recent Alerts
                    SMARecentEmailAlertsSection(
                        alerts: alerts,
                        getStatusIcon: getStatusIcon,
                        getStatusIconColor: getStatusIconColor,
                        getTypeForBadge: getTypeForBadge,
                        getBadgeColors: getBadgeColors
                    )

                    // No Alerts Placeholder
                    if alerts.isEmpty {
                        SMANoEmailAlertsPlaceholderView()
                    }
                }
                
                .padding(.bottom, 80)
                .padding(.vertical) // Overall vertical padding for the scroll view content
            }
            .navigationTitle("Email Alert System")
             // .inline to make space for custom title view
            .toolbar {
//                ToolbarItem(placement: .principal) { // principal placement for custom title view
//                    VStack(alignment: .center, spacing: 4) { // Centered for cleaner look
//                        Text("Email Alert System")
//                            .font(.headline)
//                            .fontWeight(.bold)
//                            .foregroundColor(.gray.opacity(0.9))
//                            .lineLimit(1) // Ensure it doesn't wrap and take too much space
//                            .minimumScaleFactor(0.8) // Allow font to scale down if needed
//                        Text("Automated health emergency and reminder notifications")
//                            .font(.caption)
//                            .foregroundColor(.gray.opacity(0.7))
//                            .lineLimit(1) // Ensure it doesn't wrap
//                            .minimumScaleFactor(0.7) // Allow font to scale down if needed
//                    }
//                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) { // Buttons ko HStack mein rakha gaya hai
                        Button(action: sendTestAlert) {
                            Text("Test")
                                .font(.caption)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .background(Color.gray.opacity(0.1))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                        }
                        
                        Button(action: simulateEmergencyAlert) {
                            Text("Simulate")
                                .font(.caption)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .background(Color.red.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        Button(action: { isSettingsOpen = true }) {
                            Text("Settings")
                                .font(.caption)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .background(Color.gray.opacity(0.1))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                        }
                    }
                    // Adding fixed width for toolbar items if necessary, or letting them adapt
                    // .fixedSize(horizontal: true, vertical: false) // Optional: If buttons still break
                }
            }
            .sheet(isPresented: $isSettingsOpen) {
                SMAEmailAlertsSettingsView(
                    settings: $settings,
                    isSettingsOpen: $isSettingsOpen,
                    newContact: $newContact,
                    bpSystolicInput: $bpSystolicInput,
                    bpDiastolicInput: $bpDiastolicInput,
                    sugarThresholdInput: $sugarThresholdInput,
                    addEmergencyContact: addEmergencyContact,
                    removeEmergencyContact: removeEmergencyContact
                )
            }
        }
    }
}

// MARK: - Single Alert Stat Card Sub-View
// Ye ek naya component hai jo har ek stat card ko represent karta hai,
// taake `SMAEmailAlertStatsView` mein inko vertically arrange kiya ja sake.
struct SMAEmailAlertStatsCard: View {
    let title: String
    let count: Int?
    let countText: String? // For percentage or custom text
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
                        Text(countText ?? "\(count ?? 0)") // Use countText if available, otherwise count
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
    @Binding var isSettingsOpen: Bool
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
                
                Button(action: { isSettingsOpen = true }) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                    .font(.footnote)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Settings Sheet Sub-View (for Alerts)
// View for configuring email alert settings.
struct SMAEmailAlertsSettingsView: View {
    @Binding var settings: SMAAlertSettings
    @Binding var isSettingsOpen: Bool
    @Binding var newContact: String
    @Binding var bpSystolicInput: String
    @Binding var bpDiastolicInput: String
    @Binding var sugarThresholdInput: String
    let addEmergencyContact: () -> Void
    let removeEmergencyContact: (String) -> Void

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Email Alert Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Configure emergency contacts and alert thresholds")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 8)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Emergency Contacts")
                        .font(.headline)
                    
                    VStack(spacing: 8) {
                        ForEach(settings.emergencyContacts, id: \.self) { contact in
                            HStack {
                                Text(contact)
                                    .font(.subheadline)
                                Spacer()
                                Button(action: { removeEmergencyContact(contact) }) {
                                    Text("Remove")
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(8)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(6)
                        }
                        
                        HStack(spacing: 8) {
                            TextField("Add emergency contact email", text: $newContact)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                            Button(action: addEmergencyContact) {
                                Text("Add")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BP Alert Threshold")
                            .font(.headline)
                        HStack(spacing: 8) {
                            TextField("Systolic", text: $bpSystolicInput)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                                .onChange(of: bpSystolicInput) { newValue in
                                    if let intValue = Int(newValue) {
                                        settings.bpThreshold.systolic = intValue
                                    }
                                }
                            TextField("Diastolic", text: $bpDiastolicInput)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                                .onChange(of: bpDiastolicInput) { newValue in
                                    if let intValue = Int(newValue) {
                                        settings.bpThreshold.diastolic = intValue
                                    }
                                }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sugar Alert Threshold")
                            .font(.headline)
                        TextField("mg/dL", text: $sugarThresholdInput)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .onChange(of: sugarThresholdInput) { newValue in
                                if let intValue = Int(newValue) {
                                    settings.sugarThreshold = intValue
                                }
                            }
                    }
                }

                Spacer()

                HStack {
                    Spacer()
                    Button(action: { isSettingsOpen = false }) {
                        Text("Save Settings")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isSettingsOpen = false
                    }
                }
            }
        }
    }
}


// Alert Stats Sub-View
struct SMAEmailAlertStatsView: View {
    let alerts: [SMAAlert]
    let settings: SMAAlertSettings

    var body: some View {
        HStack(spacing: 16) {
            // Fix 1: Reordered borderColor and gradient arguments
            SMACustomCards(borderColor: .red.opacity(0.2), gradient: LinearGradient(gradient: Gradient(colors: [Color.red.opacity(0.05), Color.red.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)) {
                SMACustomCardContents {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(alerts.filter { $0.type == .emergency }.count)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.red.opacity(0.7))
                            Text("Emergency Alerts")
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.6))
                        }
                        Spacer()
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .padding(8)
                            .background(Color.red.opacity(0.2))
                            .clipShape(Circle())
                            .foregroundColor(.red.opacity(0.7))
                    }
                }
            }

            // Fix 1: Reordered borderColor and gradient arguments
            SMACustomCards(borderColor: .blue.opacity(0.2), gradient: LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.blue.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)) {
                SMACustomCardContents {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(settings.emergencyContacts.count)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.blue.opacity(0.7))
                            Text("Emergency Contacts")
                                .font(.caption)
                                .foregroundColor(.blue.opacity(0.6))
                        }
                        Spacer()
                        Image(systemName: "envelope.fill")
                            .font(.title2)
                            .padding(8)
                            .background(Color.blue.opacity(0.2))
                            .clipShape(Circle())
                            .foregroundColor(.blue.opacity(0.7))
                    }
                }
            }

            // Fix 1: Reordered borderColor and gradient arguments
            SMACustomCards(borderColor: .green.opacity(0.2), gradient: LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.05), Color.green.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)) {
                SMACustomCardContents {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(alerts.isEmpty ? 0 : Int(round(Double(alerts.filter { $0.status == .sent }.count) / Double(alerts.count) * 100)))%")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.green.opacity(0.7))
                            Text("Delivery Rate")
                                .font(.caption)
                                .foregroundColor(.green.opacity(0.6))
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .padding(8)
                            .background(Color.green.opacity(0.2))
                            .clipShape(Circle())
                            .foregroundColor(.green.opacity(0.7))
                    }
                }
            }
        }
    }
}

// Recent Alerts Section Sub-View
struct SMARecentEmailAlertsSection: View {
    let alerts: [SMAAlert]
    // FIX: Changed parameter name to _status to remove external argument label
    let getStatusIcon: (_ status: SMAAlert.SMAAlertStatus) -> Image
    // FIX: Changed parameter name to _status to remove external argument label
    let getStatusIconColor: (_ status: SMAAlert.SMAAlertStatus) -> Color
    let getTypeForBadge: (SMAAlert.SMAAlertType) -> String // Function parameter
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

            // FIX: Added id: \.id to ForEach to help compiler inference
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
                                        // No change needed here for alert.subject, it's already a String
                                        SMACustomCardTitles(text: alert.subject, fontSize: 18)
                                        // Fix: Format Date to String before passing to Text
                                        SMACustomCardDescriptions(text: "To: \(Self.dateFormatter.string(from: alert.sentAt)) at \(Self.timeFormatter.string(from: alert.sentAt))")
                                    }
                                }
                                Spacer()
                                HStack(spacing: 8) {
                                    // Changed call to getTypeForBadge to remove the 'type:' label
                                    let badgeType = getTypeForBadge(alert.type)
                                    // Changed call to getBadgeColors to remove the 'type:' label
                                    let colors = getBadgeColors(badgeType)
                                    SMACustomBadges(text: badgeType.uppercased(), variant: "outline")
                                        .background(colors.bg)
                                        .foregroundColor(colors.text)
                                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(colors.border, lineWidth: 1))
                                    
                                    HStack(spacing: 4) {
                                        // FIX: Changed call to getStatusIcon to remove the 'status:' label
                                        getStatusIcon(alert.status)
                                            // FIX: Changed call to getStatusIconColor to remove the 'status:' label
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
