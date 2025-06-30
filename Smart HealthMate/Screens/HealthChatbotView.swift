import SwiftUI

// MARK: - Data Models
// ChatMessages: User ke asal naam ko barqarar rakhte hue
struct ChatMessages: Identifiable, Equatable {
    let id = UUID() // Identifiable ke liye UUID istemal karein
    let type: MessageType
    let message: String
    let timestamp: Date
    var category: MessageCategory?

    enum MessageType: String, Codable {
        case user
        case bot
    }

    enum MessageCategory: String, Codable {
        case symptom
        case medicine
        case vitals
        case general
    }
}

// Health Context for Gemini API prompt
struct HealthContext: Codable {
    let medicines: [MedicineContext]
    let vitals: VitalsContext
    let adherence: Int
}

struct MedicineContext: Codable {
    let name: String
    let purpose: String
    let adherence: Int
}

struct VitalsContext: Codable {
    let bp: BPContext
    let sugar: SugarContext
}

struct BPContext: Codable {
    let systolic: Int
    let diastolic: Int
}

struct SugarContext: Codable {
    let level: Int
}

// MARK: - GeminiService (API interaction ke liye Swift equivalent)
class GeminiService: ObservableObject {
    // HARDCODED API KEY: User ki faraham karda API key yahan hardcode ki gayi hai.
    // **IMPORTANT**: Agar aapko API key ka masla aa raha hai, to yahan apni valid Google Cloud API key paste karein.
    // Yeh API key Gemini API calls ke liye zaruri hai.
    private var apiKey: String = "AIzaSyDNe9gCejleY5mJM_dL_dHcHUWUYP011kU"

    // Initializer mein API key set ki gayi hai.
    init(apiKey: String = "AIzaSyDNe9gCejleY5mJM_dL_dHcHUWUYP011kU") {
        self.apiKey = apiKey
    }

    // Yeh function aap use kar sakte hain agar aap runtime mein API key badalna chahein,
    // lekin is code mein yeh zaroori nahi hai kyunki key hardcoded hai.
    func setApiKey(_ key: String) {
        self.apiKey = key
    }

    func chatWithHealthBot(_ userMessage: String, healthContext: HealthContext) async throws -> String {
        // Health context ke saath prompt tayyar karein
        let prompt = """
        Aap ek Smart HealthMate AI assistant hain. User ke health context ki buniyad par unke sawalon ka jawab dein.
        User ka Health Context:
        - Medicines: \(healthContext.medicines.map { "\($0.name) (\($0.purpose)), adherence: \($0.adherence)%" }.joined(separator: "; "))
        - Vitals: BP: \(healthContext.vitals.bp.systolic)/\(healthContext.vitals.bp.diastolic), Sugar: \(healthContext.vitals.sugar.level)
        - Overall Adherence: \(healthContext.adherence)%

        User ka Sawal: \(userMessage)

        Mukhtasar aur madadgar jawab faraham karein. Agar user symptoms ke bare mein poochta hai, toh aam mashwara dein aur doctor se mashwara karne ka sujhav dein. Agar woh medicines ke bare mein poochte hain, toh unki adherence ka hawala dein. Agar woh vitals ke bare mein poochte hain, toh unke data se context faraham karein.
        """

        // Gemini API ke liye payload tayyar karein
        let chatHistory = [
            ["role": "user", "parts": [["text": prompt]]]
        ]

        let payload: [String: Any] = ["contents": chatHistory]
        
        // API URL tayyar karein
        // Ensure that the model used is gemini-2.0-flash as it's typically used for text generation.
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)") else {
            print("ERROR: Invalid URL.")
            throw NSError(domain: "InvalidURL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL."])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("ERROR: Payload JSON serialization failed: \(error.localizedDescription)")
            throw NSError(domain: "JSONSerializationError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Request payload creation failed."])
        }

        // API call karein
        let (data, response) = try await URLSession.shared.data(for: request)

        // Debugging ke liye response print karein
        if let httpResponse = response as? HTTPURLResponse {
            print("API Response Status Code: \(httpResponse.statusCode)")
            if let responseBody = String(data: data, encoding: .utf8) {
                print("API Response Body: \(responseBody)")
            }
            
            // Check for non-200 status codes
            if httpResponse.statusCode != 200 {
                let errorDetails = String(data: data, encoding: .utf8) ?? "No response body"
                throw NSError(domain: "APIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API request failed with status code \(httpResponse.statusCode). Details: \(errorDetails)"])
            }
        }
        
        // JSON response ko parse karein
        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
            let candidates = json["candidates"] as? [[String: Any]],
            let firstCandidate = candidates.first,
            let content = firstCandidate["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]],
            let firstPart = parts.first,
            let text = firstPart["text"] as? String {
            return text
        } else {
            print("AI response parse karne mein nakam raha: \(String(data: data, encoding: .utf8) ?? "N/A")")
            throw NSError(domain: "APIParseError", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "AI response parse karne mein nakami. Ghair mutawaqqe format."
            ])
        }
    }
}


