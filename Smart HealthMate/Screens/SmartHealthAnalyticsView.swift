import Foundation
import SwiftUI
import SwiftData
import FirebaseAuth

// MARK: - Persisted Data Models for SwiftData
@Model
final class PersistedMedicinePattern: Identifiable {
    @Attribute(.unique) var id: UUID
    var userID: String
    var medicineName: String
    var patternDescription: String
    var severity: String
    
    init(id: UUID = UUID(), userID: String, medicineName: String, patternDescription: String, severity: String) {
        self.id = id
        self.userID = userID
        self.medicineName = medicineName
        self.patternDescription = patternDescription
        self.severity = severity
    }
}

@Model
final class PersistedVitalPattern: Identifiable {
    @Attribute(.unique) var id: UUID
    var userID: String
    var vitalType: String
    var sugarReadingType: String?
    var patternDescription: String
    var trend: String
    var averageValue: String
    var isDaily: Bool
    
    init(id: UUID = UUID(), userID: String, vitalType: String, sugarReadingType: String?, patternDescription: String, trend: String, averageValue: String, isDaily: Bool = false) {
        self.id = id
        self.userID = userID
        self.vitalType = vitalType
        self.sugarReadingType = sugarReadingType
        self.patternDescription = patternDescription
        self.trend = trend
        self.averageValue = averageValue
        self.isDaily = isDaily
    }
}

@Model
final class PersistedSpike: Identifiable {
    @Attribute(.unique) var id: UUID
    var userID: String
    var type: String
    var sugarReadingType: String?
    var value: String
    var time: Date
    var context: String
    
    init(id: UUID = UUID(), userID: String, type: String, sugarReadingType: String?, value: String, time: Date, context: String) {
        self.id = id
        self.userID = userID
        self.type = type
        self.sugarReadingType = sugarReadingType
        self.value = value
        self.time = time
        self.context = context
    }
}

@Model
final class PersistedRecommendation: Identifiable {
    @Attribute(.unique) var id: UUID
    var userID: String
    var title: String
    var details: String
    var category: String
    
    init(id: UUID = UUID(), userID: String, title: String, details: String, category: String) {
        self.id = id
        self.userID = userID
        self.title = title
        self.details = details
        self.category = category
    }
}

@Model
final class PersistedInsight: Identifiable {
    @Attribute(.unique) var id: UUID
    var userID: String
    var title: String
    var details: String
    var impact: String
    
    init(id: UUID = UUID(), userID: String, title: String, details: String, impact: String) {
        self.id = id
        self.userID = userID
        self.title = title
        self.details = details
        self.impact = impact
    }
}

// MARK: - Core Analytics Data Models
struct MedicinePattern: Identifiable, Hashable {
    let id = UUID()
    let medicineName: String
    let patternDescription: String
    let severity: String
}

struct VitalPattern: Identifiable, Hashable {
    let id = UUID()
    let vitalType: String
    let sugarReadingType: String?
    let patternDescription: String
    let trend: String
    let averageValue: String
}

struct Spike: Identifiable, Hashable {
    let id = UUID()
    let type: String
    let sugarReadingType: String?
    let value: String
    let time: Date
    let context: String
}

struct Recommendation: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let details: String
    let category: String
}

struct Insight: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let details: String
    let impact: String
}

// MARK: - HealthAnalysisResults Struct
struct HealthAnalysisResults {
    let medicinePatterns: [MedicinePattern]
    let vitalPatterns: [VitalPattern]
    let spikes: [Spike]
    let recommendations: [Recommendation]
    let insights: [Insight]
    let dailyPatterns: [VitalPattern]
    
    var isEmpty: Bool {
        medicinePatterns.isEmpty && vitalPatterns.isEmpty && spikes.isEmpty && recommendations.isEmpty && insights.isEmpty && dailyPatterns.isEmpty
    }
}

// MARK: - GeminiHealthAnalyticsProcessor
class GeminiHealthAnalyticsProcessor {
    private let geminiService = GeminiService1()
    private let authManager: AuthManager
    private let modelContext: ModelContext
    
    enum HealthAnalysisError: Error, LocalizedError {
        case noMeaningfulAnalysis(String)
        case parsingError(String)
        case apiCallError(String)
        case saveError(String)
        
        var errorDescription: String? {
            switch self {
            case .noMeaningfulAnalysis(let message): return message
            case .parsingError(let message): return "Failed to parse AI response: \(message)"
            case .apiCallError(let message): return "AI API Error: \(message)"
            case .saveError(let message): return "Failed to save insights: \(message)"
            }
        }
    }
    
    init(authManager: AuthManager, modelContext: ModelContext) {
        self.authManager = authManager
        self.modelContext = modelContext
    }
    
