
import SwiftUI

// MARK: - Data Models (UNCHANGED - keep these at the top of your file)
struct MedicinePattern: Identifiable {
    let id = UUID()
    let medicineName: String
    let adherenceRate: Int
    let suggestions: [String]
}

struct VitalPattern: Identifiable {
    let id = UUID()
    let type: String // e.g., "blood pressure", "blood sugar"
    let predictions: VitalPrediction
    let trends: VitalTrends
}

struct VitalPrediction: Codable {
    let nextWeekTrend: String // e.g., "stable", "up", "down"
    let confidence: Int // percentage
}

struct VitalTrends: Codable {
    let timePatterns: [String] // e.g., "Elevated on weekends", "Morning spikes"
}

struct Spike: Identifiable {
    let id = UUID()
    let message: String
    let severity: String // "high" or "medium"
    let date: Date
}

struct Recommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let priority: String // "high", "medium", "low"
    let type: String // "medicine", "activity", "diet"
    var action: String? // Optional action text
}

struct Insight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let type: String // "anomaly", "correlation", "prediction"
    let confidence: Int
    let trend: String // "up", "down", "stable"
}

struct PatternAnalysis {
    var medicinePatterns: [MedicinePattern]
    var vitalPatterns: [VitalPattern]
    var spikes: [Spike]
    var predictions: [Prediction]
}

struct Prediction: Identifiable {
    let id = UUID()
    let message: String
    let value: String // e.g., "125/80"
}

// MARK: - Helper Views (UNCHANGED - CustomCard, CustomCardContent, etc.)
// Simplified Card for SwiftUI
struct CustomCard<Content: View>: View {
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

// Card Content for padding
struct CustomCardContent<Content: View>: View {
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

// Card Header for padding and border
struct CustomCardHeader<Content: View>: View {
    let content: Content
    var paddingBottom: CGFloat = 12 // Corresponds to pb-3 in Tailwind
    var showBorder: Bool = false
    
    init(paddingBottom: CGFloat = 12, showBorder: Bool = false, @ViewBuilder content: () -> Content) {
        self.paddingBottom = paddingBottom
        self.showBorder = showBorder
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) { // Using VStack to allow for a bottom border
            content
                .padding(.bottom, paddingBottom)
            if showBorder {
                Divider() // A simple divider
            }
        }
        .padding(.horizontal, 16) // Default horizontal padding for CardHeader
        .padding(.top, 16) // Default top padding for CardHeader
    }
}


// Card Title
struct CustomCardTitle: View {
    let text: String
    var fontSize: CGFloat = 18 // text-lg
    var textColor: Color = .primary
    
    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundColor(textColor)
    }
}

// Card Description
struct CustomCardDescription: View {
    let text: String
    var textColor: Color = .gray // Assuming text-gray-600
    
    var body: some View {
        Text(text)
            .font(.subheadline) // text-sm
            .foregroundColor(textColor)
    }
}

// Badge
struct CustomBadge: View {
    let text: String
    var variant: String = "secondary" // "destructive", "outline"
    
    var body: some View {
        Text(text)
            .font(.caption2) // text-xs
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


// MARK: - Icon Helpers (UNCHANGED)
func getTypeIcon(type: String) -> Image {
    switch type {
    case "medicine": return Image(systemName: "pills.fill")
    case "activity": return Image(systemName: "figure.walk")
    case "diet": return Image(systemName: "fork.knife")
    default: return Image(systemName: "questionmark.circle.fill")
    }
}

func getPriorityColor(priority: String) -> Color {
    switch priority {
    case "high": return Color.red.opacity(0.15)
    case "medium": return Color.orange.opacity(0.15)
    case "low": return Color.blue.opacity(0.15)
    default: return Color.gray.opacity(0.15)
    }
}

func getInsightIcon(type: String) -> Image {
    switch type {
    case "anomaly": return Image(systemName: "exclamationmark.triangle.fill") // AlertTriangle
    case "correlation": return Image(systemName: "link") // Link
    case "prediction": return Image(systemName: "lightbulb.fill") // Bulb
    default: return Image(systemName: "info.circle.fill")
    }
}

// MARK: - New Dedicated Sub-View Structs

struct MedicinePatternRow: View {
    let pattern: MedicinePattern

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(pattern.medicineName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.orange.opacity(0.8))
            Text("Adherence Rate: \(pattern.adherenceRate)%")
                .font(.caption)
                .foregroundColor(Color.orange.opacity(0.7))
                .padding(.bottom, 4)

            ForEach(pattern.suggestions, id: \.self) { suggestion in
                Text("• \(suggestion)")
                    .font(.caption)
                    .foregroundColor(Color.orange.opacity(0.7))
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(8)
    }
}

struct VitalPatternRow: View {
    let pattern: VitalPattern

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(pattern.type) Pattern Analysis")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.blue.opacity(0.8))
                .textCase(.uppercase)
            Text("Next Week Prediction: \(pattern.predictions.nextWeekTrend.replacingOccurrences(of: "_", with: " "))")
                .font(.caption)
                .foregroundColor(Color.blue.opacity(0.7))
            CustomBadge(text: "\(pattern.predictions.confidence)% confidence", variant: "outline")
                .padding(.leading, 8)
                .padding(.bottom, 4)

            ForEach(pattern.trends.timePatterns, id: \.self) { timePattern in
                Text("• \(timePattern)")
                    .font(.caption)
                    .foregroundColor(Color.blue.opacity(0.7))
            }
        }
        .padding(16)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
}

struct SpikeRow: View {
    let spike: Spike

