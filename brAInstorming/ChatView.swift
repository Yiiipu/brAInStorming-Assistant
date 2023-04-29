import SwiftUI

struct ChatView: View {
    @State private var inputText: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var turn: Int = 0
    @State private var showingSettingView = false
    @State private var isAISpeaking = false

    private let chatHistoryKey = "chatHistory"
    private let turnKey = "turn"
    @State private var showIntroText: Bool = true


    var body: some View {
        NavigationView {
            VStack {
                if showIntroText && messages.isEmpty {
                    Text("1. Please set OpenAI API Key in app before chat.\n2. Show respect to bots. Please do not close the app when bots are talking.")
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .padding(.top)
                }
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages, id: \.content) { message in
                            HStack {
                                if message.role != "user" {
                                    VStack(alignment: .leading) {
                                        Text(message.role == "bot1" ? "Amanda" : (message.role == "bot2" ? "Bob" : "Charlie"))
                                            .font(.footnote)
                                            .foregroundColor(message.role == "bot1" ? Color.green : (message.role == "bot2" ? Color.blue : Color.red))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        
                                        Text("\(message.content)")
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
            .navigationBarTitle("Chat Room")
            .navigationBarItems(trailing: Button(action: {
                showingSettingView.toggle()
            }) {
                Image(systemName: "gear")
                    .resizable()
                    .frame(width: 24, height: 24)
            })
            .sheet(isPresented:$showingSettingView){
                SettingView(clearChatHistory: clearChatHistory)
            }

            .onAppear {
                loadChatHistory()
            }
        }
    }
    private func processUserMessage() {
        if turn % 4 != 0 {
            let botID = turn % 4
            isAISpeaking = true
            APIManager.shared.fetchChatGPTResponse(botID: botID, chatHistory: messages) { result in
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        messages.append(ChatMessage(role: "bot\(botID)", content: response))
                        turn += 1
                        if turn % 4 != 0 {
                            processUserMessage()
                        } else {
                            isAISpeaking = false
                        }
                        saveChatHistory()
                    }
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                    isAISpeaking = false
                }
            }
        }
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