    func analyzeHealthData(
        medicines: [Medicine],
        vitalReadings: [VitalReading],
        reminders: [Reminder],
        currentDate: Date
    ) async throws -> HealthAnalysisResults {
        guard let userID = authManager.currentUserUID else {
            throw HealthAnalysisError.noMeaningfulAnalysis("No authenticated user found.")
        }
        
        print("Starting health analysis for userID: \(userID) at \(Date())")
        
        // Fetch user-specific alert settings
        let userSettingsDescriptor = FetchDescriptor<UserSettings>(
            predicate: #Predicate { $0.userID == userID }
        )
        let userSettings = try modelContext.fetch(userSettingsDescriptor).first
        let alertSettings = userSettings?.alertSettings ?? SMAAlertSettings.defaultSettings
        
        let fastingThreshold = "\(alertSettings.fastingSugarThreshold.min)-\(alertSettings.fastingSugarThreshold.max) mg/dL"
        let afterMealThreshold = "\(alertSettings.afterMealSugarThreshold.min)-\(alertSettings.afterMealSugarThreshold.max) mg/dL"
        let bpThreshold = "\(alertSettings.bpThreshold.minSystolic)/\(alertSettings.bpThreshold.minDiastolic)-\(alertSettings.bpThreshold.maxSystolic)/\(alertSettings.bpThreshold.maxDiastolic) mmHg"
        
        var inputPrompt = """
        Analyze the following patient health data for user ID: \(userID). Extract distinct patterns, spikes, recommendations, and insights for today (\(currentDate.formatted(date: .abbreviated, time: .omitted))). Provide output in the following strict format for each finding on a new line. Do NOT include any other conversational text or introduction. Be concise and provide a single, clear disclaimer at the end stating that this information is for general knowledge and not a substitute for professional medical advice.
        MEDICINE_PATTERN: [MedicineName]; [PatternDescription including adherence percentage (taken/due doses)]; [Severity]
        VITAL_PATTERN: [VitalType]; [SugarReadingType or None]; [PatternDescription based on all readings]; [Trend]; [AverageValue]
        DAILY_PATTERN: [VitalType]; [SugarReadingType or None]; [PatternDescription for today's readings]; [Trend]; [AverageValue]
        SPIKE: [Type]; [SugarReadingType or None]; [Value]; [Time (HH:MM AM/PM)]; [Context]
        RECOMMENDATION: [Title]; [Details]; [Category]
        INSIGHT: [Title]; [Details]; [Impact]
        
        If no data for a category, omit it. Thresholds: Fasting Sugar (\(fastingThreshold)), After Meal Sugar (\(afterMealThreshold)), Blood Pressure (\(bpThreshold)). For MEDICINE_PATTERN, calculate adherence as percentage of doses taken vs. due based on schedules. For VITAL_PATTERN, analyze all blood pressure and blood sugar (fasting and after meal) readings for trends. For SPIKE and DAILY_PATTERN, focus on today's readings only. Data:
        """
        
        if medicines.isEmpty && vitalReadings.isEmpty && reminders.isEmpty {
            return HealthAnalysisResults(
                medicinePatterns: [], vitalPatterns: [], spikes: [], recommendations: [], insights: [], dailyPatterns: []
            )
        }
        
        if !medicines.isEmpty {
            inputPrompt += "\nMedicine Intake (with adherence):\n"
            for med in medicines {
                let status = med.isActive ? "Active" : "Inactive"
                let dosesDue = med.dosesDueToday
                let dosesTaken = med.dosesTakenToday
                let adherencePercentage = dosesDue > 0 ? (Double(dosesTaken) / Double(dosesDue) * 100.0).rounded() : 0.0
                let missedDoseInfo = med.hasMissedDoseToday ? " (Missed a dose today!)" : ""
                inputPrompt += "- \(med.name) (\(med.dosage), \(med.displayTimingFrequency)). Purpose: \(med.purpose). Status: \(status). Adherence: \(dosesTaken)/\(dosesDue) (\(Int(adherencePercentage))%)\(missedDoseInfo).\n"
            }
        }
        
        if !vitalReadings.isEmpty {
            inputPrompt += "\nVital Readings (all for trends, most recent first):\n"
            let sortedVitals = vitalReadings.sorted { $0.date.combined(with: $0.time) > $1.date.combined(with: $1.time) }
            for vital in sortedVitals {
                let readingValue: String
                let sugarType = vital.sugarReadingType?.rawValue ?? "None"
                if vital.type == .bp, let sys = vital.systolic, let dias = vital.diastolic {
                    readingValue = "\(sys)/\(dias) mmHg"
                } else if vital.type == .sugar, let sugar = vital.sugarLevel {
                    readingValue = "\(sugar) mg/dL (\(sugarType))"
                } else {
                    readingValue = "N/A"
                }
                inputPrompt += "- \(vital.type.displayName) on \(vital.date.formatted(date: .abbreviated, time: .omitted)) at \(vital.time.formatted(date: .omitted, time: .shortened)): \(readingValue) (Status: \(vital.getStatus()))\n"
            }
            
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: currentDate)
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            let todaysVitals = vitalReadings.filter {
                let combinedDate = $0.date.combined(with: $0.time)
                return combinedDate >= today && combinedDate < tomorrow
            }
            if !todaysVitals.isEmpty {
                inputPrompt += "\nToday's Vital Readings (for spikes and daily patterns):\n"
                for vital in todaysVitals.sorted { $0.date.combined(with: $0.time) > $1.date.combined(with: $1.time) } {
                    let readingValue: String
                    let sugarType = vital.sugarReadingType?.rawValue ?? "None"
                    if vital.type == .bp, let sys = vital.systolic, let dias = vital.diastolic {
                        readingValue = "\(sys)/\(dias) mmHg"
                    } else if vital.type == .sugar, let sugar = vital.sugarLevel {
                        readingValue = "\(sugar) mg/dL (\(sugarType))"
                    } else {
                        readingValue = "N/A"
                    }
                    inputPrompt += "- \(vital.type.displayName) at \(vital.time.formatted(date: .omitted, time: .shortened)): \(readingValue) (Status: \(vital.getStatus()))\n"
                }
            }
        }
        