    var body: some View {
        VStack(alignment: .leading) {
            Text(spike.message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(spike.severity == "high" ? Color.red.opacity(0.8) : Color.yellow.opacity(0.8))
            Text(spike.date, style: .date)
                .font(.caption2)
                .foregroundColor(spike.severity == "high" ? Color.red.opacity(0.6) : Color.yellow.opacity(0.6))
        }
        .padding(12)
        .background(spike.severity == "high" ? Color.red.opacity(0.1) : Color.yellow.opacity(0.1))
        .cornerRadius(8)
    }
}



struct InsightRow: View {
    let insight: Insight

    var body: some View {
        CustomCard(backgroundColor: .white) {
            VStack(alignment: .leading) {
                CustomCardHeader(paddingBottom: 12) {
                    HStack(alignment: .top) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.indigo.opacity(0.1))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    getInsightIcon(type: insight.type)
                                        .font(.body)
                                        .foregroundColor(Color.indigo.opacity(0.7))
                                )
                            VStack(alignment: .leading) {
                                CustomCardTitle(text: insight.title, fontSize: 18, textColor: Color.indigo.opacity(0.7))
                                CustomCardDescription(text: insight.description)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            CustomBadge(text: "\(insight.confidence)% Confidence", variant: "outline")
                            HStack(spacing: 4) {
                                Image(systemName: insight.trend == "up" ? "chart.line.uptrend.xyaxis" : (insight.trend == "down" ? "chart.line.downtrend.xyaxis" : "equal"))
                                    .font(.caption2)
                                    .rotationEffect(insight.trend == "down" ? .degrees(180) : .zero)
                                Text(insight.trend.uppercased())
                                    .font(.caption2)
                            }
                            .foregroundColor(
                                insight.trend == "up" ? .red :
                                insight.trend == "down" ? .green : .gray
                            )
                        }
                    }
                }
            }
        }
    }
}


// MARK: - SmartHealthAnalyticsView (Refactored for auto-load and simplified UI)
struct SmartHealthAnalyticsView: View {
    @State private var isLoading: Bool = true // Start as loading to auto-trigger analysis
    @State private var patternAnalysis: PatternAnalysis? = nil // Holds the analysis results
    @State private var activeRecommendations: [Recommendation] = []
    @State private var insights: [Insight] = []

    // Simulate ML analysis - now called automatically on appear
    func generateAnalytics() {
        isLoading = true
        // Simulate a network request or heavy computation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.patternAnalysis = PatternAnalysis(
                medicinePatterns: [
                    MedicinePattern(medicineName: "Metformin", adherenceRate: 75, suggestions: ["Consider daily reminder for morning dose.", "Review schedule with doctor."]),
                    MedicinePattern(medicineName: "Lisinopril", adherenceRate: 90, suggestions: ["Good adherence, keep it up!"])
                ],
                vitalPatterns: [
                    VitalPattern(type: "Blood Pressure", predictions: VitalPrediction(nextWeekTrend: "stable", confidence: 85), trends: VitalTrends(timePatterns: ["Slightly higher readings on Mondays.", "Generally stable after medication."])),
                    VitalPattern(type: "Blood Sugar", predictions: VitalPrediction(nextWeekTrend: "up", confidence: 70), trends: VitalTrends(timePatterns: ["Spikes observed after evening meals.", "Higher readings on weekends."]))
                ],
                spikes: [
                    Spike(message: "High blood pressure spike detected.", severity: "high", date: Date().addingTimeInterval(-86400 * 3)), // 3 days ago
                    Spike(message: "Unusual blood sugar reading.", severity: "medium", date: Date().addingTimeInterval(-86400 * 7)) // 7 days ago
                ],
                predictions: [ // Example predictions
                    Prediction(message: "Predicted stable BP next week.", value: "125/80"),
                    Prediction(message: "Potential blood sugar increase.", value: "150")
                ]
            )

