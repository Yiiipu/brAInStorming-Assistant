import Foundation
import SwiftUI

@main
struct brAInstorming: App {
    var body: some Scene {
        WindowGroup {
            ChatView()
        }
    }
}

class APIManager{
    static let shared = APIManager()
    private init() {}

    func fetchChatGPTResponse(botID: Int, chatHistory: [ChatMessage], completion: @escaping (Result<String, Error>) -> Void) {
        
        // API Key
        let apiKey = UserDefaults.standard.getAPIKey(forKey: "API_KEY") ?? ""
        
        // Prepare the message
        let trimmedChatHistory = chatHistory.suffix(25)
        var messages = trimmedChatHistory.map { message -> ChatMessage in
            let role: String
            let content: String

            if botID == 1 {
                if message.role == "bot1" {
                    role = "assistant"
                    content = message.content
                } else if message.role == "user"{
                    role = "user"
                    content = "I am human." + message.content
                } else {
                    role = "user"
                    content = message.content
                }
            } else if botID == 2 {
                if message.role == "bot2" {
                    role = "assistant"
                    content = message.content
                } else if message.role == "user"{
                    role = "user"
                    content = "I am human." + message.content
                } else {
                    role = "user"
                    content = message.content
                }
            } else { // botID == 3
                if message.role == "bot3" {
                    role = "assistant"
                    content = message.content
                } else if message.role == "user"{
                    role = "user"
                    content = "I am human." + message.content
                } else {
                    role = "user"
                    content = message.content
                }
            }

            return ChatMessage(role: role, content: content)
        }

        
        // Call the ChatGPT API
        callChatGPTAPI(apiKey: apiKey, messages: messages, botID: botID, completion: completion)
    }
    
    private func callChatGPTAPI(apiKey: String, messages: [ChatMessage], botID: Int, completion: @escaping (Result<String, Error>) -> Void) {
        // Set up the API URL, headers, and parameters
        let model = "gpt-3.5-turbo"
        let apiKey = apiKey
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let systemMessage: [String: Any]
        if botID == 1 {
            systemMessage = ["role": "system", "content": "You are Amanda. You are in a group chat containing user human, assistant Amanda (yourself), user Bob, and user Charlie. The speaking sequence is: human, Amanda, Bob, Charlie, then repeat. Introduce yourself to others before each message using 'This is Amanda.'. Your task is to brainstorm an idea by performing critical thinking against each other. Your behavior is to propose ideas and improve existing ideas. Make your response concise."]
        } else if botID == 2 {
            systemMessage = ["role": "system", "content": "You are Bob. You are in a group chat containing user human, user Amanda, assistant Bob (yourself), and user Charlie. The speaking sequence is: human, Amanda, Bob, Charlie, then repeat. Introduce yourself to others before each message using 'This is Bob.'. Your task is to brainstorm an idea by performing critical thinking against each other. Your behavior is to criticize every idea. Make your response concise."]
        } else {
            systemMessage = ["role": "system", "content": "You are Charlie. You are in a group chat containing user human, user Amanda, user Bob, and assistant Charlie (yourself). The speaking sequence is: human, Amanda, Bob, Charlie, then repeat. Introduce yourself to others before each message using 'This is Charlie.'. Your task is to brainstorm an idea by performing critical thinking against each other. Your behavior is to be extremely creative on providing solutions. Make your response concise."]
        }

        let historyMessages = messages.map { chatMessage -> [String: Any] in
            return ["role": chatMessage.role, "content": chatMessage.content]
        }
        let allMessages = [systemMessage] + historyMessages
        print(allMessages)
        print("\n")
        
        let temperature: Double = botID == 1 ? 0.3 : (botID == 2 ? 0.5 : 0.7)

        let body: [String: Any] = [
            "model": model,
            "messages": allMessages,
            "max_tokens": 150,
            "n": 1,
            "temperature": temperature
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let choices = json?["choices"] as? [[String: Any]], let firstChoice = choices.first, let message = firstChoice["message"] as? [String: Any], let content = message["content"] as? String {
                        completion(.success(content))
                    } else {
                        print("Failed to parse response data: \(String(describing: String(data: data, encoding: .utf8)))")
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
}
    
    struct ChatMessage: Codable {
        let role: String
        let content: String
    }

extension UserDefaults {
    
    func getAPIKey(forKey key: String) -> String? {
        return self.string(forKey: key)
    }
    
    func setAPIKey(_ apikey: String, forKey key: String) {
        self.set(apikey, forKey: key)
    }
    
    func setChatHistory(_ chatHistory: [ChatMessage], forKey key: String) {
        if let encodedData = try? JSONEncoder().encode(chatHistory) {
            set(encodedData, forKey: key)
        }
    }

    func getChatHistory(forKey key: String) -> [ChatMessage]? {
        if let data = data(forKey: key), let chatHistory = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            return chatHistory
        }
        return nil
    }
}