        if !reminders.isEmpty {
            inputPrompt += "\nReminders:\n"
            for reminder in reminders {
                let status = reminder.active ? "Active" : "Inactive"
                inputPrompt += "- \(reminder.title) (\(reminder.type.displayName)). Status: \(status). Overdue today: \(reminder.isOverdue ? "Yes" : "No").\n"
            }
        }
        
        print("Prompt sent to Gemini at \(Date()): \n\(inputPrompt)")
        
        let rawGeminiResponse: String
        do {
            rawGeminiResponse = try await geminiService.generateContent(prompt: inputPrompt)
            print("Raw Gemini Response at \(Date()): \n\(rawGeminiResponse)")
        } catch {
            print("Gemini API call failed: \(error.localizedDescription)")
            throw HealthAnalysisError.apiCallError(error.localizedDescription)
        }
        
        if rawGeminiResponse.contains("I am a large language model") {
            throw HealthAnalysisError.noMeaningfulAnalysis("Gemini provided a generic response. Please ensure sufficient health data is provided.")
        }
        
        let cleanedResponse = rawGeminiResponse.components(separatedBy: "Important Note:").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? rawGeminiResponse
        let results = parseGeminiResponse(rawText: cleanedResponse)
        
        do {
            try saveResultsToSwiftData(results: results, userID: userID)
            print("Successfully saved insights for userID: \(userID) at \(Date())")
        } catch {
            print("Failed to save insights: \(error.localizedDescription)")
            throw HealthAnalysisError.saveError(error.localizedDescription)
        }
        
