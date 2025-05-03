import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct ContentView: View {
    @State private var user: GIDGoogleUser? = nil
    @State private var message = "Not signed in"

    var body: some View {
        VStack(spacing: 20) {
            Text(message)
                .padding()

            if let user = user {
                Button("✅ Fetch Drive JSON") {
                    listDriveFiles(
                        user: user,
                        folderID: "1sSqu2eQQydKjy-WIZzXfluuk6EoTfAE4",
                        targetFiles: ["project__meta.json", "project__actions.json"]
                    )
                }

                Button("🚪 Sign Out") {
                    GIDSignIn.sharedInstance.signOut()
                    self.user = nil
                    self.message = "Signed out"
                }

            } else {
                GoogleSignInButton {
                    signIn()
                }
                .frame(width: 200, height: 50)
            }
        }
        .onAppear {
            restorePreviousSignIn()
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
}
