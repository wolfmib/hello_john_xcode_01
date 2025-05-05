
// HelloJohnXcode :  used GogoleDrive & Voice & LLM
// Part 1 InitApp & GogoleDrive
import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

//voice part2
import Speech
import AVFoundation

struct ContentView: View {
    
    // GoogleDriveApi
    @State private var user: GIDGoogleUser? = nil
    @State private var message = "Not signed in"
    
    // XcodeVoice
    @State private var isRecording = false
    @State private var recognizedText = ""
    let speechRecognizer = SFSpeechRecognizer()
    let audioEngine = AVAudioEngine()
    let speechSynthesizer = AVSpeechSynthesizer()
    // XcodeVoice-Reply-Display-Times-Cnts
    @State private var countdown: Int? = nil
    @State private var countdownTimer: Timer? = nil
    @State private var isProcessing = false
    @State private var finalText = ""
    //open-api
    @State private var openAITokenPreview: String = "🔍 Token not loaded"
    @State private var testResult: String = ""




    var body: some View {
        VStack(spacing: 20) {
            Text(message)
                .padding()

            if let user = user {
                

                Button("🧪 Test OpenAI") {
                    let input = "Say hi to John, now in French"
                    let systemPrompt = ""
                    let extraInfo = ""

                    // 👇 Force reload right before use
                    if let token = loadCloseApiToken() {
                        openAITokenPreview = "🔑 Token Preview: \(token.prefix(12))..."
                        print("✅ Reloaded token: \(token.prefix(12))")
                        

                        testOpenAI(input: input, systemPrompt: systemPrompt, extraInfo: extraInfo) { response in
                            print("🧪 Sending request to OpenAI...")
                            print("🔑 Using token: \(token.prefix(8))...")
                            print("🧪 TestOpenAI Response:\n\(response)")
                            DispatchQueue.main.async {
                                self.testResult = response
                            }
                        }
                              
                    } else {
                        testResult = "❌ Token not found on click"
                    }
                }
                Text("🧠 OpenAI Response:\n\(testResult)")
                .font(.body)
                .foregroundColor(.green)
                .padding(.horizontal)
           

                
                
                Button("✅ Fetch Drive JSON") {
                    listDriveFiles(
                        user: user,
                        folderID: "1sSqu2eQQydKjy-WIZzXfluuk6EoTfAE4",
                        targetFiles: ["project__meta.json", "project__actions.json","JA_ENV.json"]
                    )
                }
                
                Button(isRecording ? "🛑 Stop Recording" : "🎙 Start Recording") {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }
                Text("📝 Last recognized: \(recognizedText)")
                .padding()

                
                if isProcessing {
                    Text("⏳ Finalizing speech...")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                

                Button("🚪 Sign Out") {
                    GIDSignIn.sharedInstance.signOut()
                    self.user = nil
                    self.message = "Signed out"
                }
                
                
                if let secondsLeft = countdown {
                    Text("⏳ Speaking in \(secondsLeft)...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                //open-ai
                Text(openAITokenPreview)
                    .font(.caption)
                    .foregroundColor(.blue)


                Text("📁 Meta Preview:\n\(loadJSONPreview(fileName: "project__meta.json"))")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)

                Text("📁 Action Preview:\n\(loadJSONPreview(fileName: "project__actions.json"))")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)


            } else {
                GoogleSignInButton {
                    signIn()
                }
                .frame(width: 200, height: 50)
            }
        }
        .onAppear {
            restorePreviousSignIn()
            
            // 🔁 Listen for JA_ENV update after download
            NotificationCenter.default.addObserver(forName: .didUpdateJAEnv, object: nil, queue: .main) { _ in
                if let token = loadCloseApiToken() {
                    openAITokenPreview = "🔑 Token Preview: \(token.prefix(12))..."
                } else {
                    openAITokenPreview = "❌ Failed to load token after download"
                }
            }
            
        }
    }

    func signIn() {
        if let dict = Bundle.main.infoDictionary {
            print("📦 Info.plist contents:\n\(dict)")
        } else {
            print("❌ No infoDictionary found")
        }

        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let clientID = dict["CLIENT_ID"] as? String else {
            print("❌ Failed to load CLIENT_ID from GoogleService-Info.plist")
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(
            withPresenting: getRootViewController(),
            hint: nil,
            additionalScopes: ["https://www.googleapis.com/auth/drive"]
        ) { signInResult, error in
            if let error = error {
                message = "Sign-in failed: \(error.localizedDescription)"
                return
            }

            guard let signInResult = signInResult else {
                message = "No result returned"
                return
            }

            user = signInResult.user
            message = "Signed in as: \(user?.profile?.email ?? "unknown")"
        }
    }

    func restorePreviousSignIn() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let user = user {
                self.user = user
                message = "Restored session for \(user.profile?.email ?? "unknown")"
            } else {
                message = "Not signed in"
            }
        }
    }

