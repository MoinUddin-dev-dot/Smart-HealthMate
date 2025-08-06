import SwiftUI
import Foundation
import SwiftData // SwiftData framework ko import karein
import UserNotifications // Notifications ke liye import karein
import FirebaseAuth
import FirebaseFunctions
import UserNotifications

// Notification Delegate to handle notification responses
class NotificationDelegate1: NSObject, UNUserNotificationCenterDelegate {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        super.init()
    }
    
    @MainActor
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.identifier.contains("MissedReminderReport") {
            let missedReminderService = MissedReminderService(authManager: AuthManager())
            missedReminderService.setModelContext(modelContext)
            Task {
                await missedReminderService.checkAndSendMissedReminderEmail()
            }
        }
        completionHandler()
    }
}

class MissedReminderService: ObservableObject {
    private let authManager: AuthManager
    private let notificationCenter = UNUserNotificationCenter.current()
    private var modelContext: ModelContext?

    init(authManager: AuthManager) {
        self.authManager = authManager
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func getMissedReminders(for reminders: [Reminder], date: Date = Date()) -> [(reminder: Reminder, missedTimes: [Date])] {
        guard let userID = authManager.currentUserUID else {
            print("🚫 MissedReminderService: No authenticated user. Skipping missed reminder check.")
            return []
        }
        guard let modelContext = modelContext else {
            print("🚫 MissedReminderService: ModelContext not set. Skipping missed reminder check.")
            return []
        }

        let calendar = Calendar.current
        let todayStartOfDay = calendar.startOfDay(for: date)
        var missedReminders: [(reminder: Reminder, missedTimes: [Date])] = []

        let userReminders = reminders.filter { $0.userSettings?.userID == userID && $0.active && !$0.hasPeriodEnded && !$0.isFutureReminder }

        for reminder in userReminders {
            var missedTimes: [Date] = []
            for time in reminder.times {
                let components = calendar.dateComponents([.hour, .minute], from: time)
                guard let hour = components.hour, let minute = components.minute,
                      let scheduledTimeToday = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) else {
                    continue
                }

                if reminder.isTimeSlotOverdue(time: time) {
                    missedTimes.append(scheduledTimeToday)
                }
            }

            if !missedTimes.isEmpty {
                missedReminders.append((reminder: reminder, missedTimes: missedTimes))
            }
        }

        return missedReminders
    }

    func scheduleDailyMissedReminderCheck() {
        guard let userID = authManager.currentUserUID else {
            print("🚫 MissedReminderService: No authenticated user. Cannot schedule daily check.")
            return
        }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["MissedReminderReport-\(userID)"])

        let timeZone = TimeZone(identifier: "Asia/Karachi")! // PKT, UTC+5
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = 23
        components.minute = 0
        components.timeZone = timeZone

        let content = UNMutableNotificationContent()
        content.title = "Missed Reminder Report"
        content.body = "Missed reminder report has been emailed."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "MissedReminderReport-\(userID)", content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("🔔 Error scheduling missed reminder report notification: \(error.localizedDescription)")
            } else {
                print("🔔 Scheduled missed reminder report notification for 11:00 PM PKT (ID: MissedReminderReport-\(userID))")
            }
        }
    }

    func checkAndSendMissedReminderEmail() async {
        guard let userID = authManager.currentUserUID,
              let modelContext = modelContext else {
            print("🚫 MissedReminderService: No authenticated user or modelContext. Cannot send email.")
            return
        }

        do {
            let userSettingsDescriptor = FetchDescriptor<UserSettings>(predicate: #Predicate { settings in
                settings.userID == userID
            })
            guard let userSettings = try modelContext.fetch(userSettingsDescriptor).first else {
                print("🚫 MissedReminderService: No UserSettings found for user \(userID).")
                return
            }
            let emergencyContacts = userSettings.alertSettings.emergencyContacts
            guard !emergencyContacts.isEmpty else {
                print("🚫 MissedReminderService: No emergency contacts found for user \(userID).")
                NotificationCenter.default.post(name: NSNotification.Name("NoEmergencyContacts"), object: nil)
                return
            }

            let descriptor = FetchDescriptor<Reminder>(predicate: #Predicate { reminder in
                reminder.userSettings?.userID == userID
            })
            let reminders = try modelContext.fetch(descriptor)
            let missedReminders = getMissedReminders(for: reminders)

            if missedReminders.isEmpty {
                print("📧 No missed reminders for user \(userID) today. No email sent.")
                return
            }

            var emailBody = "Dear Attendant(s),\n\n\(userSettings.userName ?? "User") missed some reminders today:\n\n"
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .short

            for (reminder, missedTimes) in missedReminders {
                emailBody += "- \(reminder.title) (\(reminder.type.displayName)) at \(missedTimes.map { dateFormatter.string(from: $0) }.joined(separator: ", "))\n"
            }

            emailBody += "\nPlease ensure the user follows their reminder schedule.\nBest regards,\nSmart HealthMate Team"

            let functions = Functions.functions()
            let data: [String: Any] = [
                "to": emergencyContacts.joined(separator: ","),
                "subject": "Smart HealthMate: Missed Reminder Report for \(userSettings.userName ?? "User")",
                "body": emailBody
            ]

            do {
                let result = try await functions.httpsCallable("sendEmail").call(data)
                print("📧 Successfully sent missed reminder email to \(emergencyContacts.joined(separator: ", ")): \(result.data)")
            } catch {
                print("📧 Error calling sendEmail Cloud Function: \(error.localizedDescription)")
            }
        } catch {
            print("🚫 Error fetching data for missed reminder email: \(error.localizedDescription)")
        }
    }
}
// MARK: - Custom Shape for Specific Corner Radius
// Ye ek helper struct hai jo kisi bhi view ke specific corners ko round karne ke liye use hota hai.
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}


