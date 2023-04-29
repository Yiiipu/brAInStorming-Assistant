import SwiftUI

struct SettingView: View {
    @State private var apiKey: String = ""
    var clearChatHistory: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter API Key", text: $apiKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                UserDefaults.standard.set(apiKey, forKey: "API_KEY")
            }) {
                Text("Save API Key")
            }
            
            Button(action: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    clearChatHistory()
                }
            }) {
                Text("Clear Chat History")
            }

            
        }
        .padding()
        .onAppear {
            apiKey = UserDefaults.standard.string(forKey: "API_KEY") ?? ""
        }
    }
}
