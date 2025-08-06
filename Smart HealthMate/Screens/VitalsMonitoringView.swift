import SwiftUI
import SwiftData
import FirebaseAuth
import FirebaseFunctions
import UserNotifications
import UIKit

// MARK: - VitalAlertService

class VitalAlertService: ObservableObject {
    private let authManager: AuthManager
    private let notificationCenter = UNUserNotificationCenter.current()
    private var modelContext: ModelContext?

    init(authManager: AuthManager) {
        self.authManager = authManager
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

//    func checkAndNotifyOutOfRange(vital: VitalReading) async -> Bool {
//        guard let userID = authManager.currentUserUID,
//              let modelContext = modelContext else {
//            print("🚫 VitalAlertService: No authenticated user or modelContext.")
//            return false
//        }
//
//        do {
//            let userSettingsDescriptor = FetchDescriptor<UserSettings>(predicate: #Predicate { settings in
//                settings.userID == userID
//            })
//            guard let userSettings = try modelContext.fetch(userSettingsDescriptor).first else {
//                print("🚫 VitalAlertService: No UserSettings found for user \(userID).")
//                return false
//            }
//            let alertSettings = userSettings.alertSettings
//            let emergencyContacts = alertSettings.emergencyContacts
//            guard !emergencyContacts.isEmpty else {
//                print("🚫 VitalAlertService: No emergency contacts found for user \(userID).")
//                NotificationCenter.default.post(name: NSNotification.Name("NoEmergencyContacts"), object: nil)
//                return false
//            }
//
//            var isOutOfRange = false
//            var recordedValue = ""
//            let dateFormatter = DateFormatter()
//            dateFormatter.dateStyle = .medium
//            dateFormatter.timeStyle = .short
//            dateFormatter.timeZone = TimeZone(identifier: "Asia/Karachi")
//
//            print("🔍 Checking vital: Type=\(vital.type.displayName), Systolic=\(vital.systolic ?? 0), Diastolic=\(vital.diastolic ?? 0), Sugar=\(vital.sugarLevel ?? 0)")
//            print("🔍 Thresholds: BP=\(alertSettings.bpThreshold.minSystolic)-\(alertSettings.bpThreshold.maxSystolic)/\(alertSettings.bpThreshold.minDiastolic)-\(alertSettings.bpThreshold.maxDiastolic), Sugar=\(alertSettings.afterMealSugarThreshold.min)-\(alertSettings.afterMealSugarThreshold.max)")
//
//            switch vital.type {
//            case .bp:
//                if let systolic = vital.systolic, let diastolic = vital.diastolic {
//                    let bpThreshold = alertSettings.bpThreshold
//                    if systolic < bpThreshold.minSystolic || systolic > bpThreshold.maxSystolic ||
//                       diastolic < bpThreshold.minDiastolic || diastolic > bpThreshold.maxDiastolic {
//                        isOutOfRange = true
//                        recordedValue = "\(systolic)/\(diastolic) mmHg"
//                        print("🔍 BP out of range: \(recordedValue)")
//                        
//                    } else {
//                        print("🔍 BP within range: \(recordedValue)")
//                    }
//                } else {
//                    print("🔍 BP invalid: Missing systolic or diastolic values")
//                }
//            case .sugar:
//               if let sugarLevel = vital.sugarLevel, let sugarReadingType = vital.sugarReadingType {
//                    let sugarThreshold: SMASugarThreshold // Changed from tuple to SMASugarThreshold
//                    switch sugarReadingType {
//                    case .fasting:
//                        sugarThreshold = alertSettings.fastingSugarThreshold
//                        print("🔍 Comparing sugar with Fasting threshold: \(sugarThreshold.min)-\(sugarThreshold.max)")
//                    case .afterMeal:
//                        sugarThreshold = alertSettings.afterMealSugarThreshold
//                        print("🔍 Comparing sugar with After Meal threshold: \(sugarThreshold.min)-\(sugarThreshold.max)")
//                    }
//                    if sugarLevel < sugarThreshold.min || sugarLevel > sugarThreshold.max {
//                        isOutOfRange = true
//                        recordedValue = "\(sugarLevel) mg/dL (\(sugarReadingType.rawValue))"
//                        print("🔍 Sugar out of range: \(recordedValue)")
//                    } else {
//                        print("🔍 Sugar within range: \(recordedValue)")
//                    }
//                } else {
//                    print("🚫 Sugar invalid: Missing sugar level or reading type")
//                }
//            }
//
//            if isOutOfRange {
//                print("truee : \(isOutOfRange)")
//                let emailBody = """
//                Dear Attendant(s),
//
//                \(userSettings.userName ?? "User")'s \(vital.type.displayName) level is out of range.
//                Type: \(vital.type.displayName)
//                Recorded value: \(recordedValue)
//                Time: \(dateFormatter.string(from: vital.time))
//                Date: \(dateFormatter.string(from: vital.date))
//
//                Please ensure the user receives appropriate attention.
//
//                Best regards,
//                Smart HealthMate Team
//                """
//
//                let functions = Functions.functions() // Update with region if needed, e.g., Functions.functions(region: "asia-south1")
//                let data: [String: Any] = [
//                    "to": emergencyContacts.joined(separator: ","),
//                    "subject": "Smart HealthMate: Out-of-Range Vital Reading for \(userSettings.userName ?? "User")",
//                    "body": emailBody
//                ]
//
//                do {
//                    let result = try await functions.httpsCallable("sendEmail").call(data)
//                    print("📧 Successfully sent out-of-range email to \(emergencyContacts.joined(separator: ", ")): \(result.data)")
//                } catch {
//                    print("📧 Error calling sendEmail Cloud Function: \(error.localizedDescription)")
////                    return false
//                }
//
//                let content = UNMutableNotificationContent()
//                content.title = "Vital Reading Alert"
//                content.body = "\(vital.type.displayName) level is out of range. Email has been sent to your attendants."
//                content.sound = .default
//                print("-----")
//                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
//                let request = UNNotificationRequest(identifier: "VitalOutOfRange-\(vital.id.uuidString)", content: content, trigger: trigger)
//                do {
//                    try await notificationCenter.add(request)
//                    print("🔔 Scheduled out-of-range notification for \(vital.type.displayName) (ID: VitalOutOfRange-\(vital.id.uuidString))")
//                } catch {
//                    print("🔔 Error scheduling out-of-range notification: \(error.localizedDescription)")
////                    return false
//                }
//            } else {
//                print("🔍 No action taken: Vital reading within range.")
//            }
//
//            return isOutOfRange
//        } catch {
//            print("🚫 Error checking out-of-range vital: \(error.localizedDescription)")
//            return false
//        }
//    }
    
    func checkAndNotifyOutOfRange(vital: VitalReading) async -> Bool {
        guard let userID = authManager.currentUserUID,
              let modelContext = modelContext else {
            print("🚫 VitalAlertService: No authenticated user or modelContext.")
            return false
        }

        do {
            let userSettingsDescriptor = FetchDescriptor<UserSettings>(predicate: #Predicate { settings in
                settings.userID == userID
            })
            guard let userSettings = try modelContext.fetch(userSettingsDescriptor).first else {
                print("🚫 VitalAlertService: No UserSettings found for user \(userID).")
                return false
            }
            let alertSettings = userSettings.alertSettings
            let emergencyContacts = alertSettings.emergencyContacts
            guard !emergencyContacts.isEmpty else {
                print("🚫 VitalAlertService: No emergency contacts found for user \(userID).")
                NotificationCenter.default.post(name: NSNotification.Name("NoEmergencyContacts"), object: nil)
                return false
            }

            var isOutOfRange = false
            var recordedValue = ""
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            dateFormatter.timeZone = TimeZone(identifier: "Asia/Karachi")

            print("🔍 Checking vital: Type=\(vital.type.displayName), Systolic=\(vital.systolic ?? 0), Diastolic=\(vital.diastolic ?? 0), Sugar=\(vital.sugarLevel ?? 0)")
            print("🔍 Thresholds: BP=\(alertSettings.bpThreshold.minSystolic)-\(alertSettings.bpThreshold.maxSystolic)/\(alertSettings.bpThreshold.minDiastolic)-\(alertSettings.bpThreshold.maxDiastolic), Sugar=\(alertSettings.afterMealSugarThreshold.min)-\(alertSettings.afterMealSugarThreshold.max)")

            switch vital.type {
            case .bp:
                if let systolic = vital.systolic, let diastolic = vital.diastolic {
                    let bpThreshold = alertSettings.bpThreshold
                    if systolic < bpThreshold.minSystolic || systolic > bpThreshold.maxSystolic ||
                       diastolic < bpThreshold.minDiastolic || diastolic > bpThreshold.maxDiastolic {
                        isOutOfRange = true
                        recordedValue = "\(systolic)/\(diastolic) mmHg"
                        print("🔍 BP out of range: \(recordedValue)")
                    } else {
                        print("🔍 BP within range: \(recordedValue)")
                    }
                } else {
                    print("🔍 BP invalid: Missing systolic or diastolic values")
                }
            case .sugar:
                if let sugarLevel = vital.sugarLevel, let sugarReadingType = vital.sugarReadingType {
                    let sugarThreshold: SMASugarThreshold
                    switch sugarReadingType {
                    case .fasting:
                        sugarThreshold = alertSettings.fastingSugarThreshold
                        print("🔍 Comparing sugar with Fasting threshold: \(sugarThreshold.min)-\(sugarThreshold.max)")
                    case .afterMeal:
                        sugarThreshold = alertSettings.afterMealSugarThreshold
                        print("🔍 Comparing sugar with After Meal threshold: \(sugarThreshold.min)-\(sugarThreshold.max)")
                    }
                    if sugarLevel < sugarThreshold.min || sugarLevel > sugarThreshold.max {
                        isOutOfRange = true
                        recordedValue = "\(sugarLevel) mg/dL (\(sugarReadingType.rawValue))"
                        print("🔍 Sugar out of range: \(recordedValue)")
                    } else {
                        print("🔍 Sugar within range: \(recordedValue)")
                    }
                } else {
                    print("🚫 Sugar invalid: Missing sugar level or reading type")
                }
            }

            if isOutOfRange {
                print("truee : \(isOutOfRange)")
                let emailBody = """
                Dear Attendant(s),

                \(userSettings.userName ?? "User")'s \(vital.type.displayName) level is out of range.
                Type: \(vital.type.displayName)
                Recorded value: \(recordedValue)
                Time: \(dateFormatter.string(from: vital.time))
                Date: \(dateFormatter.string(from: vital.date))

                Please ensure the user receives appropriate attention.

                Best regards,
                Smart HealthMate Team
                """

                let data: [String: Any] = [
                    "to": emergencyContacts,
                    "subject": "Smart HealthMate: Out-of-Range Vital Reading for \(userSettings.userName ?? "User")",
                    "body": emailBody
                ]

                // Send data to your backend
                guard let url = URL(string: "http://localhost:3000/send-email") else {
                    print("🚫 Invalid backend URL")
                    return false
                }

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: data)
                } catch {
                    print("🚫 Error serializing JSON: \(error.localizedDescription)")
                    return false
                }

                do {
                    let (data, response) = try await URLSession.shared.data(for: request)
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        print("🚫 Backend responded with error: \(String(describing: (response as? HTTPURLResponse)?.statusCode))")
                        return false
                    }
                    print("📧 Successfully sent out-of-range email to \(emergencyContacts.joined(separator: ", ")): \(String(data: data, encoding: .utf8) ?? "No response data")")
                } catch {
                    print("📧 Error sending request to backend: \(error.localizedDescription)")
                    return false
                }