// MARK: - Reminder Class (SwiftData Model)
// Ye hamara data model hai jo SwiftData ke zariye persist kiya jayega.
// `@Model` macro isse database mein store hone ke qabil banata hai.
@Model
final class Reminder { // `struct` se `final class` mein tabdeel kiya gaya
    // `@Attribute(.unique)` ensure karta hai ke har Reminder ka 'id' unique ho database mein.
    @Attribute(.unique) var id: UUID
    var title: String
    var type: ReminderType
    var times: [Date] // Reminder ke waqt (e.g., 9:00 AM, 2:00 PM)
    var startDate: Date // Reminder kab se shuru hoga
    var endDate: Date   // Reminder kab tak chalega
    var active: Bool    // Kya reminder active hai ya pause kiya gaya hai
    var nextDue: Date   // Agla waqt jab reminder due hoga (calculation ke liye)
    // `completedTimes` mein un waqton ko store karte hain jab reminder ke slots complete kiye gaye hain
    var completedTimes: [Date]
    var lastModifiedDate: Date // Akhri baar kab modify kiya gaya
    // `lastResetDate` track karta hai ke `completedTimes` ko akhri baar kab reset kiya gaya tha
    // (daily reset logic ke liye)
    var lastResetDate: Date?
    var userSettings: UserSettings?

    // Computed property jo reminder type ke hisaab se icon name provide karti hai.
    var iconName: String {
        switch type {
        case .checkup: return "stethoscope"
        case .medicine: return "pill.fill"
        }
    }

    // ReminderType enum, jo Reminder class ke andar nested hai.
    // Ye `Codable` hai taake SwiftData isse asani se store kar sake.
    enum ReminderType: String, CaseIterable, Identifiable, Codable {
        case checkup
        case medicine

        var id: String { self.rawValue }
        var displayName: String {
            switch self {
            case .checkup: return "Health Checkup"
            case .medicine: return "Medicine Intake"
            }
        }
    }

    // Check karta hai ke aaj ke din ke liye ek specific time slot complete hua hai ya nahi.
    func isTimeSlotCompleted(time: Date, forDate: Date) -> Bool { // Corrected: Added forDate parameter
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            
            return completedTimes.contains { completedDate in
                let completedComponents = calendar.dateComponents([.hour, .minute], from: completedDate)
                return completedComponents.hour == timeComponents.hour &&
                        completedComponents.minute == timeComponents.minute &&
                        calendar.isDate(completedDate, inSameDayAs: forDate) // Use forDate here
            }
        }
    
    // Check karta hai ke aaj ke din ke liye ek specific time slot overdue hai ya nahi.
    func isTimeSlotOverdue(time: Date) -> Bool {
           // Sirf active, non-expired, aur non-future reminders ke liye check karein.
           guard active && !hasPeriodEnded && !isFutureReminder else { return false }
           
           let calendar = Calendar.current
           let now = Date()
           
           // Aaj ke din ke liye specific time slot ki date banayein.
           let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
           guard let scheduledTimeToday = calendar.date(bySettingHour: timeComponents.hour!, minute: timeComponents.minute!, second: 0, of: now) else { return false }
           
           // Time slot overdue hai agar woh guzar chuka hai aur complete nahi hua hai.
           return scheduledTimeToday < now && !isTimeSlotCompleted(time: time, forDate: now) // Corrected: Pass 'now' for forDate
       }

    // Helper property: Agar koi bhi time slot overdue hai toh poora reminder overdue hai.
    var isOverdue: Bool {
        guard active && !hasPeriodEnded && !isFutureReminder else { return false }
        return times.contains(where: { isTimeSlotOverdue(time: $0) })
    }
    
    // Helper property: Agar saare time slots aaj ke din ke liye complete ho gaye hain toh poora reminder complete hai.

    var isCompletedForAllTimesToday: Bool {
        guard active && !times.isEmpty else { return false }
        return times.allSatisfy { time in
            isTimeSlotCompleted(time: time, forDate: Date()) // Corrected: Pass Date()
        }
    }

    // Check karta hai ke reminder ki period khatam ho chuki hai ya nahi.
    var hasPeriodEnded: Bool {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let normalizedEndDate = calendar.startOfDay(for: endDate)
        return normalizedEndDate < startOfToday
        print("d")
    }

    // Check karta hai ke reminder future mein shuru hoga ya nahi.
    var isFutureReminder: Bool {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let normalizedStartDate = calendar.startOfDay(for: startDate)
        return normalizedStartDate > startOfToday
    }

