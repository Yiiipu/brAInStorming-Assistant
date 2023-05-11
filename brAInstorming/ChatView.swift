import SwiftUI
import Combine

struct ChatView: View {
    @State private var inputText: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var turn: Int = 0
    @State private var showingSettingView = false
    @State private var isAISpeaking = false
    @State private var botNames: [String] = ["Amanda", "Bob", "Charlie"]
    @State private var botPersonalities: [String] = ["a scientist", "a psychologist", "an economist"]
    @State private var lastMessageId: UUID? = nil

    private let chatHistoryKey = "chatHistory"
    private let turnKey = "turn"
    @State private var showIntroText: Bool = true


    var body: some View {
        ZStack {
            
            VStack {
                if showIntroText && messages.isEmpty {
                    Text("1. Please set OpenAI API Key in app before chat.\n2. Show respect to bots. Please do not close the app when bots are talking.")
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .padding(.top)
                }
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(messages, id: \.id) { message in
                                HStack {
                                    if message.role != "user" {
                                        VStack(alignment: .leading) {
                                            Text(message.role == "bot1" ? botNames[0] : (message.role == "bot2" ? botNames[1] : botNames[2]))
                                                .font(.footnote)
                                                .foregroundColor(message.role == "bot1" ? Color.green : (message.role == "bot2" ? Color.blue : Color.red))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            
                                            Text(trimmedContent(message: message))
                                                .padding()
                                                .background(Color.secondary.opacity(0.2))
                                                .foregroundColor(.primary)
                                                .cornerRadius(8)
                                        }
                                    } else {
                                        Spacer()
                                    }
                                    
                                    if message.role == "user" {
                                        VStack(alignment: .trailing) {
                                            Text("\(message.role)")
                                                .font(.footnote)
                                                .foregroundColor(Color.gray)
                                                .frame(maxWidth: .infinity, alignment: .trailing)
                                            
                                            Text("\(message.content)")
                                                .padding()
                                                .background(Color.green)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .onChange(of: messages) { newMessages in
                        if let lastMessage = newMessages.last {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                if !isAISpeaking {
                    HStack {
                        TextEditor(text: $inputText)
                            .frame(height: 60)
                            .padding(4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        
                        Button(action: {
                            if !inputText.isEmpty {
                                messages.append(ChatMessage(role: "user", content: inputText))
                                turn += 1
                                processUserMessage()
                                inputText = ""
                                saveChatHistory()
                            }
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .padding(.trailing)
                        }
                    }
                }
            }
            .padding(.top, 100)
            
            VStack {
                HStack {
                    //Spacer()
                    Text("Chat Room")
                        .font(.title)
                        .bold()
                    Spacer()
                    
                    Button(action: {
                        showingSettingView.toggle()
                    }) {
                        Image(systemName: "gear")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .padding(.trailing)
                    }
                }
                .padding(.top, 50)
                .padding(.horizontal)
                Spacer()
            }
        }
    
        .edgesIgnoringSafeArea(.top)
        .sheet(isPresented:$showingSettingView){
            SettingView(botNames: $botNames, botPersonalities: $botPersonalities,clearChatHistory: clearChatHistory)
        }
        
        .onAppear {
            loadChatHistory()
            for index in 0..<3 {
                botNames[index] = UserDefaults.standard.string(forKey: "BOT\(index + 1)_NAME") ?? botNames[index]
                botPersonalities[index] = UserDefaults.standard.string(forKey: "BOT\(index + 1)_PERSONALITY") ?? botPersonalities[index]
            }
        }
    
    }
    private func trimmedContent(message: ChatMessage) -> String {
        if let firstDotIndex = message.content.firstIndex(of: ".") {
            let startIndex = message.content.index(after: firstDotIndex)
            let remainingContent = String(message.content[startIndex...])
            return remainingContent.trimmingCharacters(in: .whitespaces)
        } else {
            return message.content
        }
    }
    private func processUserMessage() {
        let dispatchGroup = DispatchGroup()
        
        func processMessage() {
            if turn % 4 != 0 {
                let botID = turn % 4
                isAISpeaking = true
                
                dispatchGroup.enter()
                APIManager.shared.fetchChatGPTResponse(botID: botID, chatHistory: messages) { result in
                    switch result {
                    case .success(let response):
                        DispatchQueue.main.async {
                            messages.append(ChatMessage(role: "bot\(botID)", content: response))
                            turn += 1
                            saveChatHistory()
                        }
                    case .failure(let error):
                        print("Error: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            messages.append(ChatMessage(role: "bot\(botID)", content: "This is \(botNames[botID-1]). Sorry, I need more time to think about this."))
                            turn += 1
                            saveChatHistory()
                        }
                    }
                    dispatchGroup.leave()
                }
                
                dispatchGroup.notify(queue: .main) {
                    if turn % 4 != 0 {
                        processMessage()
                    }else {
                        isAISpeaking = false
                    }
                }
            }
        }
        
        processMessage()
    }

    
    private func saveChatHistory() {
        if let encodedData = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(encodedData, forKey: chatHistoryKey)
            UserDefaults.standard.set(turn, forKey: turnKey)
        } else {
            print("Failed to save chat history")
        }
    }

    
    private func loadChatHistory() {
        if let savedData = UserDefaults.standard.data(forKey: chatHistoryKey),
           let decodedData = try? JSONDecoder().decode([ChatMessage].self, from: savedData) {
            messages = decodedData
            turn = UserDefaults.standard.integer(forKey: turnKey)
        } else {
            print("Failed to load chat history")
        }
    }

    private func clearChatHistory() {
        messages = []
        turn = 0
        UserDefaults.standard.removeObject(forKey: chatHistoryKey)
        UserDefaults.standard.set(turn, forKey: turnKey)
    }


}