                let content = UNMutableNotificationContent()
                content.title = "Vital Reading Alert"
                content.body = "\(vital.type.displayName) level is out of range. Email has been sent to your attendants."
                content.sound = .default
                print("-----")
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                
                let request1 = UNNotificationRequest(identifier: "VitalOutOfRange-\(vital.id.uuidString)", content: content, trigger: trigger)
                do {
                    try await notificationCenter.add(request1)
                    print("🔔 Scheduled out-of-range notification for \(vital.type.displayName) (ID: VitalOutOfRange-\(vital.id.uuidString))")
                } catch {
                    print("🔔 Error scheduling out-of-range notification: \(error.localizedDescription)")
                    return false
                }
            } else {
                print("🔍 No action taken: Vital reading within range.")
            }

            return isOutOfRange
        } catch {
            print("🚫 Error checking out-of-range vital: \(error.localizedDescription)")
            return false
        }
    }
}



// MARK: - VitalsCardView
struct VitalsCardView: View {
    let type: VitalReading.VitalType
    var systolic: Int?
    var diastolic: Int?
    var sugarLevel: Int?
    let time: Date
    let status: String

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(tintColor.opacity(0.05))
            RoundedRectangle(cornerRadius: 12)
                .fill(tintColor)
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: iconName)
                        .font(.subheadline)
                        .foregroundColor(tintColor)
                        .padding(6)
                        .background(tintColor.opacity(0.15))
                        .clipShape(Circle())
                    VStack(alignment: .leading) {
                        Text(type.displayName)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("Latest Reading")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                Text(displayValue)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                HStack {
                    Text(time, style: .time)
                        .font(.callout)
                        .foregroundColor(.gray)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(unit)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.leading, 19)
            .padding(15)
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        .padding(.horizontal, 5)
    }

    private var displayValue: String {
        switch type {
        case .bp:
            return "\(systolic ?? 0)/\(diastolic ?? 0)"
        case .sugar:
            return "\(sugarLevel ?? 0)"
        }
    }

    private var iconName: String {
        switch type {
        case .bp: return "heart.fill"
        case .sugar: return "waveform.path.ecg"
        }
    }

    private var unit: String {
        switch type {
        case .bp: return "mmHg"
        case .sugar: return "mg/dL"
        }
    }

    private var tintColor: Color {
        switch type {
        case .bp: return .red
        case .sugar: return .orange
        }
    }
}