    // Initializer for the Reminder class.
    init(id: UUID = UUID(), title: String, type: ReminderType, times: [Date], startDate: Date, endDate: Date, active: Bool, nextDue: Date, completedTimes: [Date] = [], lastModifiedDate: Date = Date(), lastResetDate: Date? = nil, userSettings: UserSettings? = nil) {
        self.id = id
        self.title = title
        self.type = type
        self.times = times.sorted { $0 < $1 } // Times ko hamesha sorted rakhein
        self.startDate = startDate
        self.endDate = endDate
        self.active = active
        self.nextDue = nextDue
        self.completedTimes = completedTimes
        self.lastModifiedDate = lastModifiedDate
        self.lastResetDate = lastResetDate
        self.userSettings = userSettings
    }
}




// MARK: - ReminderDetailRow View
struct ReminderDetailRow: View {
    var reminder: Reminder
    var onToggleActive: (UUID, Reminder.ReminderType) -> Void
    var onDelete: (UUID, Reminder.ReminderType) -> Void
    var onEdit: (Reminder) -> Void
    var onToggleTimeSlotCompletion: (UUID, Date, Reminder.ReminderType) -> Void

    @State private var internalIsActive: Bool

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    init(reminder: Reminder, onToggleActive: @escaping (UUID, Reminder.ReminderType) -> Void, onDelete: @escaping (UUID, Reminder.ReminderType) -> Void, onEdit: @escaping (Reminder) -> Void, onToggleTimeSlotCompletion: @escaping (UUID, Date, Reminder.ReminderType) -> Void) {
        self.reminder = reminder
        self.onToggleActive = onToggleActive
        self.onDelete = onDelete
        self.onEdit = onEdit
        self.onToggleTimeSlotCompletion = onToggleTimeSlotCompletion
        _internalIsActive = State(initialValue: reminder.active)
    }