            self.activeRecommendations = [
                Recommendation(title: "Medication Reminder Check", description: "Review and adjust your Metformin reminders for better consistency.", priority: "high", type: "medicine", action: "Adjust Reminders"),
                Recommendation(title: "Evening Meal Review", description: "Analyze your evening meal choices to manage blood sugar spikes.", priority: "medium", type: "diet", action: "View Diet Log"),
                Recommendation(title: "Weekend Activity Boost", description: "Increase physical activity on weekends to help regulate blood sugar.", priority: "low", type: "activity", action: "Set Activity Goal")
            ]

            self.insights = [
                Insight(title: "Morning BP Anomaly", description: "Your blood pressure readings consistently show a slight elevation during early morning hours.", type: "anomaly", confidence: 92, trend: "up"),
                Insight(title: "Diet-Sugar Correlation", description: "A strong correlation detected between high-carb evening meals and subsequent blood sugar spikes.", type: "correlation", confidence: 88, trend: "up"),
                Insight(title: "Future BP Stability", description: "Based on recent trends, your blood pressure is predicted to remain stable next month with current regimen.", type: "prediction", confidence: 80, trend: "stable")
            ]

            isLoading = false
        }
    }

    // Simulate accepting a recommendation
    func acceptRecommendation(id: UUID) {
        if let index = activeRecommendations.firstIndex(where: { $0.id == id }) {
            print("Accepted recommendation: \(activeRecommendations[index].title)")
            // Remove the recommendation or mark it as accepted
            activeRecommendations.remove(at: index)
        }
    }

    // Simulate dismissing a recommendation
    func dismissRecommendation(id: UUID) {
        if let index = activeRecommendations.firstIndex(where: { $0.id == id }) {
            print("Dismissed recommendation: \(activeRecommendations[index].title)")
            // Remove the recommendation
            activeRecommendations.remove(at: index)
        }
    }

    // MARK: - Sub-views as Computed Properties (updated to use new structs)

    private var analyticsHeaderView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                // Header removed as it's now a Navigation Title
                Text("AI-powered pattern analysis & ML predictions")
                    .font(.subheadline)
                    .foregroundColor(.gray.opacity(0.7))
                Spacer()
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
            
            
        }
    }

    private var dashboardCardsView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
            // Smart Recommendations Card
            CustomCard(
                borderColor: Color.purple.opacity(0.2),
                gradient: LinearGradient(colors: [Color.purple.opacity(0.05), Color.purple.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
            ) {
                CustomCardContent(paddingValue: 10) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(activeRecommendations.count)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color.purple.opacity(0.7))
                            Text("Smart Recommendations")
                                .font(.caption)
                                .foregroundColor(Color.purple.opacity(0.6))
                        }
                        Spacer()
                        Circle()
                            .fill(Color.purple.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "brain.head.profile")
                                    .font(.body)
                                    .foregroundColor(Color.purple.opacity(0.7))
                            )
                    }
                }
            }

            // Medicine Patterns Card
            CustomCard(
                borderColor: Color.orange.opacity(0.2),
                gradient: LinearGradient(colors: [Color.orange.opacity(0.05), Color.orange.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
            ) {
                CustomCardContent(paddingValue: 10) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(patternAnalysis?.medicinePatterns.count ?? 0)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color.orange.opacity(0.7))
                            Text("Medicine Patterns")
                                .font(.caption)
                                .foregroundColor(Color.orange.opacity(0.6))
                        }
                        Spacer()
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "pills.fill")
                                    .font(.body)
                                    .foregroundColor(Color.orange.opacity(0.7))
                            )
                    }
                }
            }

            // Unusual Spikes Card
            CustomCard(
                borderColor: Color.red.opacity(0.2),
                gradient: LinearGradient(colors: [Color.red.opacity(0.05), Color.red.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
            ) {
                CustomCardContent(paddingValue: 10) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(patternAnalysis?.spikes.count ?? 0)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color.red.opacity(0.7))
                            Text("Unusual Spikes")
                                .font(.caption)
                                .foregroundColor(Color.red.opacity(0.6))
                        }
                        Spacer()
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.body)
                                    .foregroundColor(Color.red.opacity(0.7))
                            )
                    }
                }
            }

            // ML Predictions Card
            CustomCard(
                borderColor: Color.green.opacity(0.2),
                gradient: LinearGradient(colors: [Color.green.opacity(0.05), Color.green.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
            ) {
                CustomCardContent(paddingValue: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(patternAnalysis?.predictions.count ?? 0)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color.green.opacity(0.7))
                            Text("ML Predictions")
                                .font(.caption)
                                .foregroundColor(Color.green.opacity(0.6))
                        }
                        Spacer()
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.body)
                                    .foregroundColor(Color.green.opacity(0.7))
                            )
                    }
                }
            }
        }
    }

    private var patternAnalysisResultsView: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Medicine Pattern Analysis
            if let patternAnalysis = patternAnalysis, patternAnalysis.medicinePatterns.count > 0 {
                CustomCard(backgroundColor: .white, shadowColor: .clear) {
                    VStack(alignment: .leading) {
                        CustomCardHeader {
                            HStack(spacing: 8) {
                                Image(systemName: "pills.fill")
                                    .font(.body)
                                    .foregroundColor(Color.orange.opacity(0.7))
                                CustomCardTitle(text: "Medicine Adherence Patterns", textColor: Color.orange.opacity(0.7))
                            }
                        }
                        CustomCardContent {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(patternAnalysis.medicinePatterns) { pattern in
                                    MedicinePatternRow(pattern: pattern) // Using new struct
                                }
                            }
                        }
                    }
                    .overlay(
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: 4)
                            .cornerRadius(4),
                        alignment: .leading
                    )
                }
            }

            // Vital Signs Analysis
            if let patternAnalysis = patternAnalysis, patternAnalysis.vitalPatterns.count > 0 {
                CustomCard(backgroundColor: .white, shadowColor: .clear) {
                    VStack(alignment: .leading) {
                        CustomCardHeader {
                            HStack(spacing: 8) {
                                Image(systemName: "waveform.path")
                                    .font(.body)
                                    .foregroundColor(Color.blue.opacity(0.7))
                                CustomCardTitle(text: "Vital Signs Analysis", textColor: Color.blue.opacity(0.7))
                            }
                        }
                        CustomCardContent {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(patternAnalysis.vitalPatterns) { pattern in
                                    VitalPatternRow(pattern: pattern) // Using new struct
                                }
                            }
                        }
                    }
                    .overlay(
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 4)
                            .cornerRadius(4),
                        alignment: .leading
                    )
                }
            }

            // Unusual Spikes Alert
            if let patternAnalysis = patternAnalysis, patternAnalysis.spikes.count > 0 {
                CustomCard(backgroundColor: .white, shadowColor: .clear) {
                    VStack(alignment: .leading) {
                        CustomCardHeader {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.body)
                                    .foregroundColor(Color.red.opacity(0.7))
                                CustomCardTitle(text: "Unusual Spikes Detected", textColor: Color.red.opacity(0.7))
                            }
                        }
                        CustomCardContent {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(patternAnalysis.spikes) { spike in
                                    SpikeRow(spike: spike) // Using new struct
                                }
                            }
                        }
                    }
                    .overlay(
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 4)
                            .cornerRadius(4),
                        alignment: .leading
                    )
                }
            }
        }
    }



    private var insightsListView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Health Insights")
                .font(.headline)
                .fontWeight(.semibold)
            ForEach(insights) { insight in
                InsightRow(insight: insight)
            }
        }
    }


    // MARK: - Main Body
    var body: some View {
        NavigationStack { // Added NavigationStack for the title
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    analyticsHeaderView
                    dashboardCardsView

                    if isLoading {
                        ProgressView("Analyzing Patterns...")
                            .padding()
                            .frame(maxWidth: .infinity)
                    } else if patternAnalysis != nil {
                        patternAnalysisResultsView
                    }


                    if insights.count > 0 {
                        insightsListView
                    }

                    if patternAnalysis == nil && !isLoading { // Show placeholder if no analysis loaded and not loading
                        CustomCard(backgroundColor: .white, shadowRadius: 0) {
                            VStack(spacing: 16) {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "brain.head.profile")
                                            .font(.largeTitle)
                                            .foregroundColor(Color.blue.opacity(0.7))
                                    )
                                VStack(spacing: 8) {
                                    Text("Ready for Advanced Analysis")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Text("Pattern recognition ke saath personalized insights paane ke liye analysis run karein.") // Hindi text
                                        .font(.subheadline)
                                        .foregroundColor(.gray.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 48)
                        }
                    }
                }
                .padding()
                .padding(.bottom, 80)
            }
            .background(Color.white)
            .navigationTitle("Smart Health Analytics") // Navigation Title
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                generateAnalytics() // Auto-load analytics on view appear
            }
        }
    }
}

// MARK: - Preview Provider (UNCHANGED)
struct SmartHealthAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        SmartHealthAnalyticsView()
    }
}
