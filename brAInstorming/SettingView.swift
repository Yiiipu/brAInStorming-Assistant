import SwiftUI

struct SettingView: View {
    @State private var apiKey: String = ""
    @Binding var botNames: [String]
    @Binding var botPersonalities: [String]
    @State private var selectedModel: String = ""

    var clearChatHistory: () -> Void

    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            VStack {
                ScrollView{
                    VStack(spacing: 20) {
                        Text("API Key")
                            .font(
                                    .system(size: 18)
                                    .weight(.heavy)
                                )
                        TextField("Enter API Key", text: $apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.bottom)
                        Text("Model settings")
                            .font(
                                    .system(size: 18)
                                    .weight(.heavy)
                                )
                        Picker(selection: $selectedModel, label: Text("Select Model")) {
                            Text("GPT-3.5-Turbo ($0.002 / 1K tokens)").tag("gpt-3.5-turbo")
                            Text("GPT-4 (~$0.06 / 1K tokens)").tag("gpt-4")
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.bottom)

                        // Bot settings
                        Text("Bot settings")
                            .font(
                                    .system(size: 18)
                                    .weight(.heavy)
                                )
                        ForEach(0..<3) { index in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Bot\(index + 1) Name")
                                    TextField("Bot\(index + 1) Name", text: $botNames[index])
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }

                                VStack(alignment: .leading) {
                                    Text("Bot\(index + 1) Personality")
                                    TextField("Bot\(index + 1) Personality", text: $botPersonalities[index])
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                        }
                        .padding(.bottom)


                        Button(action: {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                clearChatHistory()
                            }
                        }) {
                            Text("Clear Chat History")
                        }
                        .padding(.bottom)

                        Button(action: {
                            openAppStoreForRating()
                        }) {
                            Text("Rate and Feedback")
                        }
                        .padding(.bottom)

                        Text("If your API Key does not work, make sure your OpenAI account is set as a paid account because OpenAI charge API fee to use GPT-3.5-turbo and GPT-4.\nIf you have further questions or suggestions, please join my Discord channel.")
                        Button(action: {
                            openDiscord()
                        }) {
                            Text("Join Discord Channel")
                        }
                    }
                    .padding()
                    
                }
                .padding(.top, 70)
                Spacer()
            }
            
            VStack {
                HStack {
                    //Spacer()
                    Text("Settings")
                        .font(.title)
                        .bold()
                    Spacer()

                    Button(action: {
                        saveAndDismiss()
                    }) {
                        Text("Save")
                            .padding(.trailing)
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal)
                Spacer()
            }
        }
        .edgesIgnoringSafeArea(.top)
        .onAppear {
            apiKey = UserDefaults.standard.string(forKey: "API_KEY") ?? ""
            
            for index in 0..<3 {
                botNames[index] = UserDefaults.standard.string(forKey: "BOT\(index + 1)_NAME") ?? botNames[index]
                botPersonalities[index] = UserDefaults.standard.string(forKey: "BOT\(index + 1)_PERSONALITY") ?? botPersonalities[index]
            }
            selectedModel = UserDefaults.standard.string(forKey: "SELECTED_MODEL") ?? "gpt-3.5-turbo"
        }
    }
    func openAppStoreForRating() {
        guard let appStoreURL = URL(string: "https://apps.apple.com/app/id6448663582?action=write-review") else {
            return
        }
        UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
    }
    func openDiscord() {
        guard let appStoreURL = URL(string: "https://discord.gg/zHCvZkXXmX") else {
            return
        }
        UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
    }
    private func saveAndDismiss() {
        UserDefaults.standard.set(apiKey, forKey: "API_KEY")
        UserDefaults.standard.set(selectedModel, forKey: "SELECTED_MODEL")

        for index in 0..<3 {
            UserDefaults.standard.set(botNames[index], forKey: "BOT\(index + 1)_NAME")
            UserDefaults.standard.set(botPersonalities[index], forKey: "BOT\(index + 1)_PERSONALITY")
        }

        presentationMode.wrappedValue.dismiss()
    }
}