    private func isTimeSlotButtonDisabled(time: Date) -> Bool {
        return !reminder.active || reminder.hasPeriodEnded || reminder.isFutureReminder || (!reminder.isTimeSlotOverdue(time: time) && !reminder.isTimeSlotCompleted(time: time, forDate: Date()))
    }

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundTint)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)

            Rectangle()
                .fill(borderTint)
                .frame(width: 4)
                .clipShape(RoundedCorner(radius: 12, corners: [.topLeft, .bottomLeft]))

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Image(systemName: reminder.iconName)
                        .font(.body)
                        .foregroundColor(iconColor)
                        .frame(width: 36, height: 36)
                        .background(iconBackgroundColor)
                        .clipShape(Circle())

                    VStack(alignment: .leading) {
                        Text(reminder.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(reminder.type.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(reminder.times.sorted(), id: \.self) { time in
                                HStack {
                                    Text(Self.timeFormatter.string(from: time))
                                        .font(.subheadline)
                                        .foregroundColor(textColorForTimeSlot(time))
                                    
                                    Spacer()
                                    
                                    if reminder.isTimeSlotOverdue(time: time) {
                                        Text("Overdue")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.red.opacity(0.15))
                                            .foregroundColor(.red.opacity(0.9))
                                            .cornerRadius(4)
                                    } else if reminder.isTimeSlotCompleted(time: time, forDate: Date()) {
                                        Text("Done")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.15))
                                            .foregroundColor(.green.opacity(0.9))
                                            .cornerRadius(4)
                                    } else {
                                        Text("Pending")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.15))
                                            .foregroundColor(.orange.opacity(0.9))
                                            .cornerRadius(4)
                                    }
                                    
                                    Button(action: {
                                        onToggleTimeSlotCompletion(reminder.id, time, reminder.type)
                                    }) {
                                        Image(systemName: reminder.isTimeSlotCompleted(time: time, forDate: Date()) ? "arrow.counterclockwise.circle.fill" : "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(reminder.isTimeSlotCompleted(time: time, forDate: Date()) ? .gray : .green)
                                    }
                                    .accessibilityIdentifier("takenReminder")
                                    .buttonStyle(.plain)
                                    .disabled(isTimeSlotButtonDisabled(time: time))
                                }
                            }
                        }
                    }
                    Spacer()
                    
                    Toggle(isOn: $internalIsActive) {
                        EmptyView()
                    }
                    .labelsHidden()
                    .onChange(of: internalIsActive) { _, newValue in
                        reminder.active = newValue
                        onToggleActive(reminder.id, reminder.type)
                    }
                }

                Divider()

                HStack {
                    VStack(alignment: .leading) {
                        Text("Period:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Self.dateFormatter.string(from: reminder.startDate)) - \(Self.dateFormatter.string(from: reminder.endDate))")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    
                    if reminder.type == .checkup {
                        Button(action: {
                            onEdit(reminder)
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button(action: {
                        onDelete(reminder.id, reminder.type)
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .padding(.leading, 4)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var backgroundTint: Color {
        reminder.active ? Color.white : Color.gray.opacity(0.1)
    }

    private var borderTint: Color {
        if !reminder.active {
            return .gray.opacity(0.5)
        } else if reminder.hasPeriodEnded {
            return .gray
        } else if reminder.isOverdue {
            return .red
        } else if reminder.isCompletedForAllTimesToday {
            return .green
        } else if reminder.isFutureReminder {
            return .blue.opacity(0.6)
        } else {
            return .blue
        }
    }

    private var iconColor: Color {
        if !reminder.active || reminder.hasPeriodEnded {
            return .gray
        } else if reminder.isOverdue {
            return .red
        } else if reminder.isCompletedForAllTimesToday {
            return .green
        } else {
            return .blue
        }
    }

    private var iconBackgroundColor: Color {
        if !reminder.active || reminder.hasPeriodEnded {
            return .gray.opacity(0.1)
        } else if reminder.isOverdue {
            return .red.opacity(0.1)
        } else if reminder.isCompletedForAllTimesToday {
            return .green.opacity(0.1)
        } else {
            return .blue.opacity(0.1)
        }
    }

    private func textColorForTimeSlot(_ time: Date) -> Color {
        if !reminder.active || reminder.hasPeriodEnded || reminder.isFutureReminder {
            return .gray
        } else if reminder.isTimeSlotCompleted(time: time, forDate: Date()) {
            return .green
        } else if reminder.isTimeSlotOverdue(time: time) {
            return .red
        } else {
            return .primary
        }
    }
}

// MARK: - ReminderSummaryCard
struct ReminderSummaryCard: View {
    let title: String
    let subtitle: String
    let iconName: String
    let tintColor: Color
    let gradientStart: Color
    let gradientEnd: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [gradientStart, gradientEnd]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(tintColor.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
            .frame(maxWidth: .infinity)
            .aspectRatio(4/1, contentMode: .fit)
            .overlay(
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(tintColor.opacity(0.8))
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(tintColor.opacity(0.6))
                    }
                    Spacer()
                    Image(systemName: iconName)
                        .font(.title2)
                        .padding(8)
                        .background(tintColor.opacity(0.2))
                        .clipShape(Circle())
                        .foregroundColor(tintColor.opacity(0.7))
                }
                .padding(10)
            )
    }
}



// MARK: - AddNewReminderSheetView (New View for the Add/Edit Reminder Dialog/Sheet)
// Naye reminders add karne ya existing reminders ko edit karne ke liye sheet.


// MARK: - AddNewReminderSheetView (New View for the Add/Edit Reminder Dialog/Sheet)
// Naye reminders add karne ya existing reminders ko edit karne ke liye sheet.
struct AddNewReminderSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authManager: AuthManager
    @Binding var reminderToEdit: Reminder?
    var onSave: (Reminder) -> Void

    @State private var title: String = ""
    @State private var var_type: Reminder.ReminderType = .checkup
    @State private var selectedTimes: [Date] = [Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!]
    @State private var startDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var endDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
    @State private var newTime: Date = Date()
    @State private var showAlert = false
    @State private var alertMessage = ""

    @Query private var userSettingsQuery: [UserSettings]

    private var currentUserSettings: UserSettings {
        if let settings = userSettingsQuery.first(where: { $0.userID == authManager.currentUserUID }) {
            return settings
        } else {
            let newSettings = UserSettings(userID: authManager.currentUserUID ?? "unknown", userName: authManager.currentUserDisplayName)
            modelContext.insert(newSettings)
            return newSettings
        }
    }

    var isEditMode: Bool { reminderToEdit != nil }

    var body: some View {
        NavigationView {
            Form {
                Section("Reminder Details") {
                    TextField("Reminder Title (e.g., Blood Pressure Check)", text: $title)
                        .accessibilityIdentifier("reminderTitle")
                    Picker("Reminder Type", selection: $var_type) {
                        Text(Reminder.ReminderType.checkup.displayName).tag(Reminder.ReminderType.checkup)
                    }
                    .disabled(true)
                }

                Section("Schedule Times (Daily)") {
                    if selectedTimes.isEmpty {
                        Text("No timings added yet.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(selectedTimes.sorted(), id: \.self) { time in
                            HStack {
                                Text(time, formatter: ReminderDetailRow.timeFormatter)
                                Spacer()
                                Button(role: .destructive) {
                                    selectedTimes.removeAll(where: { $0 == time })
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    
                    HStack {
                        DatePicker("Add New Time", selection: $newTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                        Button("Add") {
                            if !selectedTimes.contains(where: { Calendar.current.isDate($0, equalTo: newTime, toGranularity: .minute) }) {
                                selectedTimes.append(newTime)
                                selectedTimes.sort()
                            } else {
                                alertMessage = "This time has already been added!"
                                showAlert = true
                            }
                            newTime = Date()
                        }
                        .disabled(selectedTimes.count >= 5)
                    }
                }

                Section("Reminder Period") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
            }
            .navigationTitle(isEditMode ? "Edit Reminder" : "Add New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveReminder()
                    }
                    .accessibilityIdentifier("saveReminder")
                    .disabled(title.isEmpty || selectedTimes.isEmpty)
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                if let reminder = reminderToEdit {
                    if reminder.type == .checkup {
                        title = reminder.title
                        var_type = reminder.type
                        selectedTimes = reminder.times
                        startDate = reminder.startDate
                        endDate = reminder.endDate
                    } else {
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveReminder() {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Reminder title cannot be empty."
            showAlert = true
            return
        }
        guard !selectedTimes.isEmpty else {
            alertMessage = "Please add at least one scheduled time."
            showAlert = true
            return
        }
        guard startDate <= endDate else {
            alertMessage = "Start date cannot be after end date."
            showAlert = true
            return
        }

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        let nextDueTime = selectedTimes.first ?? Date()
        let selectedTimeComponents = calendar.dateComponents([.hour, .minute], from: nextDueTime)
        
        components.hour = selectedTimeComponents.hour
        components.minute = selectedTimeComponents.minute
        
        let calculatedNextDue = calendar.date(from: components) ?? Date()
        
        if let existingReminder = reminderToEdit {
            existingReminder.title = title
            existingReminder.type = var_type
            existingReminder.times = selectedTimes
            existingReminder.startDate = Calendar.current.startOfDay(for: startDate)
            existingReminder.endDate = Calendar.current.startOfDay(for: endDate)
            existingReminder.nextDue = calculatedNextDue
            existingReminder.lastModifiedDate = Date()
            onSave(existingReminder)
        } else {
            let newReminder = Reminder(
                title: title,
                type: var_type,
                times: selectedTimes,
                startDate: Calendar.current.startOfDay(for: startDate),
                endDate: Calendar.current.startOfDay(for: endDate),
                active: true,
                nextDue: calculatedNextDue,
                completedTimes: [],
                lastModifiedDate: Date(),
                lastResetDate: nil,
                userSettings: currentUserSettings
            )
            modelContext.insert(newReminder)
            onSave(newReminder)
        }
        dismiss()
    }
}

// MARK: - NoRemindersPlaceholderView
struct NoRemindersPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash.fill")
                .font(.largeTitle)
                .padding(16)
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 4) {
                Text("No reminders set up yet")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("Add your first reminder to get started")
                    .font(.subheadline)
                    .foregroundColor(.gray.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

// MARK: - RemindersMainContentView
struct RemindersMainContentView: View {
    @EnvironmentObject var authManager: AuthManager
    var activeMedicines: [Medicine]
    var activeReminders: [Reminder]
    var activeRemindersCount: Int
    var overdueRemindersCount: Int
    var onTrackPercentage: Int
    var onToggleActive: (UUID, Reminder.ReminderType) -> Void
    var onDelete: (UUID, Reminder.ReminderType) -> Void
    var onEdit: (Reminder) -> Void
    var onToggleTimeSlotCompletion: (UUID, Date, Reminder.ReminderType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            RemindersIntroHeader()
            
            SMAMedicineTrackerStats(medicinesCount: activeMedicines.count)
            
            RemindersSummarySection(
                activeRemindersCount: activeRemindersCount,
                overdueRemindersCount: overdueRemindersCount,
                onTrackPercentage: onTrackPercentage
            )

            SectionHeaderView(title: "All Reminders")

            AllRemindersList(
                displayedReminders: activeReminders,
                onToggleActive: onToggleActive,
                onDelete: onDelete,
                onEdit: onEdit,
                onToggleTimeSlotCompletion: onToggleTimeSlotCompletion
            )
            .padding(.bottom, 20)
        }
    }
}

// MARK: - RemindersScreen
struct RemindersScreen: View {
    @Query(filter: #Predicate<Medicine> { $0.isActive == true && $0.userSettings?.userID != nil })
    private var activeMedicines: [Medicine]
    
    @Query(sort: \Reminder.nextDue)
    private var reminders: [Reminder]
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authManager: AuthManager
    @State private var showingAddReminderSheet = false
    @State private var reminderToEdit: Reminder?
    @State private var showNoContactsAlert = false
    @State private var queryRefreshTrigger = false
    @StateObject private var missedReminderService: MissedReminderService

    init() {
        _missedReminderService = StateObject(wrappedValue: MissedReminderService(authManager: AuthManager()))
    }

    private var activeRemindersCount: Int {
        reminders.filter {
            $0.userSettings?.userID == authManager.currentUserUID &&
            $0.active && !$0.hasPeriodEnded && !$0.isFutureReminder
        }.count
    }

    private var overdueRemindersCount: Int {
        reminders.filter {
            $0.userSettings?.userID == authManager.currentUserUID &&
            $0.active && $0.isOverdue && !$0.isCompletedForAllTimesToday
        }.count
    }

    private var onTrackPercentage: Int {
        let userFilteredReminders = reminders.filter { $0.userSettings?.userID == authManager.currentUserUID }
        guard userFilteredReminders.count > 0 else { return 100 }
        let onTrackUserReminders = userFilteredReminders.filter {
            $0.active && !$0.hasPeriodEnded && !$0.isFutureReminder && !$0.isOverdue
        }.count
        return Int(round(Double(onTrackUserReminders) / Double(userFilteredReminders.count) * 100))
    }

    private var activeReminders: [Reminder] {
        print("🔄 activeReminders computed property re-evaluating... queryRefreshTrigger: \(queryRefreshTrigger)")
        let userFilteredReminders = reminders.filter { reminder in
            reminder.userSettings?.userID == authManager.currentUserUID
        }
        let filtered = userFilteredReminders.filter { reminder in
            !reminder.hasPeriodEnded && !reminder.isFutureReminder
        }
        let sorted = sortReminders(filteredReminders: filtered)
        return sorted
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    RemindersMainContentView(
                        activeMedicines: activeMedicines,
                        activeReminders: activeReminders,
                        activeRemindersCount: activeRemindersCount,
                        overdueRemindersCount: overdueRemindersCount,
                        onTrackPercentage: onTrackPercentage,
                        onToggleActive: handleToggleActive,
                        onDelete: handleDelete,
                        onEdit: handleEdit,
                        onToggleTimeSlotCompletion: handleToggleTimeSlotCompletion
                    )
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 60)
                }
            }
            .navigationTitle("Smart Reminders")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        reminderToEdit = nil
                        showingAddReminderSheet = true
                    }) {
                        Label("Add Reminder", systemImage: "plus")
                    }
                    .accessibilityIdentifier("plusReminder")
                }
            }
            .sheet(isPresented: $showingAddReminderSheet, onDismiss: {
                removeExpiredReminders()
                resetCompletedRemindersForNewDay()
            }) {
                AddNewReminderSheetView(reminderToEdit: $reminderToEdit) { savedReminder in
                    print("Reminder saved/updated: \(savedReminder.title)")
                    if savedReminder.active {
                        scheduleNotifications(for: savedReminder)
                    } else {
                        cancelNotifications(for: savedReminder)
                    }
                }
            }
            .alert("Action Required", isPresented: $showNoContactsAlert) {
                Button("OK") {
                    // Navigate to settings screen or prompt user to add contacts/notifications
                }
            } message: {
                Text("Please add emergency contacts in your profile or enable notifications to receive missed reminder reports.")
            }
            .onAppear {
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    if settings.authorizationStatus == .denied {
                        print("🚫 Notification permission denied.")
                        DispatchQueue.main.async {
                            showNoContactsAlert = true
                        }
                    } else {
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                            if success {
                                print("🔔 Notification authorization granted.")
                                DispatchQueue.main.async {
                                    let notificationDelegate = NotificationDelegate1(modelContext: modelContext)
                                    UNUserNotificationCenter.current().delegate = notificationDelegate
                                    missedReminderService.setModelContext(modelContext)
                                    missedReminderService.scheduleDailyMissedReminderCheck()
                                }
                            } else if let error = error {
                                print("🔔 Notification authorization error: \(error.localizedDescription)")
                            }
                        }
                    }
                }
                removeExpiredReminders()
                resetCompletedRemindersForNewDay()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NoEmergencyContacts"))) { _ in
                showNoContactsAlert = true
            }
            .onReceive(authManager.$currentUserUID) { _ in
                queryRefreshTrigger.toggle()
            }
            .environmentObject(missedReminderService)
        }
    }

    private func handleToggleActive(id: UUID, type: Reminder.ReminderType) {
        if type == .checkup {
            if let reminderToUpdate = reminders.first(where: { $0.id == id && $0.userSettings?.userID == authManager.currentUserUID }) {
                print("Toggled checkup reminder \(reminderToUpdate.title) to active: \(reminderToUpdate.active)")
                if reminderToUpdate.active {
                    scheduleNotifications(for: reminderToUpdate)
                } else {
                    cancelNotifications(for: reminderToUpdate)
                }
            }
        }
    }

    private func handleDelete(id: UUID, type: Reminder.ReminderType) {
        withAnimation {
            if type == .checkup {
                if let reminderToDelete = reminders.first(where: { $0.id == id && $0.userSettings?.userID == authManager.currentUserUID }) {
                    cancelNotifications(for: reminderToDelete)
                    modelContext.delete(reminderToDelete)
                    print("Deleted checkup reminder: \(reminderToDelete.title)")
                }
            }
        }
    }

    private func handleEdit(reminderToEdit: Reminder) {
        if reminderToEdit.type == .checkup {
            self.reminderToEdit = reminderToEdit
            showingAddReminderSheet = true
        } else {
            print("Editing not allowed for medicine reminders directly from here.")
        }
    }

    private func handleToggleTimeSlotCompletion(id: UUID, timeSlot: Date, type: Reminder.ReminderType) {
        let calendar = Calendar.current
        if type == .checkup {
            if let reminderToUpdate = reminders.first(where: { $0.id == id && $0.userSettings?.userID == authManager.currentUserUID }) {
                if reminderToUpdate.isTimeSlotCompleted(time: timeSlot, forDate: Date()) {
                    reminderToUpdate.completedTimes.removeAll { completedDate in
                        calendar.isDate(completedDate, equalTo: timeSlot, toGranularity: .minute) &&
                            calendar.isDate(completedDate, inSameDayAs: Date())
                    }
                    print("Reopened checkup time slot \(ReminderDetailRow.timeFormatter.string(from: timeSlot)) for reminder: \(reminderToUpdate.title)")
                } else {
                    reminderToUpdate.completedTimes.append(calendar.date(bySettingHour: calendar.component(.hour, from: timeSlot), minute: calendar.component(.minute, from: timeSlot), second: 0, of: Date())!)
                    print("Completed checkup time slot \(ReminderDetailRow.timeFormatter.string(from: timeSlot)) for reminder: \(reminderToUpdate.title)")
                }
                reminderToUpdate.lastModifiedDate = Date()
            }
        }
    }

    private func removeExpiredReminders() {
        let initialCount = reminders.count
        reminders.filter { $0.hasPeriodEnded && $0.userSettings?.userID == authManager.currentUserUID }.forEach { expiredReminder in
            cancelNotifications(for: expiredReminder)
            modelContext.delete(expiredReminder)
            print("Removed expired checkup reminder: \(expiredReminder.title)")
        }
        if reminders.count != initialCount {
            print("Expired checkup reminders cleaned up. Count changed from \(initialCount) to \(reminders.count)")
        }
    }

    private func resetCompletedRemindersForNewDay() {
        let calendar = Calendar.current
        var changed = false
        for reminder in reminders where reminder.active && reminder.userSettings?.userID == authManager.currentUserUID {
            if let lastReset = reminder.lastResetDate, calendar.isDateInToday(lastReset) {
                continue
            }
            if !reminder.completedTimes.isEmpty {
                reminder.completedTimes = []
                reminder.lastModifiedDate = Date()
                changed = true
                print("Reset completed times for checkup reminder: \(reminder.title) for a new day.")
            }
            reminder.lastResetDate = Date()
        }
        if changed {
            print("Checkup reminders reset for new day.")
        }
    }

    private func scheduleNotifications(for reminder: Reminder) {
        print("🔔 scheduleNotifications called for reminder: \(reminder.title)")
        guard reminder.active && reminder.type == .checkup && reminder.userSettings?.userID == authManager.currentUserUID else {
            print("🔔 Notification not scheduled for \(reminder.title): Not active, not a checkup reminder, or not for current user.")
            return
        }

        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        var identifiersToCancel: [String] = []
        for time in reminder.times {
            identifiersToCancel.append("\(reminder.id.uuidString)-\(ReminderDetailRow.timeFormatter.string(from: time))")
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
        print("🔔 Cleared existing notifications for \(reminder.title) with identifiers: \(identifiersToCancel)")

        for time in reminder.times {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = "It's time for your \(reminder.type.displayName)!"
            content.sound = .default
            var dateComponents = calendar.dateComponents([.hour, .minute], from: time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let requestIdentifier = "\(reminder.id.uuidString)-\(ReminderDetailRow.timeFormatter.string(from: time))"
            let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
            center.add(request) { error in
                if let error = error {
                    print("🔔 Error scheduling notification for \(reminder.title) at \(ReminderDetailRow.timeFormatter.string(from: time)): \(error.localizedDescription)")
                } else {
                    print("🔔 Successfully scheduled notification for \(reminder.title) at \(ReminderDetailRow.timeFormatter.string(from: time)) (ID: \(requestIdentifier))")
                }
            }
        }
    }

    private func cancelNotifications(for reminder: Reminder) {
        let center = UNUserNotificationCenter.current()
        var identifiersToCancel: [String] = []
        for time in reminder.times {
            let requestIdentifier = "\(reminder.id.uuidString)-\(ReminderDetailRow.timeFormatter.string(from: time))"
            identifiersToCancel.append(requestIdentifier)
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
        print("🔔 Cancelled notifications for reminder: \(reminder.title) (IDs: \(identifiersToCancel.joined(separator: ", ")))")
    }

    private func sortReminders(filteredReminders: [Reminder]) -> [Reminder] {
        return filteredReminders.sorted { (rem1, rem2) in
            if rem1.isOverdue && !rem2.isOverdue {
                return true
            }
            if !rem1.isOverdue && rem2.isOverdue {
                return false
            }
            if rem1.isFutureReminder && !rem2.isFutureReminder {
                return false
            }
            if !rem1.isFutureReminder && rem2.isFutureReminder {
                return true
            }
            if rem1.nextDue != rem2.nextDue {
                return rem1.nextDue < rem2.nextDue
            }
            if !rem1.isCompletedForAllTimesToday && rem2.isCompletedForAllTimesToday {
                return true
            }
            if rem1.isCompletedForAllTimesToday && !rem2.isCompletedForAllTimesToday {
                return false
            }
            return rem1.title < rem2.title
        }
    }
}

// MARK: - Extracted Sub-views for RemindersScreen

// MARK: - Extracted Sub-views
struct RemindersIntroHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Manage your health checkup and medicine reminders")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.7))
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
}

struct RemindersSummarySection: View {
    let activeRemindersCount: Int
    let overdueRemindersCount: Int
    let onTrackPercentage: Int

    var body: some View {
        VStack(spacing: 12) {
            ReminderSummaryCard(
                title: "\(activeRemindersCount)", subtitle: "Active Reminders",
                iconName: "bell.fill", tintColor: .blue,
                gradientStart: .blue.opacity(0.05), gradientEnd: .blue.opacity(0.1)
            )
            ReminderSummaryCard(
                title: "\(overdueRemindersCount)", subtitle: "Overdue",
                iconName: "exclamationmark.triangle.fill", tintColor: .red,
                gradientStart: .red.opacity(0.05), gradientEnd: .red.opacity(0.1)
            )
            ReminderSummaryCard(
                title: "\(onTrackPercentage)%", subtitle: "On Track",
                iconName: "checkmark.circle.fill", tintColor: .green,
                gradientStart: .green.opacity(0.05), gradientEnd: .green.opacity(0.1)
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
}

struct SectionHeaderView: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.title2)
            .fontWeight(.semibold)
            .padding(.top, 10)
            .padding(.horizontal)
    }
}

struct AllRemindersList: View {
    let displayedReminders: [Reminder]
    @EnvironmentObject var authManager: AuthManager
    var onToggleActive: (UUID, Reminder.ReminderType) -> Void
    var onDelete: (UUID, Reminder.ReminderType) -> Void
    var onEdit: (Reminder) -> Void
    var onToggleTimeSlotCompletion: (UUID, Date, Reminder.ReminderType) -> Void

    var body: some View {
        LazyVStack(spacing: 8) {
            if displayedReminders.isEmpty {
                NoRemindersPlaceholderView()
                    .padding(.horizontal)
            } else {
                ForEach(displayedReminders) { reminder in
                    ReminderDetailRow(
                        reminder: reminder,
                        onToggleActive: onToggleActive,
                        onDelete: onDelete,
                        onEdit: onEdit,
                        onToggleTimeSlotCompletion: onToggleTimeSlotCompletion
                    )
                }
            }
        }
    }
}


extension Reminder {
    /// Resets `completedTimes` if the last reset was not today.
    /// This should be called typically once per day (e.g., on app launch or a background task).
    func resetCompletedTimesIfNeeded() {
        let calendar = Calendar.current
        let today = Date()

        if let lastReset = lastResetDate {
            if !calendar.isDate(lastReset, inSameDayAs: today) {
                // It's a new day, reset completed times
                completedTimes = []
                lastResetDate = today
                // Important: Ensure you save the model context after this change
            }
        } else {
            // First time running or no reset date set, initialize it
            completedTimes = []
            lastResetDate = today
            // Important: Ensure you save the model context after this change
        }
    }

    /// Calculates the adherence for this reminder for a specific day.
    /// - Parameter day: The date for which to calculate adherence.
    /// - Returns: A Double representing the adherence percentage (0.0 to 1.0), or nil if not applicable.
    func calculateDailyAdherence(for day: Date) -> Double? {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: day)
            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: day) ?? day

            // If reminder is not active, or its period doesn't cover this day, no adherence
            guard active && !hasPeriodEnded && !isFutureReminder else { return nil }
            
            let normalizedStartDate = calendar.startOfDay(for: startDate)
            let normalizedEndDate = calendar.startOfDay(for: endDate)

            if !(startOfDay >= normalizedStartDate && startOfDay <= normalizedEndDate) {
                return nil // Reminder is not active for this specific day
            }

            guard !times.isEmpty else { return 0.0 } // If no times, 100% adherence (or define as N/A)

            var completedSlotsOnDay = 0
            var totalDueSlotsOnDay = 0

            for timeSlot in times {
                let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: timeSlot)
                guard let scheduledTimeForDay = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                                              minute: timeComponents.minute ?? 0,
                                                              second: timeComponents.second ?? 0,
                                                              of: day) else { continue }
                
                // Only count slots that were actually due by the reference point (end of day or now)
                let referenceDate = calendar.isDateInToday(day) ? Date() : endOfDay

                if scheduledTimeForDay <= referenceDate {
                    totalDueSlotsOnDay += 1
                    if isTimeSlotCompleted(time: scheduledTimeForDay, forDate: day) { // Pass 'day' here
                        completedSlotsOnDay += 1
                    }
                }
            }
            
            guard totalDueSlotsOnDay > 0 else { return 0.0 } // No slots due, technically 100% adherence (or N/A)
            return Double(completedSlotsOnDay) / Double(totalDueSlotsOnDay)
        }

    /// Calculates the adherence for this reminder over a given date range.
    /// - Parameters:
    ///   - fromDate: The beginning of the date range (inclusive).
    ///   - toDate: The end of the date range (inclusive).
    /// - Returns: A Double representing the average adherence percentage, or nil if no days were applicable.
    func calculateAdherence(from fromDate: Date, to toDate: Date) -> Double? {
        let calendar = Calendar.current
        var totalAdherence: Double = 0.0
        var applicableDays = 0

        var currentDate = calendar.startOfDay(for: fromDate)
        let endRangeDate = calendar.startOfDay(for: toDate)

        while currentDate <= endRangeDate {
            if let dailyAdherence = calculateDailyAdherence(for: currentDate) {
                totalAdherence += dailyAdherence
                applicableDays += 1
            }
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDay
        }

        guard applicableDays > 0 else { return nil }
        return totalAdherence / Double(applicableDays)
    }
}