        return results
    }
    
    private func parseGeminiResponse(rawText: String) -> HealthAnalysisResults {
        var medicinePatterns: [MedicinePattern] = []
        var vitalPatterns: [VitalPattern] = []
        var dailyPatterns: [VitalPattern] = []
        var spikes: [Spike] = []
        var recommendations: [Recommendation] = []
        var insights: [Insight] = []
        
        let lines = rawText.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Karachi")
        
        for line in lines {
            if line.isEmpty { continue }
            
            if line.starts(with: "MEDICINE_PATTERN:") {
                let content = line.replacingOccurrences(of: "MEDICINE_PATTERN:", with: "").trimmingCharacters(in: .whitespaces)
                let parts = content.split(separator: ";").map { String($0).trimmingCharacters(in: .whitespaces) }
                if parts.count >= 3 {
                    medicinePatterns.append(MedicinePattern(medicineName: parts[0], patternDescription: parts[1], severity: parts[2]))
                } else {
                    print("Warning: Could not parse MEDICINE_PATTERN: \(line)")
                }
            } else if line.starts(with: "VITAL_PATTERN:") {
                let content = line.replacingOccurrences(of: "VITAL_PATTERN:", with: "").trimmingCharacters(in: .whitespaces)
                let parts = content.split(separator: ";").map { String($0).trimmingCharacters(in: .whitespaces) }
                if parts.count >= 5 {
                    let sugarType = parts[1] == "None" ? nil : parts[1]
                    vitalPatterns.append(VitalPattern(vitalType: parts[0], sugarReadingType: sugarType, patternDescription: parts[2], trend: parts[3], averageValue: parts[4]))
                } else {
                    print("Warning: Could not parse VITAL_PATTERN: \(line)")
                }
            } else if line.starts(with: "DAILY_PATTERN:") {
                let content = line.replacingOccurrences(of: "DAILY_PATTERN:", with: "").trimmingCharacters(in: .whitespaces)
                let parts = content.split(separator: ";").map { String($0).trimmingCharacters(in: .whitespaces) }
                if parts.count >= 5 {
                    let sugarType = parts[1] == "None" ? nil : parts[1]
                    dailyPatterns.append(VitalPattern(vitalType: parts[0], sugarReadingType: sugarType, patternDescription: parts[2], trend: parts[3], averageValue: parts[4]))
                } else {
                    print("Warning: Could not parse DAILY_PATTERN: \(line)")
                }
            } else if line.starts(with: "SPIKE:") {
                let content = line.replacingOccurrences(of: "SPIKE:", with: "").trimmingCharacters(in: .whitespaces)
                let parts = content.split(separator: ";").map { String($0).trimmingCharacters(in: .whitespaces) }
                if parts.count >= 5 {
                    let sugarType = parts[1] == "None" ? nil : parts[1]
                    if let time = dateFormatter.date(from: parts[3]) {
                        spikes.append(Spike(type: parts[0], sugarReadingType: sugarType, value: parts[2], time: time, context: parts[4]))
                    } else {
                        print("Warning: Could not parse time for SPIKE: '\(parts[3])' in line: \(line)")
                    }
                } else {
                    print("Warning: Could not parse SPIKE: \(line)")
                }
            } else if line.starts(with: "RECOMMENDATION:") {
                let content = line.replacingOccurrences(of: "RECOMMENDATION:", with: "").trimmingCharacters(in: .whitespaces)
                let parts = content.split(separator: ";").map { String($0).trimmingCharacters(in: .whitespaces) }
                if parts.count >= 3 {
                    recommendations.append(Recommendation(title: parts[0], details: parts[1], category: parts[2]))
                } else {
                    print("Warning: Could not parse RECOMMENDATION: \(line)")
                }
            } else if line.starts(with: "INSIGHT:") {
                let content = line.replacingOccurrences(of: "INSIGHT:", with: "").trimmingCharacters(in: .whitespaces)
                let parts = content.split(separator: ";").map { String($0).trimmingCharacters(in: .whitespaces) }
                if parts.count >= 3 {
                    insights.append(Insight(title: parts[0], details: parts[1], impact: parts[2]))
                } else {
                    print("Warning: Could not parse INSIGHT: \(line)")
                }
            }
        }
        
        return HealthAnalysisResults(
            medicinePatterns: medicinePatterns,
            vitalPatterns: vitalPatterns,
            spikes: spikes,
            recommendations: recommendations,
            insights: insights,
            dailyPatterns: dailyPatterns
        )
    }
    
    private func saveResultsToSwiftData(results: HealthAnalysisResults, userID: String) throws {
        print("Starting saveResultsToSwiftData for userID: \(userID) at \(Date())")
        
        do {
            try modelContext.transaction {
                let descriptors: [Any] = [
                    FetchDescriptor<PersistedMedicinePattern>(
                        predicate: #Predicate { $0.userID == userID }
                    ),
                    FetchDescriptor<PersistedVitalPattern>(
                        predicate: #Predicate { $0.userID == userID }
                    ),
                    FetchDescriptor<PersistedSpike>(
                        predicate: #Predicate { $0.userID == userID }
                    ),
                    FetchDescriptor<PersistedRecommendation>(
                        predicate: #Predicate { $0.userID == userID }
                    ),
                    FetchDescriptor<PersistedInsight>(
                        predicate: #Predicate { $0.userID == userID }
                    )
                ]
                
                for descriptor in descriptors {
                    if let medicineDescriptor = descriptor as? FetchDescriptor<PersistedMedicinePattern> {
                        let objects = try modelContext.fetch(medicineDescriptor)
                        print("Deleting \(objects.count) PersistedMedicinePattern objects for userID: \(userID)")
                        objects.forEach { modelContext.delete($0) }
                    } else if let vitalDescriptor = descriptor as? FetchDescriptor<PersistedVitalPattern> {
                        let objects = try modelContext.fetch(vitalDescriptor)
                        print("Deleting \(objects.count) PersistedVitalPattern objects for userID: \(userID)")
                        objects.forEach { modelContext.delete($0) }
                    } else if let spikeDescriptor = descriptor as? FetchDescriptor<PersistedSpike> {
                        let objects = try modelContext.fetch(spikeDescriptor)
                        print("Deleting \(objects.count) PersistedSpike objects for userID: \(userID)")
                        objects.forEach { modelContext.delete($0) }
                    } else if let recommendationDescriptor = descriptor as? FetchDescriptor<PersistedRecommendation> {
                        let objects = try modelContext.fetch(recommendationDescriptor)
                        print("Deleting \(objects.count) PersistedRecommendation objects for userID: \(userID)")
                        objects.forEach { modelContext.delete($0) }
                    } else if let insightDescriptor = descriptor as? FetchDescriptor<PersistedInsight> {
                        let objects = try modelContext.fetch(insightDescriptor)
                        print("Deleting \(objects.count) PersistedInsight objects for userID: \(userID)")
                        objects.forEach { modelContext.delete($0) }
                    }
                }
                
                results.medicinePatterns.forEach {
                    let pattern = PersistedMedicinePattern(userID: userID, medicineName: $0.medicineName, patternDescription: $0.patternDescription, severity: $0.severity)
                    modelContext.insert(pattern)
                    print("Inserted PersistedMedicinePattern: \(pattern.medicineName)")
                }
                results.vitalPatterns.forEach {
                    let pattern = PersistedVitalPattern(userID: userID, vitalType: $0.vitalType, sugarReadingType: $0.sugarReadingType, patternDescription: $0.patternDescription, trend: $0.trend, averageValue: $0.averageValue, isDaily: false)
                    modelContext.insert(pattern)
                    print("Inserted PersistedVitalPattern: \(pattern.vitalType) (\(pattern.sugarReadingType ?? "None"))")
                }
                results.dailyPatterns.forEach {
                    let pattern = PersistedVitalPattern(userID: userID, vitalType: $0.vitalType, sugarReadingType: $0.sugarReadingType, patternDescription: $0.patternDescription, trend: $0.trend, averageValue: $0.averageValue, isDaily: true)
                    modelContext.insert(pattern)
                    print("Inserted PersistedVitalPattern (Daily): \(pattern.vitalType) (\(pattern.sugarReadingType ?? "None"))")
                }
                results.spikes.forEach {
                    let spike = PersistedSpike(userID: userID, type: $0.type, sugarReadingType: $0.sugarReadingType, value: $0.value, time: $0.time, context: $0.context)
                    modelContext.insert(spike)
                    print("Inserted PersistedSpike: \(spike.type) (\(spike.sugarReadingType ?? "None"))")
                }
                results.recommendations.forEach {
                    let recommendation = PersistedRecommendation(userID: userID, title: $0.title, details: $0.details, category: $0.category)
                    modelContext.insert(recommendation)
                    print("Inserted PersistedRecommendation: \(recommendation.title)")
                }
                results.insights.forEach {
                    let insight = PersistedInsight(userID: userID, title: $0.title, details: $0.details, impact: $0.impact)
                    modelContext.insert(insight)
                    print("Inserted PersistedInsight: \(insight.title)")
                }
            }
            
            try modelContext.save()
            print("SwiftData save completed successfully for userID: \(userID) at \(Date())")
        } catch {
            print("SwiftData save failed for userID: \(userID): \(error.localizedDescription)")
            throw HealthAnalysisError.saveError("Failed to save to SwiftData: \(error.localizedDescription)")
        }
        
        let descriptors: [Any] = [
            FetchDescriptor<PersistedMedicinePattern>(
                predicate: #Predicate { $0.userID == userID }
            ),
            FetchDescriptor<PersistedVitalPattern>(
                predicate: #Predicate { $0.userID == userID }
            ),
            FetchDescriptor<PersistedSpike>(
                predicate: #Predicate { $0.userID == userID }
            ),
            FetchDescriptor<PersistedRecommendation>(
                predicate: #Predicate { $0.userID == userID }
            ),
            FetchDescriptor<PersistedInsight>(
                predicate: #Predicate { $0.userID == userID }
            )
        ]
        for descriptor in descriptors {
            if let medicineDescriptor = descriptor as? FetchDescriptor<PersistedMedicinePattern> {
                let objects = try modelContext.fetch(medicineDescriptor)
                print("Verified: \(objects.count) PersistedMedicinePattern objects saved for userID: \(userID)")
            } else if let vitalDescriptor = descriptor as? FetchDescriptor<PersistedVitalPattern> {
                let objects = try modelContext.fetch(vitalDescriptor)
                print("Verified: \(objects.count) PersistedVitalPattern objects saved for userID: \(userID)")
            } else if let spikeDescriptor = descriptor as? FetchDescriptor<PersistedSpike> {
                let objects = try modelContext.fetch(spikeDescriptor)
                print("Verified: \(objects.count) PersistedSpike objects saved for userID: \(userID)")
            } else if let recommendationDescriptor = descriptor as? FetchDescriptor<PersistedRecommendation> {
                let objects = try modelContext.fetch(recommendationDescriptor)
                print("Verified: \(objects.count) PersistedRecommendation objects saved for userID: \(userID)")
            } else if let insightDescriptor = descriptor as? FetchDescriptor<PersistedInsight> {
                let objects = try modelContext.fetch(insightDescriptor)
                print("Verified: \(objects.count) PersistedInsight objects saved for userID: \(userID)")
            }
        }
    }
}

