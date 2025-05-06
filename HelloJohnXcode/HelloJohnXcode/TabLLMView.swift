//
//  TabLLMView.swift
//  HelloJohnXcode
//
//  Created by Johnny on 05/05/2025.
//

import Foundation
import SwiftUI



// ✅ Hardcoded system prompt
let systemPrompt = """
You are Little-Green, an AI agent made by John (Johnny Hung), tasked with suggesting clear and technically sound project field values. The goal is to help John create a job-attractive showcase that appeals to roles like Data Engineer, Python Developer, or AI Engineer on LinkedIn or GitHub.
Each time John gives a project idea or summary, you must respond with suggested values for the following fields — formatted clearly and concisely. Below are the field definitions and reasoning.

🔧 Fields to Fill with AI Suggestions + Reasoning
//Mark- ProjectMeta
1. Project Name
🟢 Why: This title is key to drawing recruiter attention and quickly identifying the tech scope.
 📌 How I choose: Combine platform/tech (e.g. “Xcode”, “Airflow”) with a label or sequence (e.g. “01”, “Dashboard”).
 📈 Goal: Clear, consistent naming across all your projects for visibility and sorting.
2. Focus (max 3 terms)
🟢 Why: These tags help categorize the project under high-level technical families used in hiring filters.
 📌 How I choose: Pick 2–3 from your preferred family set (e.g. ETL, LLM, BI-Dash, K8S, Airflow).
 📈 Goal: Use LinkedIn-style keywords that match job searches without being too narrow.
3. Target Audience
🟢 Why: Framing the audience as job roles clarifies the intent and signals your alignment with hiring profiles.
 📌 How I choose: From core roles such as data engineer, AI engineer, project manager, etc., depending on the tools and business logic in the project.
 📈 Goal: Increase relevance when recruiters view your project portfolio.
4. Description
🟢 Why: This tells what the project does, how it works, and why it matters.
 📌 How I write: Bullet points showing functionality, architecture, and logic. Ends with Little-Green: suggest future feature — ...
 📈 Goal: Present the project clearly to both technical reviewers and hiring managers.
5. Current Action
🟢 Why: Shows project momentum — useful for status logs and daily check-ins.
 📌 How I write: Always begin with a default like:
 "Initial setup completed. Currently syncing project_meta.json to Google Drive."
 📈 Goal: Track progress visibly, maintain structured log flow.
6. Next Action
🟢 Why: Highlights planning skills and logical roadmap.
 📌 How I choose: I follow the current action and suggest the next practical milestone, like extending functionality or integrating new systems.
 📈 Goal: Reflect future-thinking and task ownership.
7. Skills (comma-separated, max 7)
🟢 Why: Skills are parsed by recruiters, ATS, and APIs — this is your technical summary anchor.
 📌 How I choose:
Include tools/techs clearly mentioned in the project.


Add 1–2 future tools if relevant to the planned roadmap.


Clearly state in a comment:


 Little-Green: this skill list includes [X, Y] as future extensions because John mentioned [e.g., AWS migration / BI pipeline idea].
 📈 Goal: Make the skill list immediately useful to job filtering systems, while showing John's growth and planning.



8. Action ID (optional)
🟢 Why: Useful for internal tracking or version control.
 📌 How I write: Leave empty unless explicitly provided.
 📈 Goal: Avoid clutter unless required.

// MARK: - EachAction
{
    "action_id": "UUID",
    "project_id": "Link to project above",
    "action_description": "Detailed log of what was done",
    "action_status": "one of: in-progress, completed, on-hold",
    "action_owner": "johnny or other",
    "related_info": "Additional context or file",
    "created_at": "YYYY-MM-DD",
    "updated_at": "YYYY-MM-DD",
    "next_followup": "Important reminder or next step"
}




📱 Display Style Instruction:
When returning lists of data (e.g., action details or project attributes), avoid Markdown tables. Instead, format each item as a vertical list with clear bullets or labels, like:

🔹 Action 1:
• ID: ...
• Project ID: ...
• Name: ...

🔹 Action 2:
• ID: ...
...

This keeps the output easy to read on narrow mobile screens.



🛑 Important: Response Guardrail

If John says "thanks", "ok", or any friendly closing comment that does not include a technical question or request, **do not generate a follow-up response**. Simply reply with something short and polite like:
"You're welcome!" or "Glad to help!"

Avoid repeating project summaries or action data unless John explicitly asks for them again.

You will always receive project__meta.json and project__actions.json content from John, and your job is to analyze them and assist.


"""