// MARK: - VitalReading
@Model
final class VitalReading: Identifiable, Equatable {
    @Attribute(.unique) var id: UUID
    var type: VitalType
    var systolic: Int?
    var diastolic: Int?
    var sugarLevel: Int?
    var sugarReadingType: SugarReadingType? // New property for sugar reading type
    var date: Date
    var time: Date
    var userSettings: UserSettings?

    enum VitalType: String, CaseIterable, Identifiable, Codable {
        case bp = "bp"
        case sugar = "sugar"
        var id: String { self.rawValue }
        var displayName: String {
            switch self {
            case .bp: return "Blood Pressure"
            case .sugar: return "Blood Sugar"
            }
        }
        
        var accessibilityID: String {
                switch self {
                case .bp: return "forBP"
                case .sugar: return "forSugar"
               
                }
            }
    }

    enum SugarReadingType: String, CaseIterable, Identifiable, Codable {
        case fasting = "Fasting"
        case afterMeal = "After Meal"
        var id: String { self.rawValue }
    }

    init(id: UUID = UUID(), type: VitalType, systolic: Int? = nil, diastolic: Int? = nil, sugarLevel: Int? = nil, sugarReadingType: SugarReadingType? = nil, date: Date, time: Date, userSettings: UserSettings? = nil) {
        self.id = id
        self.type = type
        self.systolic = systolic
        self.diastolic = diastolic
        self.sugarLevel = sugarLevel
        self.sugarReadingType = sugarReadingType
        self.date = date
        self.time = time
        self.userSettings = userSettings
    }