// MARK: - Extension for Date
extension Date {
    func combined(with time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: self)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.second = timeComponents.second
        return calendar.date(from: combinedComponents) ?? self
    }
}

// MARK: - SmartHealthAnalyticsView
struct SmartHealthAnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    var authManager: AuthManager
    
    @Query private var medicines: [Medicine]
    @Query private var vitalReadings: [VitalReading]
    @Query private var reminders: [Reminder]
    @Query private var persistedMedicinePatterns: [PersistedMedicinePattern]
    @Query private var persistedVitalPatterns: [PersistedVitalPattern]
    @Query private var persistedSpikes: [PersistedSpike]
    @Query private var persistedRecommendations: [PersistedRecommendation]
    @Query private var persistedInsights: [PersistedInsight]
    
    @State private var analysisResults: HealthAnalysisResults?
    @State private var isLoadingAnalysis = false
    @State private var analysisError: String?
    
    private var analyticsProcessor: GeminiHealthAnalyticsProcessor {
        GeminiHealthAnalyticsProcessor(authManager: authManager, modelContext: modelContext)
    }
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    init(authManager: AuthManager) {
        self.authManager = authManager
        if let userID = authManager.currentUserUID {
            _medicines = Query(filter: #Predicate { $0.userSettings?.userID == userID })
            _vitalReadings = Query(filter: #Predicate { $0.userSettings?.userID == userID })
            _reminders = Query(filter: #Predicate { $0.userSettings?.userID == userID })
            _persistedMedicinePatterns = Query(filter: #Predicate { $0.userID == userID })
            _persistedVitalPatterns = Query(filter: #Predicate { $0.userID == userID })
            _persistedSpikes = Query(filter: #Predicate { $0.userID == userID })
            _persistedRecommendations = Query(filter: #Predicate { $0.userID == userID })
            _persistedInsights = Query(filter: #Predicate { $0.userID == userID })
        } else {
            _medicines = Query()
            _vitalReadings = Query()
            _reminders = Query()
            _persistedMedicinePatterns = Query()
            _persistedVitalPatterns = Query()
            _persistedSpikes = Query()
            _persistedRecommendations = Query()
            _persistedInsights = Query()
        }
    }
    
    private var userSpecificResults: HealthAnalysisResults? {
        guard let userID = authManager.currentUserUID else {
            print("No userID found in userSpecificResults at \(Date())")
            return nil
        }
        
        let userMedicinePatterns = persistedMedicinePatterns.filter { $0.userID == userID }.map {
            MedicinePattern(medicineName: $0.medicineName, patternDescription: $0.patternDescription, severity: $0.severity)
        }
        let userVitalPatterns = persistedVitalPatterns.filter { $0.userID == userID && !$0.isDaily }.map {
            VitalPattern(vitalType: $0.vitalType, sugarReadingType: $0.sugarReadingType, patternDescription: $0.patternDescription, trend: $0.trend, averageValue: $0.averageValue)
        }
        let userDailyPatterns = persistedVitalPatterns.filter { $0.userID == userID && $0.isDaily }.map {
            VitalPattern(vitalType: $0.vitalType, sugarReadingType: $0.sugarReadingType, patternDescription: $0.patternDescription, trend: $0.trend, averageValue: $0.averageValue)
        }
        let userSpikes = persistedSpikes.filter { $0.userID == userID }.map {
            Spike(type: $0.type, sugarReadingType: $0.sugarReadingType, value: $0.value, time: $0.time, context: $0.context)
        }
        let userRecommendations = persistedRecommendations.filter { $0.userID == userID }.map {
            Recommendation(title: $0.title, details: $0.details, category: $0.category)
        }
        let userInsights = persistedInsights.filter { $0.userID == userID }.map {
            Insight(title: $0.title, details: $0.details, impact: $0.impact)
        }
        
        let results = HealthAnalysisResults(
            medicinePatterns: userMedicinePatterns,
            vitalPatterns: userVitalPatterns,
            spikes: userSpikes,
            recommendations: userRecommendations,
            insights: userInsights,
            dailyPatterns: userDailyPatterns
        )
        
        print("Fetched userSpecificResults for userID: \(userID) at \(Date()): medicinePatterns=\(results.medicinePatterns.count), vitalPatterns=\(results.vitalPatterns.count), dailyPatterns=\(results.dailyPatterns.count), spikes=\(results.spikes.count), recommendations=\(results.recommendations.count), insights=\(results.insights.count)")
        
        return results.isEmpty ? nil : results
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI-powered pattern analysis & ML predictions")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.7))
                        Spacer().frame(height: 10)
                        HStack(spacing: 8) {
                            Image(systemName: "brain.head.profile")
                                .font(.body)
                                .foregroundColor(.purple)
                            Text("Advanced ML Analysis")
                                .font(.footnote)
                                .fontWeight(.medium)
                                .foregroundColor(.purple)
                        }
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    summaryCardsSection
                    
                    analyticsContentSection
                }
                .padding(.bottom, 90)
            }
            .navigationTitle("Smart Health Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("Refresh Analytics tapped at \(Date())!")
                        performHealthAnalysis()
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .accessibilityIdentifier("refresh")
                }
            }
            .onAppear {
                print("SmartHealthAnalyticsView appeared at \(Date())")
                if let results = userSpecificResults {
                    analysisResults = results
                    print("Loaded persisted results on appear: \(results.medicinePatterns.count) medicine patterns, \(results.vitalPatterns.count) vital patterns, \(results.dailyPatterns.count) daily patterns, \(results.spikes.count) spikes, \(results.recommendations.count) recommendations, \(results.insights.count) insights")
                } else {
                    print("No persisted results found on appear for userID: \(authManager.currentUserUID ?? "nil")")
                    performHealthAnalysis()
                }
            }
        }
    }
    
    private var summaryCardsSection: some View {
        Group {
            if isLoadingAnalysis {
                ProgressView("Analyzing your health data...")
                    .padding()
                    .foregroundColor(.purple)
            } else if let results = analysisResults, !results.isEmpty {
                LazyVGrid(columns: columns, spacing: 15) {
                    CustomCard(
                        borderColor: .purple.opacity(0.2),
                        gradient: LinearGradient(colors: [.purple.opacity(0.05), .purple.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    ) {
                        CustomCardContent(paddingValue: 10) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\((results.insights.count + results.recommendations.count))")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.purple.opacity(0.7))
                                    Text("Advanced ML Analysis")
                                        .font(.caption)
                                        .foregroundColor(.purple.opacity(0.6))
                                }
                                Spacer()
                                Circle()
                                    .fill(.purple.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "brain.head.profile")
                                            .font(.body)
                                            .foregroundColor(.purple.opacity(0.7))
                                    )
                            }
                        }
                    }
                    
                    CustomCard(
                        borderColor: .orange.opacity(0.2),
                        gradient: LinearGradient(colors: [.orange.opacity(0.05), .orange.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    ) {
                        CustomCardContent(paddingValue: 10) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(results.medicinePatterns.count)")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange.opacity(0.7))
                                    Text("Medicine Patterns")
                                        .font(.caption)
                                        .foregroundColor(.orange.opacity(0.6))
                                }
                                Spacer()
                                Circle()
                                    .fill(.orange.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "pills.fill")
                                            .font(.body)
                                            .foregroundColor(.orange.opacity(0.7))
                                    )
                            }
                        }
                    }
                    
                    CustomCard(
                        borderColor: .red.opacity(0.2),
                        gradient: LinearGradient(colors: [.red.opacity(0.05), .red.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    ) {
                        CustomCardContent(paddingValue: 10) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(results.spikes.count)")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.red.opacity(0.7))
                                    Text("Unusual Spikes")
                                        .font(.caption)
                                        .foregroundColor(.red.opacity(0.6))
                                }
                                Spacer()
                                Circle()
                                    .fill(.red.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.body)
                                            .foregroundColor(.red.opacity(0.7))
                                    )
                            }
                        }
                    }
                    
                    CustomCard(
                        borderColor: .blue.opacity(0.2),
                        gradient: LinearGradient(colors: [.blue.opacity(0.05), .blue.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    ) {
                        CustomCardContent(paddingValue: 10) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(results.dailyPatterns.count)")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue.opacity(0.7))
                                    Text("Daily BP/Sugar Patterns")
                                        .font(.caption)
                                        .foregroundColor(.blue.opacity(0.6))
                                }
                                Spacer()
                                Circle()
                                    .fill(.blue.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "chart.line.uptrend.xyaxis")
                                            .font(.body)
                                            .foregroundColor(.blue.opacity(0.7))
                                    )
                            }
                        }
                    }
                    
