import SwiftUI
import PhotosUI
import Vision
import UIKit

struct ScannerContentView: View {
    @Environment(\.dismiss) var dismiss // To close the sheet
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    @State private var rawDetails: String?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showAlert: Bool = false
    
    private let geminiApiKey = Bundle.main.infoDictionary?["API_KEY"] as? String ?? "Not Found"
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.1), .white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Custom PhotosPicker button
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                                .shadow(radius: 5)
                            
                            Image(systemName: "camera.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            isLoading = true
                            errorMessage = nil
                            rawDetails = nil
                            showAlert = false
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                selectedImage = Image(uiImage: uiImage)
                                await processMedicineImage(uiImage)
                            } else {
                                errorMessage = "Failed to load image."
                                showAlert = true
                                isLoading = false
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    // Selected image with card effect
                    if let selectedImage = selectedImage {
                        selectedImage
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 200, maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
                            .padding(.horizontal)
                            .animation(.easeInOut(duration: 0.3), value: selectedImage)
                    } else {
                        Text("Select an image to analyze")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.gray)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(radius: 5)
                    }
                    
                    // Loading indicator with custom style
                    if isLoading {
                        ProgressView("Processing image...")
                            .progressViewStyle(.circular)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(radius: 5)
                    }
                    
                    // Error message with card style
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal)
                            .shadow(radius: 5)
                    }
                    
                    // Medicine details in a scrollable card
                    ScrollView {
                        if let rawDetails = rawDetails {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("ℹ️ Extracted Information")
                                    .font(.system(.title3, design: .rounded, weight: .bold))
                                    .foregroundColor(.blue)
                                    .padding(.bottom, 5)
                                
                                Text(rawDetails)
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.primary)
                                    .lineSpacing(5)
                            }
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
                            .padding(.horizontal)
                            .animation(.easeInOut(duration: 0.3), value: rawDetails)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top)
                .navigationTitle("Medicine Scanner")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(.blue)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                    }

                    ToolbarItem(placement: .principal) {
                        Text("Medicine Scanner")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }

                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Error"),
                        message: Text(errorMessage ?? "Unknown error"),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
    }
    
    // Process image with Vision for OCR
    func processMedicineImage(_ image: UIImage) async {
        guard let cgImage = image.cgImage else {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to process image."
                self.showAlert = true
                self.isLoading = false
            }
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                DispatchQueue.main.async {
                    self.errorMessage = "No text detected in the image."
                    self.showAlert = true
                    self.isLoading = false
                }
                return
            }
            
            let recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            
            Task {
                await self.queryGeminiAPI(itemName: recognizedText)
            }
        }
        
        request.recognitionLevel = .accurate
        
        do {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Error processing image: \(error.localizedDescription)"
                self.showAlert = true
                self.isLoading = false
            }
        }
    }
    
    // Query Gemini API with retry logic and timeout
    func queryGeminiAPI(itemName: String, attempt: Int = 1, maxAttempts: Int = 3) async {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(geminiApiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let prompt = """
        The text extracted from an image is: "\(itemName)". Provide detailed and user-friendly information about this item.
        
        Format the response as plain text, clearly labeling each section. For each detail, provide a comprehensive explanation. If specific information is not directly available from the image, provide general knowledge or common examples related to the item. Do not state that information is missing or refer to the "provided text".
        
        - Name: [Name of the medicine or item]
        - Purpose: [What it is used for, with a brief explanation]
        - Form: [e.g., Tablet, Liquid, Cream] (if applicable)
        - Ingredients: [List of active and inactive ingredients, if applicable, with brief roles if known, separated by commas]
        - Uses: [Specific conditions or applications, explained with examples if possible, listed as bullet points]
        - How It Works: [Mechanism of action, explained simply]
        - Benefits: [Advantages of using it, explained with examples if possible, listed as bullet points]
        - Risks: [Common side effects or precautions, explained with examples if possible, listed as bullet points. Emphasize consulting a healthcare professional.]
        - Summary: [A comprehensive and user-friendly overview for users, emphasizing key takeaways and the importance of professional advice.]
        
        If the item is clearly not a medicine or cannot be recognized as a medical product, provide a concise summary stating that it is not a medicine and suggest consulting a healthcare professional for medical advice.
        Example for non-medicine:
        Name: Medical Tape
        Summary: This item is not recognized as a medicine. It appears to be medical tape, commonly used for securing bandages or medical devices. Please consult a healthcare professional for specific medical advice.
        """
        
        let json: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json) else {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to create JSON request for Gemini."
                self.showAlert = true
                self.isLoading = false
            }
            return
        }
        
        request.httpBody = jsonData
        
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        let session = URLSession(configuration: config)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 503 && attempt < maxAttempts {
                    try await Task.sleep(nanoseconds: 5_000_000_000)
                    await queryGeminiAPI(itemName: itemName, attempt: attempt + 1, maxAttempts: maxAttempts)
                    return
                }
            }
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw Gemini Response: \(rawResponse)")
            } else {
                print("Failed to decode raw response as UTF-8")
            }
            
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let error = jsonResponse["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    if attempt < maxAttempts && message.contains("overloaded") {
                        try await Task.sleep(nanoseconds: 5_000_000_000)
                        await queryGeminiAPI(itemName: itemName, attempt: attempt + 1, maxAttempts: maxAttempts)
                        return
                    }
                    DispatchQueue.main.async {
                        self.errorMessage = "Gemini API is temporarily unavailable. Please try again later or consult a healthcare professional."
                        self.showAlert = true
                        self.isLoading = false
                    }
                    return
                }
                
                if let candidates = jsonResponse["candidates"] as? [[String: Any]],
                   let firstCandidate = candidates.first,
                   let content = firstCandidate["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let text = parts.first?["text"] as? String {
                    DispatchQueue.main.async {
                        self.rawDetails = text
                        self.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "No valid response structure from Gemini API."
                        self.showAlert = true
                        self.isLoading = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to parse Gemini response as JSON."
                    self.showAlert = true
                    self.isLoading = false
                }
            }
        } catch {
            if attempt < maxAttempts, (error as NSError).code == NSURLErrorTimedOut {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                await queryGeminiAPI(itemName: itemName, attempt: attempt + 1, maxAttempts: maxAttempts)
                return
            }
            DispatchQueue.main.async {
                self.errorMessage = "Error querying Gemini API: \(error.localizedDescription). Please try again later or consult a healthcare professional."
                self.showAlert = true
                self.isLoading = false
            }
        }
    }
}

#Preview {
    ScannerContentView()
}