struct TabLLMView: View {
    @State private var userInput = ""
    @State private var extraInfo = ""
    @State private var responseText = ""
    @State private var isCollapsed = true
    @FocusState private var isInputFocused: Bool
    @State private var chatCnt = 1 // History chat cnt
    @State private var historyChatRef = ""
    @State private var systemPrompt = ""
    
    
    @State private var isFetching = false // use for . .. ... processing fetching open-api
    @State private var dotPhase = 0       // use for . .. ... processing fetching open-api
    @State private var loadingDots = ""   // use for . .. ... processing fetching open-api
    let loadingFrames = ["🐦.", "🐦..", "🐦...", "🐦✨", "🐦💭"]
    

    
    var body: some View {
            VStack(spacing: 0) {

                // 🧠 Terminal-style dynamic input field
                VStack(alignment: .leading, spacing: 8) {
                    ZStack(alignment: .topLeading) {
                        if userInput.isEmpty {
                            Text("Type your prompt...")
                                .foregroundColor(.green.opacity(0.4))
                                .padding(8)
                                .font(.system(.body, design: .monospaced))
                        }

                        TextEditor(text: $userInput)
                            .focused($isInputFocused)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.green)
                            .padding(8)
                        // 🛠️ Fix for Issue-03: ensure visible full one-line input (avoid clipping bottom of first line)
                            .frame(minHeight: isCollapsed ? 0 : 101, maxHeight: isCollapsed ? 0 : .infinity)
                            .scrollContentBackground(.hidden)
                            .background(Color.black.opacity(0.95))
                            .cornerRadius(8)
                    }

                    // 🔘 Icon bar below input
                    HStack(spacing: 20) {
                        Button(action: sendToLLM) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                        }
                        Button(action: {}) {
                            Image(systemName: "mic")
                                .foregroundColor(.green.opacity(0.5))
                                .font(.title2)
                        }
                        Button(action: {
                            withAnimation {
                                isCollapsed.toggle()
                                isInputFocused = !isCollapsed
                            }
                        }) {
                            Image(systemName: isCollapsed ? "arrow.down" : "arrow.up")
                                .foregroundColor(.green.opacity(0.6))
                                .font(.title2)
                        }
                        
                        // use ["🐦.", "🐦..", "🐦...", "🐦✨", "🐦💭"] processing
                        Spacer()
                        Text(loadingDots)
                            .font(.body)
                            .foregroundColor(.green)
                            .bold()

                        // Add more buttons in future
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
                .padding()

                Divider()

                // 🧾 Response display
                ScrollView {
                    Group {
                        if !responseText.isEmpty, !responseText.contains("NaN") {
                            Text(.init(responseText))
                                .font(.body)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text("🕵️ No valid response yet. Enter input and tap Send.")
                                .font(.callout)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        }
                    }
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .onTapGesture {
                isInputFocused = false // ✅ tap outside to dismiss keyboard
            }
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    if isFetching {
                        dotPhase = (dotPhase + 1) % loadingFrames.count
                        loadingDots = loadingFrames[dotPhase]
                    } else {
                        loadingDots = ""
                        dotPhase = 0
                    }
                }
            }
        }

        func sendToLLM() {
            
            isFetching = true            //Start Fetcing . .. ..
            
            let projects: [ProjectMeta] = loadProjects(from: "project__meta.json").sorted { $0.updatedAt > $1.updatedAt }
            let actions: [ProjectAction] = loadActions(from: "project__actions.json").sorted { $0.updatedAt > $1.updatedAt }

            let metaSummary = projects.prefix(3).enumerated().map { (index, project) in
                let mirror = Mirror(reflecting: project)
                let properties = mirror.children.compactMap { child in
                    if let label = child.label {
                        return "\(label): \(child.value)"
                    } else {
                        return nil
                    }
                }.joined(separator: "\n")
                return "\(index + 1). ProjectMeta\n\(properties)"
            }.joined(separator: "\n\n")

            let actionSummary = actions.prefix(5).enumerated().map { (index, action) in
                let mirror = Mirror(reflecting: action)
                let properties = mirror.children.compactMap { child in
                    if let label = child.label {
                        return "\(label): \(child.value)"
                    } else {
                        return nil
                    }
                }.joined(separator: "\n")
                return "\(index + 1). EachAction\n\(properties)"
            }.joined(separator: "\n\n")

            let combinedExtraInfo = """
            \(extraInfo)

            --- project list and project-purpose ---
            \(metaSummary)

            --- actions data , decending by time ---
            \(actionSummary)
            """

            print("may-14-debug-show-CombineText: ", combinedExtraInfo)

            testOpenAI(input: userInput, systemPrompt: systemPrompt, extraInfo: combinedExtraInfo) { result in
                let newMessage = """
                🟢 I Say - \(chatCnt):
                \(userInput)

                ⚪️ LittleGreen - \(chatCnt):
                \(result)

                """
                DispatchQueue.main.async {
                    responseText += "\n" + newMessage
                    userInput = ""
                    isCollapsed = true
                    chatCnt += 1
                    historyChatRef += "\n" + newMessage
                    
                    //UpdatedSystepromp:
                    systemPrompt = """
                    \(systemPrompt)
                    
                    // See History Chats: 
                    \(historyChatRef)
                    
                    
                    """
                    
                    isFetching = false // stop procesiing anmiation
                    print(responseText)
                }
            }
        }
}