//                    CustomCard(
//                        borderColor: .green.opacity(0.2),
//                        gradient: LinearGradient(colors: [.green.opacity(0.05), .green.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
//                    ) {
//                        CustomCardContent(paddingValue: 10) {
//                            HStack(alignment: .center) {
//                                VStack(alignment: .leading) {
//                                    Text("\(results.recommendations.count)")
//                                        .font(.title)
//                                        .fontWeight(.bold)
//                                        .foregroundColor(.green.opacity(0.7))
//                                    Text("Smart Recommendations")
//                                        .font(.caption)
//                                        .foregroundColor(.green.opacity(0.6))
//                                }
//                                Spacer()
//                                Circle()
//                                    .fill(.green.opacity(0.2))
//                                    .frame(width: 40, height: 40)
//                                    .overlay(
//                                        Image(systemName: "lightbulb.fill")
//                                            .font(.body)
//                                            .foregroundColor(.green.opacity(0.7))
//                                    )
//                            }
//                        }
//                    }
                }
                .padding(.horizontal)
            } else if let error = analysisError {
                VStack {
                    Image(systemName: "xmark.octagon.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.red)
                        .padding(.bottom, 5)
                    Text("Analysis Error")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Retry Analysis") {
                        print("Retry Analysis tapped at \(Date())")
                        performHealthAnalysis()
                    }
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            } else {
                ContentUnavailableView(
                    "No Data to Analyze",
                    systemImage: "chart.bar.doc.horizontal",
                    description: Text("Please add some medicine records, vital readings, or reminders to generate insights.")
                )
                .padding()
            }
        }
    }
    
    private var analyticsContentSection: some View {
        Group {
            if let results = analysisResults {
                AnalyticsSectionView(title: "Medicine Adherence Patterns", icon: "pill.fill", tint: .blue) {
                    if results.medicinePatterns.isEmpty {
                        Text("No significant medicine patterns detected.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(results.medicinePatterns) { pattern in
                            PatternCardView(title: pattern.medicineName, description: pattern.patternDescription, severity: pattern.severity, tintColor: .blue)
                        }
                    }
                }
                
                AnalyticsSectionView(title: "Vital Signs Trends", icon: "heart.fill", tint: .red) {
                    if results.vitalPatterns.isEmpty {
                        Text("No vital trends detected.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(results.vitalPatterns) { pattern in
                            PatternCardView(
                                title: pattern.vitalType + (pattern.sugarReadingType != nil ? " (\(pattern.sugarReadingType!))" : ""),
                                description: pattern.patternDescription,
                                severity: pattern.trend,
                                tintColor: .red
                            )
                        }
                    }
                }
                
                AnalyticsSectionView(title: "Daily BP/Sugar Patterns", icon: "chart.line.uptrend.xyaxis", tint: .blue) {
                    if results.dailyPatterns.isEmpty {
                        Text("No daily patterns detected for today.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(results.dailyPatterns) { pattern in
                            PatternCardView(
                                title: pattern.vitalType + (pattern.sugarReadingType != nil ? " (\(pattern.sugarReadingType!))" : ""),
                                description: pattern.patternDescription,
                                severity: pattern.trend,
                                tintColor: .blue
                            )
                        }
                    }
                }
                
                AnalyticsSectionView(title: "Health Spikes & Anomalies", icon: "bolt.fill", tint: .orange) {
                    if results.spikes.isEmpty {
                        Text("No major spikes or anomalies detected.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(results.spikes) { spike in
                            SpikeCardView(
                                type: spike.type + (spike.sugarReadingType != nil ? " (\(spike.sugarReadingType!))" : ""),
                                value: spike.value,
                                time: spike.time,
                                context: spike.context,
                                tintColor: .orange
                            )
                        }
                    }
                }
                
                AnalyticsSectionView(title: "Personalized Recommendations", icon: "lightbulb.fill", tint: .green) {
                    if results.recommendations.isEmpty {
                        Text("No new recommendations at this time.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(results.recommendations) { recommendation in
                            RecommendationCardView(title: recommendation.title, description: recommendation.details, category: recommendation.category, tintColor: .green)
                        }
                    }
                }
                
                AnalyticsSectionView(title: "AI Insights", icon: "sparkles", tint: .purple) {
                    if results.insights.isEmpty {
                        Text("No specific AI insights generated.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(results.insights) { insight in
                            InsightCardView(title: insight.title, description: insight.details, impact: insight.impact, tintColor: .purple)
                        }
                    }
                }
            }
        }
    }
    
    private func performHealthAnalysis() {
        guard let userID = authManager.currentUserUID else {
            print("No authenticated user found at \(Date())")
            analysisError = "No authenticated user found."
            isLoadingAnalysis = false
            analysisResults = nil
            return
        }
        
        isLoadingAnalysis = true
        analysisError = nil
        analysisResults = nil
        
        Task {
            do {
                let userMedicines = medicines.filter { $0.userSettings?.userID == userID }
                let userVitalReadings = vitalReadings.filter { $0.userSettings?.userID == userID }
                let userReminders = reminders.filter { $0.userSettings?.userID == userID }
                
                print("Fetching data for userID: \(userID) at \(Date()): \(userMedicines.count) medicines, \(userVitalReadings.count) vital readings, \(userReminders.count) reminders")
                
                if userMedicines.isEmpty && userVitalReadings.isEmpty && userReminders.isEmpty {
                    DispatchQueue.main.async {
                        self.isLoadingAnalysis = false
                        self.analysisResults = HealthAnalysisResults(
                            medicinePatterns: [], vitalPatterns: [], spikes: [], recommendations: [], insights: [], dailyPatterns: []
                        )
                        print("No data to analyze for userID: \(userID) at \(Date())")
                    }
                    return
                }
                
                let results = try await analyticsProcessor.analyzeHealthData(
                    medicines: userMedicines,
                    vitalReadings: userVitalReadings,
                    reminders: userReminders,
                    currentDate: Date()
                )
                
                DispatchQueue.main.async {
                    self.analysisResults = results
                    self.isLoadingAnalysis = false
                    print("Analysis completed at \(Date()): \(results.medicinePatterns.count) medicine patterns, \(results.vitalPatterns.count) vital patterns, \(results.dailyPatterns.count) daily patterns, \(results.spikes.count) spikes, \(results.recommendations.count) recommendations, \(results.insights.count) insights")
                }
            } catch let error as GeminiHealthAnalyticsProcessor.HealthAnalysisError {
                DispatchQueue.main.async {
                    print("Health Analysis Error at \(Date()): \(error.localizedDescription)")
                    self.analysisError = error.localizedDescription
                    self.isLoadingAnalysis = false
                    self.analysisResults = nil
                }
            } catch {
                DispatchQueue.main.async {
                    print("Unexpected Error at \(Date()): \(error.localizedDescription)")
                    self.analysisError = "An unexpected error occurred: \(error.localizedDescription)"
                    self.isLoadingAnalysis = false
                    self.analysisResults = nil
                }
            }
        }
    }
}