    func getRootViewController() -> UIViewController {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else {
            fatalError("No root view controller.")
        }
        return root
    }

    func listDriveFiles(
        user: GIDGoogleUser,
        folderID: String,
        targetFiles: [String]
    ) {
        let accessToken = user.accessToken.tokenString

        for targetName in targetFiles {
            let query = "https://www.googleapis.com/drive/v3/files?q='\(folderID)'+in+parents+and+name='\(targetName)'&orderBy=modifiedTime desc&pageSize=1&fields=files(id,name,modifiedTime)"
            guard let url = URL(string: query) else {
                print("❌ Invalid URL for \(targetName)")
                continue
            }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data else {
                    print("❌ Failed to list \(targetName): \(error?.localizedDescription ?? "unknown")")
                    return
                }

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let files = json["files"] as? [[String: Any]],
                   let file = files.first,
                   let fileId = file["id"] as? String {
                    print("📥 Latest \(targetName): \(file)")
                    downloadDriveFile(fileId: fileId, fileName: targetName, accessToken: accessToken)
                } else {
                    print("⚠️ No recent file found for \(targetName)")
                }
            }.resume()
        }
    }

    func downloadDriveFile(fileId: String, fileName: String, accessToken: String) {
        let urlStr = "https://www.googleapis.com/drive/v3/files/\(fileId)?alt=media"
        guard let url = URL(string: urlStr) else {
            print("❌ Invalid download URL")
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let data = data {
                if let content = String(data: data, encoding: .utf8) {
                    print("📥 \(fileName) content:\n\(content)")
                }
                saveToDocuments(data: data, fileName: fileName)
                // 👇 Fix here: notify main view AFTER save
                if fileName == "JA_ENV.json" {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .didUpdateJAEnv, object: nil)
                        print("I am fucking confimred  dispatchque main sync for the JA_ENV.json")
                    }
                }

            } else {
                print("❌ Failed to download \(fileName): \(error?.localizedDescription ?? "unknown")")
            }
        }.resume()
    }

    func saveToDocuments(data: Data, fileName: String) {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            print("✅ Saved \(fileName) to local documents")
        } catch {
            print("❌ Save error: \(error.localizedDescription)")
        }
    }
    
    
    func startRecording() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            guard authStatus == .authorized else {
                print("❌ Speech recognition not authorized")
                message = "Microphone access not granted"
                return
            }
            
           


            let request = SFSpeechAudioBufferRecognitionRequest()
            let inputNode = audioEngine.inputNode

            request.shouldReportPartialResults = true
            isRecording = true
            recognizedText = ""

            speechRecognizer?.recognitionTask(with: request) { result, error in
                if let result = result {
                    finalText = result.bestTranscription.formattedString
                    recognizedText = finalText
                }
                
                if error != nil || result?.isFinal == true {
                    // Don't call stopRecording here anymore
                }
            }

            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                request.append(buffer)
            }

            audioEngine.prepare()
            try? audioEngine.start()
            print("🎙 Recording started")
        }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isRecording = false
        isProcessing = true
        recognizedText = "🧠 Processing..."
        print("🛑 Recording stopped")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startCountdown(seconds: 5) {
                isProcessing = false
                recognizedText = finalText  // 👈 restore proper display text
                speakText(finalText)
            }
        }
    }


    func speakText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.4 // << make it slower
        speechSynthesizer.speak(utterance)
        print("🔊 Speaking: \(text)")
    }
    
    
    func startCountdown(seconds: Int, onComplete: @escaping () -> Void) {
        countdown = seconds
        countdownTimer?.invalidate()
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            DispatchQueue.main.async {  // 🔁 Force UI update
                if let current = countdown, current > 0 {
                    print("⏳ Countdown: \(current)")
                    countdown = current - 1
                } else {
                    timer.invalidate()
                    countdownTimer = nil
                    countdown = nil
                    onComplete()
                }
            }
        }
    }
    

    
    


}


//openai
func loadCloseApiToken() -> String? {
    let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("JA_ENV.json")

    do {
        let data = try Data(contentsOf: fileURL)
        if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            for item in jsonArray {
                if let key = item["key"] as? String,
                   key == "CLOSE_API_TOKEN",
                   let value = item["value"] as? String {
                    print("✅ Found token: \(value.prefix(12))...")
                    return value
                }
            }
        }
    } catch {
        print("❌ Token load error: \(error)")
    }

    return nil
}










extension Notification.Name {
    static let didUpdateJAEnv = Notification.Name("didUpdateJAEnv")
}


