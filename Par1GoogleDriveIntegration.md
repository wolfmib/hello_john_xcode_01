# ✅ Project Summary: Google Drive Integration with SwiftUI + Google Sign-In

## 🎯 Goal

Integrate Google Sign-In (OAuth2) with Drive scope (`auth/drive`) to fetch and download files using an iOS SwiftUI app.

---

## 🚀 Setup Steps (Xcode + Google Cloud)

### 1. 📄 Download GoogleService-Info.plist

* Go to **Google Cloud Console > Credentials**
* Choose **iOS OAuth Client**
* Save the `.plist` file

### 2. 🛠️ Add GoogleService-Info.plist to Xcode

* Drag the file into the project root in Xcode
* Ensure it's added to **target membership**

### 3. 🧠 Manually Modify Info.plist

Add the `REVERSED_CLIENT_ID` key manually:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

### 4. 🧱 Build Settings (⚠️ Common Pitfalls)

#### 4.1 In Build Settings:

* `Generate Info.plist File` → **NO**
* `Info.plist File` → manually set to `HelloJohnXcode/Info.plist`

#### 4.2 In Build Phases → Packaging:

* Ensure **no redundant Info.plist** is being copied
* Avoid `Multiple commands produce Info.plist` error

---

## 🔑 Code Changes

### 5. ✏️ Modify `ContentView.swift`

Implement Google Sign-In with Drive scope:

```swift
GIDSignIn.sharedInstance.signIn(
    withPresenting: getRootViewController(),
    hint: nil,
    additionalScopes: ["https://www.googleapis.com/auth/drive"]
) { signInResult, error in
    ...
}
```

---

## 🧪 Issues Encountered (and Solved)

### ❌ 403: access\_denied

* **Cause**: App not verified for external access using `auth/drive`
* **Solution**:

  * Go to **OAuth Consent Screen**
  * Set app name, support email, scopes
  * Add test user (e.g., `wolfmib@gmail.com`)
  * Publish for internal testing

### ❌ Consent screen auto-redirects to dashboard

* **Cause**: Incorrect project context or uninitialized consent screen
* **Solution**:

  * Select correct project in Google Cloud console
  * Go back to **OAuth Consent Screen** setup

### ❌ CFBundleVersion error

* **Cause**: `Info.plist` missing required fields
* **Solution**:

  * Add:

    ```
    CFBundleVersion = 1
    CFBundleShortVersionString = 1.0
    ```
  * Clean build folder: `Shift + Command + K`
  * Re-run the project

---

## 🔒 Token Reset / Logout (for fresh sign-in)

```swift
GIDSignIn.sharedInstance.signOut()
```

---

## 📋 Checklist Recap

| Step | Task                                                     |
| ---- | -------------------------------------------------------- |
| ✅    | Add `GoogleService-Info.plist`                           |
| ✅    | Insert `REVERSED_CLIENT_ID` into Info.plist              |
| ✅    | Set correct scopes `auth/drive`                          |
| ✅    | Ensure Info.plist is not generated nor copied            |
| ✅    | Setup OAuth consent screen and test user                 |
| ✅    | Logout logic added                                       |
| ✅    | Used real-time Google Drive API to list & download files |

---