// MARK: - Reusable UI Components (Preserving user's original naming)

// Preserving user's original naming: CustomCards
struct CustomCards<Content: View>: View {
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

// Preserving user's original naming: CustomCardContents
struct CustomCardContents<Content: View>: View {
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

// Preserving user's original naming: CustomCardHeaders
struct CustomCardHeaders<Content: View>: View {
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

// Preserving user's original naming: CustomCardTitles
struct CustomCardTitles: View {
    let text: String
    var fontSize: CGFloat = 18 // text-lg
    var textColor: Color = .primary

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundColor(textColor)
    }
}

// Preserving user's original naming: CustomCardDescriptions
struct CustomCardDescriptions: View {
    let text: String
    var textColor: Color = .gray // Assuming text-gray-600

    var body: some View {
        Text(text)
            .font(.subheadline) // text-sm
            .foregroundColor(textColor)
    }
}

// Preserving user's original naming: CustomBadges
struct CustomBadges: View {
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


// ApiKeyInputViews is no longer needed as the API Key is hardcoded.
// However, if you need this component for other purposes, you can keep it separate.
// I'm removing it from the main HealthChatbotView body.

// MARK: - HealthChatbotView (Main Chatbot Screen)
struct HealthChatbotView: View {
    // Preserving user's original naming: ChatMessages
    @State private var messages: [ChatMessages] = [
        ChatMessages(type: .bot, message: "Hello! I'm your Smart HealthMate AI assistant powered by Gemini. I can help you with symptoms, medicine questions, and health insights based on your data. How can I help you today?", timestamp: Date(), category: .general)
    ]
    @State private var currentMessage: String = ""
    @State private var isTyping: Bool = false
    @StateObject private var geminiService = GeminiService() // Initialized with hardcoded key
    @State private var errorMessage: String? = nil // For displaying errors in UI

    @FocusState private var isInputFocused: Bool // To manage keyboard focus
    @Namespace private var bottomID // For scrolling to bottom of chat

    // Quick Questions (UNCHANGED)
    let quickQuestions = [
        "I have a headache",
        "Feeling dizzy today",
        "When should I take my medicine?",
        "My BP seems high",
        "I'm feeling tired"
    ]

    // MARK: - Helper Functions for UI (Icons and Colors)
    // Preserving user's original naming: ChatMessages
    private func getCategoryIcon(category: ChatMessages.MessageCategory?) -> Image {
        switch category {
        case .symptom: return Image(systemName: "exclamationmark.triangle.fill") // AlertTriangle
        case .medicine: return Image(systemName: "pill.fill") // Bot
        case .vitals: return Image(systemName: "waveform.path.ecg") // Activity
        case .general: return Image(systemName: "heart.fill") // Heart
        default: return Image(systemName: "message.fill") // MessageSquare
        }
    }

    // Preserving user's original naming: ChatMessages
    private func getCategoryColor(category: ChatMessages.MessageCategory?) -> Color {
        switch category {
        case .symptom: return Color.red.opacity(0.6) // text-red-600
        case .medicine: return Color.blue.opacity(0.6) // text-blue-600
        case .vitals: return Color.purple.opacity(0.6) // text-purple-600
        case .general: return Color.green.opacity(0.6) // text-green-600
        default: return Color.gray.opacity(0.6) // text-gray-600
        }
    }

