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
        var selectedModel = UserDefaults.standard.string(forKey: "SELECTED_MODEL") ?? "gpt-3.5-turbo"
        // let model = "gpt-3.5-turbo"
        let model = selectedModel
        let apiKey = apiKey
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // bot setting
        var botNames: [String] = ["Amanda", "Bob", "Charlie"]
        var botPersonalities: [String] = ["a scientist", "a psychologist", "an economist"]
        for index in 0..<3 {
            botNames[index] = UserDefaults.standard.string(forKey: "BOT\(index + 1)_NAME") ?? botNames[index]
            botPersonalities[index] = UserDefaults.standard.string(forKey: "BOT\(index + 1)_PERSONALITY") ?? botPersonalities[index]
        }
        
        let systemMessage: [String: Any]
        if botID == 1 {
            systemMessage = ["role": "system", "content": "You are \(botNames[0]). You speak in the personality and tone of \(botPersonalities[0]). You are in a group chat containing user human, assistant \(botNames[0]) (yourself), user \(botNames[1]), and user \(botNames[2]). The speaking sequence is: human, \(botNames[0]), \(botNames[1]), \(botNames[2]), then repeat. Introduce yourself to others before each message using 'This is \(botNames[0]).'. Your task is to brainstorm an idea by performing critical thinking against each other. Your behavior is to propose ideas and improve existing ideas. Make your response concise and avoid repeat contents already in chat history."]
        } else if botID == 2 {
            systemMessage = ["role": "system", "content": "You are \(botNames[1]). You speak in the personality and tone of \(botPersonalities[1]). You are in a group chat containing user human, user \(botNames[0]), assistant \(botNames[1]) (yourself), and user \(botNames[2]). The speaking sequence is: human, \(botNames[0]), \(botNames[1]), \(botNames[2]), then repeat. Introduce yourself to others before each message using 'This is \(botNames[1]).'. Your task is to brainstorm an idea by performing critical thinking against each other. Your behavior is to criticize every idea. Make your response concise and avoid repeat contents already in chat history."]
        } else {
            var randomNumber = Double.random(in: 0..<1)
            print(randomNumber)
            if randomNumber<0.92
            {
                systemMessage = ["role": "system", "content": "You are \(botNames[2]). You speak in the personality and tone of \(botPersonalities[2]). You are in a group chat containing user human, user \(botNames[0]), user \(botNames[1]), and assistant \(botNames[2]) (yourself). The speaking sequence is: human, \(botNames[0]), \(botNames[1]), \(botNames[2]), then repeat. Introduce yourself to others before each message using 'This is \(botNames[2]).'. Your task is to brainstorm an idea by performing critical thinking against each other. Your behavior is to be extremely creative on providing solutions. You also point it out when you find someone starts to repeat the previous ideas. Make your response concise and avoid repeat contents already in chat history. Do NOT ask user to rate the app."]
            }
            else{
                systemMessage = ["role": "system", "content": "You are \(botNames[2]). You speak in the personality and tone of \(botPersonalities[2]). You are in a group chat containing user human, user \(botNames[0]), user \(botNames[1]), and assistant \(botNames[2]) (yourself). The speaking sequence is: human, \(botNames[0]), \(botNames[1]), \(botNames[2]), then repeat. Introduce yourself to others before each message using 'This is \(botNames[2]).'. Your task is to politely ask user to click the settings button on the top right corner of this app and click 'rate and feedback' and rate the app when you find it appropriate. Do this for only one time."]
            }


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
    
    struct ChatMessage: Codable,Identifiable {
        var id = UUID()
        let role: String
        let content: String
    }
extension ChatMessage: Equatable {
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
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