    func getStatus() -> String {
        switch type {
        case .bp:
            if let sys = systolic, let dias = diastolic {
                if sys < 90 || dias < 60 { return "Low" }
                if sys <= 120 && dias <= 80 { return "Normal" }
                return "Elevated"
            }
        case .sugar:
            if let sugar = sugarLevel {
                if sugar < 70 { return "Low" }
                if sugar <= 140 { return "Normal" }
                return "Elevated"
            }
        }
        return "N/A"
    }

    func getStatusColor() -> Color {
        let status = getStatus()
        switch vitalStatusCategory(status: status) {
        case .normal: return .green
        case .elevated: return .orange
        case .low: return .blue
        case .unknown: return .gray
        }
    }

    private func vitalStatusCategory(status: String) -> VitalStatusCategory {
        switch status {
        case "Normal": return .normal
        case "Elevated": return .elevated
        case "Low": return .low
        default: return .unknown
        }
    }

    enum VitalStatusCategory {
        case normal, low, elevated, unknown
    }
}

// MARK: - VitalSummaryCard
struct VitalSummaryCard: View {
    let type: VitalReading.VitalType
    var systolic: Int?
    var diastolic: Int?
    var sugarLevel: Int?
    var time: Date
    let status: String

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
            .aspectRatio(3/1, contentMode: .fit)
            .overlay(
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        Text(displayValue)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(tintColor.opacity(0.8))
                        Text(type.displayName)
                            .font(.subheadline)
                            .foregroundColor(tintColor.opacity(0.6))
                        Text(time, style: .time)
                            .font(.caption)
                            .foregroundColor(tintColor.opacity(0.5))
                    }
                    Spacer()
                    Image(systemName: iconName)
                        .font(.title2)
                        .padding(8)
                        .background(tintColor.opacity(0.2))
                        .clipShape(Circle())
                        .foregroundColor(tintColor.opacity(0.7))
                }
                .padding(12)
            )
    }

    private var displayValue: String {
        switch type {
        case .bp:
            return "\(systolic ?? 0)/\(diastolic ?? 0)"
        case .sugar:
            return "\(sugarLevel ?? 0)"
        }
    }

    private var iconName: String {
        switch type {
        case .bp: return "heart.fill"
        case .sugar: return "waveform.path.ecg"
        }
    }

    private var tintColor: Color {
        switch type {
        case .bp: return .red
        case .sugar: return .orange
        }
    }

    private var gradientStart: Color {
        switch type {
        case .bp: return .red.opacity(0.05)
        case .sugar: return .orange.opacity(0.05)
        }
    }

    private var gradientEnd: Color {
        switch type {
        case .bp: return .red.opacity(0.1)
        case .sugar: return .orange.opacity(0.1)
        }
    }
}