// NOTE: Your `isTimeSlotCompleted` function in the `Reminder` model
// currently checks `inSameDayAs: Date()`. For `calculateDailyAdherence(for day: Date)`,
// you'll need to modify `isTimeSlotCompleted` to accept the `day` parameter
// so it can check against that specific day instead of always `Date()`.
//
// Updated `isTimeSlotCompleted` (within the Reminder class):
/*
func isTimeSlotCompleted(time: Date) -> Bool { // Original function, can be overloaded
    let calendar = Calendar.current
    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

    return completedTimes.contains { completedDate in
        let completedComponents = calendar.dateComponents([.hour, .minute], from: completedDate)
        return completedComponents.hour == timeComponents.hour &&
                completedComponents.minute == timeComponents.minute &&
                calendar.isDate(completedDate, inSameDayAs: Date()) // Sirf aaj ke din ke liye check karein
    }
}

// NEW OVERLOAD to handle checking for a specific day:
func isTimeSlotCompleted(time: Date, for specificDay: Date) -> Bool {
    let calendar = Calendar.current
    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

    return completedTimes.contains { completedDate in
        let completedComponents = calendar.dateComponents([.hour, .minute], from: completedDate)
        return completedComponents.hour == timeComponents.hour &&
                completedComponents.minute == timeComponents.minute &&
                calendar.isDate(completedDate, inSameDayAs: specificDay) // Check for specific day
    }
}
*/
// And then in `calculateDailyAdherence`, call `isTimeSlotCompleted(time: scheduledTimeForDay, for: day)`.