    // Preserving user's original naming: ChatMessages
    private func getCategoryBackgroundColor(category: ChatMessages.MessageCategory?) -> Color {
        switch category {
        case .symptom: return Color.red.opacity(0.1) // bg-red-100
        case .medicine: return Color.blue.opacity(0.1) // bg-blue-100
        case .vitals: return Color.purple.opacity(0.1) // bg-purple-100
        case .general: return Color.green.opacity(0.1) // bg-green-100
        default: return Color.gray.opacity(0.1) // bg-gray-100
        }
    }

    // MARK: - Send Message Logic
    private func sendMessage() {
        guard !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Preserving user's original naming: ChatMessages
        let userMessage = ChatMessages(type: .user, message: currentMessage, timestamp: Date())
        messages.append(userMessage) // Add user message instantly
        currentMessage = "" // Clear input field
        isTyping = true
        errorMessage = nil // Clear error on new attempt

        Task {
            defer { // Use defer for code that should always run
                isTyping = false
            }

            do {
                // Mock health context - in real app, this would come from a data store (UNCHANGED)
                let healthContext = HealthContext(
                    medicines: [
                        MedicineContext(name: "Amlodipine", purpose: "Blood Pressure Control", adherence: 85),
                        MedicineContext(name: "Metformin", purpose: "Diabetes Management", adherence: 90)
                    ],
                    vitals: VitalsContext(
                        bp: BPContext(systolic: 125, diastolic: 82),
                        sugar: SugarContext(level: 140)
                    ),
                    adherence: 87
                )

                // The geminiService instance already has the hardcoded API key
                let aiResponse = try await geminiService.chatWithHealthBot(userMessage.message, healthContext: healthContext)
                
                // Determine category based on message content (simplified from JS for brevity)
                // Preserving user's original naming: ChatMessages
                var category: ChatMessages.MessageCategory = .general
                let lowerMessage = userMessage.message.lowercased()
                if lowerMessage.contains("headache") || lowerMessage.contains("pain") || lowerMessage.contains("dizzy") {
                    category = .symptom
                } else if lowerMessage.contains("medicine") || lowerMessage.contains("dose") {
                    category = .medicine
                } else if lowerMessage.contains("pressure") || lowerMessage.contains("sugar") || lowerMessage.contains("bp") {
                    category = .vitals
                }

                // Preserving user's original naming: ChatMessages
                let botMessage = ChatMessages(type: .bot, message: aiResponse, timestamp: Date(), category: category)
                messages.append(botMessage)

            } catch {
                print("Error getting AI response: \(error.localizedDescription)")
                // Preserving user's original naming: ChatMessages
                let errorMessageText: String
                if let nsError = error as? NSError, nsError.code == -1005 {
                    errorMessageText = "The network connection was lost. Please check your internet connection and try again."
                } else {
                    errorMessageText = "I'm having trouble connecting to the AI service. Error: \(error.localizedDescription). Please try again in a moment."
                }
                let errorBotMessage = ChatMessages(type: .bot, message: errorMessageText, timestamp: Date(), category: .general)
                messages.append(errorBotMessage)
                errorMessage = errorMessageText // Update UI error message
            }
        }
    }

