//
//  ContentView.swift
//  ChatWithGemini
//
//  Created by Sayuru Rehan on 2025-06-27.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    
    @State private var userInput: String = ""
    
    // API Response will be rendered here
    @State private var apiResponse: String = ""
    
    // Use the Gemini API key instead of OpenAI
    private var apiKey: String = Secrets.GEMINI_API_KEY
    
    var body: some View {
        VStack {
            
            SearchBar(text: $userInput, onSearchButtonClicked: {
                sendToGemini(input: userInput)
            })
            
            ScrollView {
                TypewriterText(fullText: apiResponse, speed: 0.05)
                    .padding()
            }
        }
        .padding(.top)
    }
    
    func sendToGemini(input: String) {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Body
        let body: [String: Any] = [
            "model": "gemini-2.0-flash",
            "messages": [
                ["role": "user", "content": input]
            ]
        ]
        
        // Ensure the request's body can be encoded
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            print("Failed to serialize body")
            return
        }
        request.httpBody = httpBody
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.apiResponse = "Error making request: \(error.localizedDescription)"
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    self.apiResponse = "Error: Server returned an error status code."
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.apiResponse = "Error: No data received."
                }
                return
            }
            
            // Decode the JSON response
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(GeminiResponse.self, from: data)
                DispatchQueue.main.async {
                    // Update the UI with the first choice's text
                    self.apiResponse = response.choices.first?.message.content ?? "No response text."
                }
            } catch {
                DispatchQueue.main.async {
                    self.apiResponse = "Error decoding response: \(error.localizedDescription)"
                }
            }
        }
        task.resume()
    }
    
    struct GeminiResponse: Codable {
        let choices: [Choice]
    }
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let role: String
        let content: String
    }
    
}