// MARK: - RecentVitalReadingRow
struct RecentVitalReadingRow: View {
    let vital: VitalReading

    var body: some View {
        HStack {
            Image(systemName: vital.type == .bp ? "heart.fill" : "waveform.path.ecg")
                .foregroundColor(vital.type == .bp ? .red : .orange)
                .font(.body)
                .frame(width: 30, height: 30)
                .background(vital.type == .bp ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
                .clipShape(Circle())
            VStack(alignment: .leading) {
                Text(vital.type.displayName + (vital.sugarReadingType != nil ? " (\(vital.sugarReadingType!.rawValue))" : ""))
                    .font(.headline)
                    .fontWeight(.medium)
                Text("\(vital.date, formatter: Self.dateFormatter) at \(vital.time, formatter: Self.timeFormatter)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(displayValue)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(vital.type == .bp ? "mmHg" : "mg/dL")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }

    private var displayValue: String {
        switch vital.type {
        case .bp:
            return "\(vital.systolic ?? 0)/\(vital.diastolic ?? 0)"
        case .sugar:
            return "\(vital.sugarLevel ?? 0)"
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - AddVitalReadingSheetView
struct AddVitalReadingSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var vitalAlertService: VitalAlertService
    @State private var showOutOfRangeAlert = false
    @State private var outOfRangeMessage = ""

    var onSave: (VitalReading) -> Void

    @State private var selectedType: VitalReading.VitalType = .bp
    @State private var systolicInput: String = ""
    @State private var diastolicInput: String = ""
    @State private var sugarLevelInput: String = ""
    @State private var sugarReadingType: VitalReading.SugarReadingType = .fasting // Default to fasting
    @State private var selectedDateTime: Date = Date()

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

    init(onSave: @escaping (VitalReading) -> Void) {
        self.onSave = onSave
        _vitalAlertService = StateObject(wrappedValue: VitalAlertService(authManager: AuthManager()))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reading Type")) {
                    Picker("Type", selection: $selectedType) {
                        ForEach(VitalReading.VitalType.allCases) { type in
                            Text(type.displayName).tag(type).accessibilityIdentifier(type.accessibilityID) // Add accessibility identifier
                        }
                    }
                    .pickerStyle(.segmented)
                }
                if selectedType == .sugar {
                    Section(header: Text("Sugar Reading Type")) {
                        Picker("Sugar Type", selection: $sugarReadingType) {
                            ForEach(VitalReading.SugarReadingType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                Section(header: Text("Measurements")) {
                    if selectedType == .bp {
                        TextField("Systolic (mmHg)", text: $systolicInput)
                            .keyboardType(.numberPad)
                            .accessibilityIdentifier("systolic")
                        TextField("Diastolic (mmHg)", text: $diastolicInput)
                            .keyboardType(.numberPad)
                            .accessibilityIdentifier("diastolic")
                    } else {
                        TextField("Sugar Level (mg/dL)", text: $sugarLevelInput)
                            .keyboardType(.numberPad)
                            .accessibilityIdentifier("sugarLevel")
                    }
                }
                Section(header: Text("Date and Time")) {
                    DatePicker("Date & Time", selection: $selectedDateTime, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                }
            }
            .navigationTitle("Add Vital Reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addReading()
                    }
                    .accessibilityIdentifier("addVital")
                    .disabled(!isValidInput())
                }
            }
            .alert("Vital Reading Alert", isPresented: $showOutOfRangeAlert) {
                Button("OK") { }
            } message: {
                Text(outOfRangeMessage)
            }
            .onAppear {
                vitalAlertService.setModelContext(modelContext)
            }
        }
    }

    private func isValidInput() -> Bool {
        if selectedType == .bp {
            return !systolicInput.isEmpty && Int(systolicInput) != nil &&
                   !diastolicInput.isEmpty && Int(diastolicInput) != nil
        } else {
            return !sugarLevelInput.isEmpty && Int(sugarLevelInput) != nil
        }
    }

    private func addReading() {
        let calendar = Calendar.current
        let dateOnly = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: selectedDateTime)) ?? Date()
        let timeOnly = calendar.date(from: calendar.dateComponents([.hour, .minute], from: selectedDateTime)) ?? Date()

        let newVital: VitalReading
        if selectedType == .bp {
            guard let systolic = Int(systolicInput),
                  let diastolic = Int(diastolicInput) else {
                print("🚫 Invalid BP input: Systolic=\(systolicInput), Diastolic=\(diastolicInput)")
                return
            }
            newVital = VitalReading(
                type: .bp,
                systolic: systolic,
                diastolic: diastolic,
                date: dateOnly,
                time: timeOnly,
                userSettings: currentUserSettings
            )
            print("🔍 Created VitalReading: Type=BP, Systolic=\(systolic), Diastolic=\(diastolic), Date=\(dateOnly), Time=\(timeOnly)")
        } else {
            guard let sugarLevel = Int(sugarLevelInput) else {
                print("🚫 Invalid Sugar input: SugarLevel=\(sugarLevelInput)")
                return
            }
            newVital = VitalReading(
                type: .sugar,
                sugarLevel: sugarLevel,
                sugarReadingType: sugarReadingType,
                date: dateOnly,
                time: timeOnly,
                userSettings: currentUserSettings
            )
            print("🔍 Created VitalReading: Type=Sugar, SugarLevel=\(sugarLevel), SugarReadingType=\(sugarReadingType.rawValue), Date=\(dateOnly), Time=\(timeOnly)")
        }

        modelContext.insert(newVital)
        onSave(newVital)

        Task {
            let isOutOfRange = await vitalAlertService.checkAndNotifyOutOfRange(vital: newVital)
            print("Vital reading added: \(newVital.type.displayName), Out of range: \(isOutOfRange)")
            if isOutOfRange {
                DispatchQueue.main.async {
                    outOfRangeMessage = "\(newVital.type.displayName) level is out of range."
                    showOutOfRangeAlert = true
                }
            }
        }

        dismiss()
    }
}

// MARK: - EditVitalReadingSheetView
struct EditVitalReadingSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var vital: VitalReading
    var onSave: (VitalReading) -> Void

    @State private var selectedType: VitalReading.VitalType
    @State private var systolicInput: String
    @State private var diastolicInput: String
    @State private var sugarLevelInput: String
    @State private var sugarReadingType: VitalReading.SugarReadingType?
    @State private var selectedDateTime: Date

    init(vital: VitalReading, onSave: @escaping (VitalReading) -> Void) {
        self.vital = vital
        self.onSave = onSave
        _selectedType = State(initialValue: vital.type)
        _systolicInput = State(initialValue: vital.systolic != nil ? String(vital.systolic!) : "")
        _diastolicInput = State(initialValue: vital.diastolic != nil ? String(vital.diastolic!) : "")
        _sugarLevelInput = State(initialValue: vital.sugarLevel != nil ? String(vital.sugarLevel!) : "")
        _sugarReadingType = State(initialValue: vital.sugarReadingType)
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: vital.date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: vital.time)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        _selectedDateTime = State(initialValue: calendar.date(from: components) ?? Date())
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reading Type")) {
                    Picker("Type", selection: $selectedType) {
                        ForEach(VitalReading.VitalType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(true)
                }
                if selectedType == .sugar {
                    Section(header: Text("Sugar Reading Type")) {
                        Picker("Sugar Type", selection: $sugarReadingType) {
                            Text("Select Type").tag(VitalReading.SugarReadingType?.none)
                            ForEach(VitalReading.SugarReadingType.allCases) { type in
                                Text(type.rawValue).tag(type as VitalReading.SugarReadingType?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                Section(header: Text("Measurements")) {
                    if selectedType == .bp {
                        TextField("Systolic (mmHg)", text: $systolicInput)
                            .keyboardType(.numberPad)
                        TextField("Diastolic (mmHg)", text: $diastolicInput)
                            .keyboardType(.numberPad)
                    } else {
                        TextField("Sugar Level (mg/dL)", text: $sugarLevelInput)
                            .keyboardType(.numberPad)
                    }
                }
                Section(header: Text("Date and Time")) {
                    DatePicker("Date & Time", selection: $selectedDateTime, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                }
            }
            .navigationTitle("Edit Vital Reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateReading()
                    }
                    .disabled(!isValidInput())
                }
            }
        }
    }

    private func isValidInput() -> Bool {
        if selectedType == .bp {
            return !systolicInput.isEmpty && Int(systolicInput) != nil &&
                   !diastolicInput.isEmpty && Int(diastolicInput) != nil
        } else {
            return !sugarLevelInput.isEmpty && Int(sugarLevelInput) != nil && sugarReadingType != nil
        }
    }

    private func updateReading() {
        let calendar = Calendar.current
        vital.date = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: selectedDateTime)) ?? Date()
        vital.time = calendar.date(from: calendar.dateComponents([.hour, .minute], from: selectedDateTime)) ?? Date()
        if selectedType == .bp {
            vital.systolic = Int(systolicInput)
            vital.diastolic = Int(diastolicInput)
            vital.sugarLevel = nil
            vital.sugarReadingType = nil
        } else {
            vital.sugarLevel = Int(sugarLevelInput)
            vital.systolic = nil
            vital.diastolic = nil
            vital.sugarReadingType = sugarReadingType
        }
        onSave(vital)
        dismiss()
    }
}

// MARK: - VitalsMonitoringScreen
struct VitalsMonitoringScreen: View {
    @EnvironmentObject var authManager: AuthManager
    @Query(sort: [SortDescriptor(\VitalReading.date, order: .forward), SortDescriptor(\VitalReading.time, order: .forward)])
    private var allVitals: [VitalReading]
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Medicine> { $0.isActive == true && $0.userSettings?.userID != nil })
    var activeMedicines: [Medicine]
    @State private var showingAddReadingSheet = false
    @State private var showingEditReadingSheet = false
    @State private var selectedVitalForEdit: VitalReading?
    @State private var showingActionSheet = false
    @State private var vitalToDelete: VitalReading?
    @State private var showNoContactsAlert = false
    @StateObject private var vitalAlertService: VitalAlertService

    private var userVitals: [VitalReading] {
        allVitals.filter { $0.userSettings?.userID == authManager.currentUserUID }
    }

    private var latestBP: VitalReading? {
        userVitals.filter { $0.type == .bp }.last
    }

    private var latestSugar: VitalReading? {
        userVitals.filter { $0.type == .sugar }.last
    }

    init() {
        _vitalAlertService = StateObject(wrappedValue: VitalAlertService(authManager: AuthManager()))
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Track your blood pressure and sugar levels")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                        SMAMedicineTrackerStats(medicinesCount: activeMedicines.count)
                       
                        Text("Recent Readings")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.top, 10)
                            .padding(.horizontal)
                        LazyVStack(spacing: 8) {
                            if userVitals.isEmpty {
                                Text("No recent vital readings for this user.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                            } else {
                                ForEach(userVitals.reversed()) { vital in
                                    RecentVitalReadingRow(vital: vital)
                                        .onLongPressGesture {
                                            self.selectedVitalForEdit = vital
                                            self.vitalToDelete = vital
                                            self.showingActionSheet = true
                                        }
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 60)
                }
            }
            .navigationTitle("Vitals Monitoring")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("Add Reading tapped from NavigationBar!")
                        showingAddReadingSheet = true
                    }) {
                        Label("Add Reading", systemImage: "plus")
                    }
                    .accessibilityIdentifier("plusVital")
                }
            }
            .sheet(isPresented: $showingAddReadingSheet) {
                AddVitalReadingSheetView { newVital in }
            }
            .sheet(isPresented: $showingEditReadingSheet) {
                if let vitalToEdit = selectedVitalForEdit {
                    EditVitalReadingSheetView(vital: vitalToEdit) { updatedVital in }
                }
            }
            .actionSheet(isPresented: $showingActionSheet) {
                ActionSheet(
                    title: Text("Vital Reading Options"),
                    message: Text("What do you want to do with this reading?"),
                    buttons: [
                        .default(Text("Edit")) {
                            showingEditReadingSheet = true
                        },
                        .destructive(Text("Delete")) {
                            if let vital = vitalToDelete {
                                deleteVital(vital)
                            }
                        },
                        .cancel()
                    ]
                )
            }
            .alert("Action Required", isPresented: $showNoContactsAlert) {
                Button("OK") { }
            } message: {
                Text("Please add emergency contacts in your profile or enable notifications to receive vital alerts.")
            }
            .onAppear {
                vitalAlertService.setModelContext(modelContext)
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
                            } else if let error = error {
                                print("🔔 Notification authorization error: \(error.localizedDescription)")
                            }
                        }
                    }
                }
                cleanUpOldReadings()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NoEmergencyContacts"))) { _ in
                showNoContactsAlert = true
            }
        }
    }

    private func cleanUpOldReadings() {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date.distantPast
        for vital in userVitals where vital.date < thirtyDaysAgo {
            modelContext.delete(vital)
        }
    }

    private func deleteVital(_ vital: VitalReading) {
        modelContext.delete(vital)
    }
}