// MARK: - UI Components
struct AnalyticsSectionView<Content: View>: View {
    let title: String
    let icon: String
    let tint: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(tint)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal)
            VStack(spacing: 10) { content }
        }
        .padding(.vertical, 10)
        .background(.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        .padding(.horizontal)
    }
}

struct PatternCardView: View {
    let title: String
    let description: String
    let severity: String
    let tintColor: Color
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "chart.bar.fill")
                .foregroundColor(tintColor)
                .font(.title2)
                .padding(.trailing, 5)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text(severity)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(tintColor.opacity(0.2))
                .cornerRadius(5)
                .foregroundColor(tintColor)
        }
        .padding(12)
        .background(tintColor.opacity(0.05))
        .cornerRadius(10)
        .padding(.horizontal, 5)
    }
}

struct SpikeCardView: View {
    let type: String
    let value: String
    let time: Date
    let context: String
    let tintColor: Color
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(tintColor)
                .font(.title2)
                .padding(.trailing, 5)
            VStack(alignment: .leading, spacing: 5) {
                Text("\(type) Spike: \(value)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Detected at \(time.formatted(date: .omitted, time: .shortened)) - \(context)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text("Alert")
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.red.opacity(0.2))
                .cornerRadius(5)
                .foregroundColor(.red)
        }
        .padding(12)
        .background(tintColor.opacity(0.05))
        .cornerRadius(10)
        .padding(.horizontal, 5)
    }
}