    // MARK: - Main Body
    var body: some View {
        NavigationStack { // Added NavigationStack for the title and subheading
            GeometryReader { geometry in // Use GeometryReader to get safe area insets
                ScrollView(.vertical, showsIndicators: false) { // Make the entire view scrollable
                    VStack(alignment: .leading, spacing: 24) { // space-y-6 equivalent
                        // Subheading below the navigation title
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI-powered symptom checker and health guidance")
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .padding(.horizontal) // Apply horizontal padding here
                        
                        HStack(spacing: 8) { // gap-2
                            Image(systemName: "sparkle") // Bot icon (using a generic AI/sparkle icon) - Changed from sparkle.arkframe
                                .font(.body) // h-5 w-5
                                .foregroundColor(.blue.opacity(0.6)) // text-blue-600
                            Text("Gemini AI Assistant")
                                .font(.footnote) // text-sm font-medium
                                .fontWeight(.medium)
                                .foregroundColor(.blue.opacity(0.6)) // text-blue-600
                            Spacer() // Pushes the assistant info to the left
                        }
                        .padding(.horizontal) // Apply horizontal padding here

                        // Chat Interface Card
                        // Preserving user's original naming: CustomCards
                        CustomCards { // Using CustomCards for overall styling
                            VStack(alignment: .leading) { // Simulates Card component
                                // Preserving user's original naming: CustomCardHeaders
                                CustomCardHeaders(paddingBottom: 12) { // pb-3
                                    HStack(spacing: 8) { // gap-2
                                        Image(systemName: "message.fill") // MessageSquare icon
                                            .font(.body) // h-5 w-5
                                        // Preserving user's original naming: CustomCardTitles
                                        CustomCardTitles(text: "Health Chat", fontSize: 18) // text-lg
                                    }
                                    // Preserving user's original naming: CustomCardDescriptions
                                    CustomCardDescriptions(text: "Ask about symptoms, medications, or health patterns")
                                }
                                
                                // Preserving user's original naming: CustomCardContents
                                CustomCardContents { // space-y-4
                                    // Messages Area - SCROLL FIX APPLIED HERE
                                    ScrollViewReader { scrollViewProxy in
                                        ScrollView(.vertical, showsIndicators: false) {
                                            VStack(spacing: 12) { // space-y-3
                                                ForEach(messages) { msg in
                                                    HStack {
                                                        if msg.type == .user {
                                                            Spacer() // Push user message to the right
                                                        }
                                                        
                                                        // Preserving user's original naming: ChatMessages
                                                        VStack(alignment: msg.type == .user ? .trailing : .leading, spacing: 4) { // max-w-xs
                                                            HStack(spacing: 8) { // gap-2 mb-1
                                                                if msg.type == .user {
                                                                    Image(systemName: "person.fill") // User icon
                                                                        .font(.caption) // h-4 w-4
                                                                    Text("You")
                                                                        .font(.caption2) // text-xs font-medium
                                                                } else {
                                                                    Image(systemName: "sparkle") // Bot icon - Changed from sparkle.arkframe
                                                                        .font(.caption) // h-4 w-4
                                                                        .foregroundColor(.blue.opacity(0.6)) // text-blue-600
                                                                    Text("Gemini AI")
                                                                        .font(.caption2)
                                                                }

                                                                if msg.category != nil && msg.type == .bot {
                                                                    // Preserving user's original naming: CustomBadges
                                                                    CustomBadges(text: msg.category!.rawValue.capitalized, variant: "outline")
                                                                        .background(getCategoryBackgroundColor(category: msg.category))
                                                                        .foregroundColor(getCategoryColor(category: msg.category))
                                                                }
                                                            }
                                                            
                                                            Text(msg.message)
                                                                .font(.footnote) // text-sm
                                                                .fixedSize(horizontal: false, vertical: true) // whitespace-pre-line
                                                            
                                                            Text(msg.timestamp, formatter: Self.timeFormatter)
                                                                .font(.caption2) // text-xs
                                                                .opacity(0.7) // opacity-70 mt-1
                                                        }
                                                        .padding(12) // p-3
                                                        .background(msg.type == .user ? Color.blue.opacity(0.8) : Color.white) // bg-blue-600 : bg-white
                                                        .foregroundColor(msg.type == .user ? .white : .primary) // text-white : default
                                                        .cornerRadius(8) // rounded-lg
                                                        .shadow(color: msg.type == .bot ? .black.opacity(0.05) : .clear, radius: msg.type == .bot ? 2 : 0, x: 0, y: 1) // border shadow-sm
                                                        .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: msg.type == .user ? .trailing : .leading) // max-w-xs
                                                        
                                                        if msg.type == .bot {
                                                            Spacer() // Push bot message to the left
                                                        }
                                                    }
                                                    .id(msg.id) // Assign ID for ScrollViewReader
                                                }
                                                
                                                // Typing indicator
                                                if isTyping {
                                                    HStack {
                                                        Image(systemName: "sparkle") // Changed from sparkle.arkframe
                                                            .font(.caption)
                                                            .foregroundColor(.blue.opacity(0.6))
                                                        Text("Gemini AI")
                                                            .font(.caption2)
                                                        ProgressView()
                                                            .controlSize(.small)
                                                            .progressViewStyle(.circular)
                                                            .padding(.leading, 4)
                                                    }
                                                    .padding(12)
                                                    .background(Color.white)
                                                    .cornerRadius(8)
                                                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                                    .transition(.opacity) // Fade in/out typing indicator
                                                    .animation(.easeOut(duration: 0.3), value: isTyping)
                                                }
                                                // Add a hidden view at the very bottom to ensure auto-scroll can reach it
                                                Rectangle()
                                                    .fill(Color.clear)
                                                    .frame(height: 1) // Small height
                                                    .id(bottomID) // Assign an ID to scroll to
                                            }
                                            .padding(12) // p-3 for the internal messages area
                                            .background(Color.gray.opacity(0.05)) // bg-gray-50
                                            .cornerRadius(8) // rounded-lg
                                            .onChange(of: messages.count) { _ in
                                                // Scroll to the latest message when messages count changes
                                                withAnimation {
                                                    scrollViewProxy.scrollTo(bottomID, anchor: .bottom)
                                                }
                                            }
                                            .onChange(of: isTyping) { _ in // Scroll when typing status changes
                                                withAnimation {
                                                    scrollViewProxy.scrollTo(bottomID, anchor: .bottom)
                                                }
                                            }
                                        }
                                        .frame(maxHeight: 400) // Adjusted maxHeight, allowing it to grow but not overflow completely
                                    }
                                    
                                    // Input Area (UNCHANGED logic, but names are preserved)
                                    HStack(spacing: 8) { // flex gap-2
                                        TextField("Ask about your symptoms or health...", text: $currentMessage)
                                            .textFieldStyle(.roundedBorder)
                                            .focused($isInputFocused)
                                            .disabled(isTyping) // Removed apiKey check here
                                            .onSubmit {
                                                sendMessage() // Send on Enter key press
                                            }
                                        
                                        Button(action: sendMessage) {
                                            Image(systemName: "arrow.up.circle.fill") // Send icon
                                                .font(.title2) // h-4 w-4 (adjusted size)
                                                .frame(width: 30, height: 30) // To make it a good tap target
                                                .background(Color.blue.opacity(0.8)) // bg-blue-600
                                                .foregroundColor(.white)
                                                .cornerRadius(15) // rounded-full
                                        }
                                        .disabled(currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTyping) // Removed apiKey check here
                                    }

                                    // API Error message
                                    if errorMessage != nil { // Check for actual error messages from API calls
                                        Text(errorMessage!)
                                            .font(.caption) // text-xs
                                            .foregroundColor(.red.opacity(0.7)) // text-amber-600
                                            .frame(maxWidth: .infinity, alignment: .center) // text-center
                                    }
                                }
                            }
                        }

                        // Quick Questions Card
                        // Preserving user's original naming: CustomCards
                        CustomCards {
                            VStack(alignment: .leading) {
                                // Preserving user's original naming: CustomCardHeaders
                                CustomCardHeaders {
                                    // Preserving user's original naming: CustomCardTitles
                                    CustomCardTitles(text: "Quick Questions")
                                    // Preserving user's original naming: CustomCardDescriptions
                                    CustomCardDescriptions(text: "Common health questions you can ask")
                                }
                                // Preserving user's original naming: CustomCardContents
                                CustomCardContents {
                                    // Use ScrollView for horizontal scrolling for wrapping buttons
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) { // gap-2
                                            ForEach(quickQuestions, id: \.self) { question in
                                                Button(action: {
                                                    currentMessage = question
                                                    isInputFocused = true // Focus input after selecting quick question
                                                }) {
                                                    Text(question)
                                                        .font(.caption) // Slightly smaller font for compactness
                                                        .padding(.horizontal, 8) // Reduced horizontal padding
                                                        .padding(.vertical, 4) // Reduced vertical padding
                                                        .background(Color.gray.opacity(0.1)) // variant="outline"
                                                        .foregroundColor(.primary)
                                                        .cornerRadius(6) // rounded-md
                                                }
                                                .disabled(isTyping) // Disabled when AI is typing
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding() // Overall padding for the ScrollView content
                    // IMPORTANT: Add padding to the bottom of the ScrollView to prevent collision with the fixed bottom bar
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 70) // Added padding, adjusted from 60 to 70 for extra clearance
                }
            }
            .navigationTitle("Health Assistant")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // Formatter for timestamps (UNCHANGED)
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}



// MARK: - FlowLayout (A custom layout helper for wrapping items, like flex-wrap) (UNCHANGED)
struct FlowLayout: Layout {
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
                // New row
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
                // New row
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
