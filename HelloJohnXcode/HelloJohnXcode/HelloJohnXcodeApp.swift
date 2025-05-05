import SwiftUI
import GoogleSignIn

@main
struct HelloJohnXcodeApp: App {

    init() {
        // ✅ Load client ID from Info.plist or GoogleService-Info.plist
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let clientID = dict["CLIENT_ID"] as? String {

            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            print("✅ Google Sign-In configured")
        } else {
            print("❌ Failed to configure Google Sign-In: Missing client ID")
        }
    }


    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("Main", systemImage: "house")
                    }

                TabOutputView()
                    .tabItem {
                        Label("Output", systemImage: "doc.plaintext")
                    }
                
                TabLLMView()
                    .tabItem {
                        Label("LLM", systemImage: "brain.head.profile")
                    }
            }
        }
    }
}
