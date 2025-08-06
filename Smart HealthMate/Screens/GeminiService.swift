//
//  GeminiService.swift
//  Smart HealthMate
//
//  Created by Moin on 7/17/25.
//

import Foundation
//
//  GeminiService.swift
//  dltme
//
//  Created by Moin on 7/17/25.
//

import Foundation

// MARK: - Gemini API Request and Response Structures

// Structure for the content part of the request and response
struct GeminiContent: Codable {
    let parts: [GeminiPart]
    let role: String? // ADDED: Common in Gemini API responses for content
}

// Structure for the part within content (e.g., text)
struct GeminiPart: Codable {
    let text: String
}

// Structure for the full request body
struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig? // Optional: for temperature, max output tokens etc.
}

// Optional: Generation configuration for the model
struct GeminiGenerationConfig: Codable {
    let temperature: Double?
    let topK: Int?
    let topP: Double?
    let maxOutputTokens: Int?
    let stopSequences: [String]?
}

// Structure for the full response from Gemini
struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
    let promptFeedback: GeminiPromptFeedback?
}

// Candidate response (where the generated text is)
struct GeminiCandidate: Codable {
    let content: GeminiContent?
    let finishReason: String?
    let index: Int?
    let safetyRatings: [GeminiSafetyRating]?
}

// Safety Rating (if you want to handle blocked content)
struct GeminiSafetyRating: Codable {
    let category: String
    let probability: String
}

// Prompt Feedback (e.g., if the prompt itself was blocked)
struct GeminiPromptFeedback: Codable {
    let safetyRatings: [GeminiSafetyRating]?
}

// MARK: - Google API Error Structures (NEW)
// These structs are for decoding common error responses from Google APIs
struct GoogleAPIErrorResponse: Codable {
    let error: GoogleAPIErrorDetail
}

struct GoogleAPIErrorDetail: Codable {
    let code: Int
    let message: String
    let status: String
}

// MARK: - GeminiService: Makes the actual API Call

class GeminiService1: ObservableObject {
    
    
    
    // !! IMPORTANT: Replace "YOUR_GEMINI_API_KEY" with your actual API Key !!
    // As discussed, consider environment variables or a backend for production.
//    private let apiKey = "AIzaSyCnqpCGzeHhplPhx6PDcmQYAEUQG3mp9R8" // <--- REPLACE THIS WITH YOUR KEY
    private let apiKey = Bundle.main.infoDictionary?["API_KEY"] as? String ?? "Not Found" // <--- REPLACE THIS WITH YOUR KEY

    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent" // Using gemini-1.5-flash model

    enum GeminiServiceError: Error, LocalizedError {
        case invalidURL
        case noData
        case decodingError(Error)
        case apiError(String)
        case unknownError

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid API URL."
            case .noData: return "No data received from the API."
            case .decodingError(let error): return "Failed to decode API response: \(error.localizedDescription)"
            case .apiError(let message): return "Gemini API Error: \(message)"
            case .unknownError: return "An unknown error occurred."
            }
        }
    }

    /// Sends a prompt to the Gemini API and returns the generated text.
    func generateContent(prompt: String) async throws -> String {
        let config = URLSessionConfiguration.ephemeral // Ephemeral configuration
        let session = URLSession(configuration: config)
        
        let url = URL(string: "\(baseURL)?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let content = GeminiContent(parts: [GeminiPart(text: prompt)], role: nil)
        let generationConfig = GeminiGenerationConfig(
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 800,
            stopSequences: []
        )
        let geminiRequest = GeminiRequest(contents: [content], generationConfig: generationConfig)

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            request.httpBody = try encoder.encode(geminiRequest)
        } catch {
            print("Request Encoding Error: \(error.localizedDescription)")
            throw GeminiServiceError.decodingError(error)
        }

        print("Sending request to Gemini API...")
        print("Request Body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "N/A")")

        var attempts = 0
        let maxAttempts = 3
        while attempts < maxAttempts {
            do {
                let (data, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw GeminiServiceError.unknownError
                }

                if httpResponse.statusCode != 200 {
                    let errorString = String(data: data, encoding: .utf8) ?? "Unknown API Error"
                    print("Gemini API HTTP Error: \(httpResponse.statusCode), Response: \(errorString)")
                    if let apiErrorDetail = try? JSONDecoder().decode(GoogleAPIErrorResponse.self, from: data) {
                        throw GeminiServiceError.apiError("Status \(httpResponse.statusCode): \(apiErrorDetail.error.message)")
                    } else {
                        throw GeminiServiceError.apiError("Status \(httpResponse.statusCode): \(errorString)")
                    }
                }

                guard !data.isEmpty else {
                    throw GeminiServiceError.noData
                }

                let decoder = JSONDecoder()
                let geminiResponse = try decoder.decode(GeminiResponse.self, from: data)

                if let candidate = geminiResponse.candidates?.first,
                   let text = candidate.content?.parts.first?.text {
                    return text
                } else if let promptFeedback = geminiResponse.promptFeedback,
                          let safetyRatings = promptFeedback.safetyRatings,
                          !safetyRatings.isEmpty {
                    let blockedCategories = safetyRatings.filter { $0.probability != "NEGLIGIBLE" }
                        .map { "\($0.category) (\($0.probability))" }
                        .joined(separator: ", ")
                    throw GeminiServiceError.apiError("Prompt blocked by safety settings: \(blockedCategories)")
                } else {
                    throw GeminiServiceError.apiError("No valid text candidate found in Gemini response or unexpected format.")
                }
            } catch {
                attempts += 1
                if attempts == maxAttempts {
                    print("Max retry attempts reached. Final error: \(error.localizedDescription)")
                    throw error
                }
                try await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...2_000_000_000)) // 1-2 seconds with jitter
                print("Retrying attempt \(attempts + 1) due to error: \(error.localizedDescription)")
            }
        }
        throw GeminiServiceError.unknownError
    }
}