struct RecommendationCardView: View {
    let title: String
    let description: String
    let category: String
    let tintColor: Color
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(tintColor)
                .font(.title2)
                .padding(.trailing, 5)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text(category)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(tintColor.opacity(0.2))
                .cornerRadius(5)
                .foregroundColor(tintColor)
        }
        .padding(12)
        .background(tintColor.opacity(0.05))
        .cornerRadius(10)
        .padding(.horizontal, 5)
    }
}

struct InsightCardView: View {
    let title: String
    let description: String
    let impact: String
    let tintColor: Color
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "sparkles")
                .foregroundColor(tintColor)
                .font(.title2)
                .padding(.trailing, 5)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text(impact)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(tintColor.opacity(0.2))
                .cornerRadius(5)
                .foregroundColor(tintColor)
        }
        .padding(12)
        .background(tintColor.opacity(0.05))
        .cornerRadius(10)
        .padding(.horizontal, 5)
    }
}

struct CustomCard<Content: View>: View {
    let borderColor: Color
    let gradient: LinearGradient
    @ViewBuilder let content: Content
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(gradient)
            RoundedRectangle(cornerRadius: 15)
                .stroke(borderColor, lineWidth: 1)
            content
        }
        .frame(height: 100)
    }
}

struct CustomCardContent<Content: View>: View {
    let paddingValue: CGFloat
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading) {
            content
        }
        .padding(paddingValue)
    }
}
