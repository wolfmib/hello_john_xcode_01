//
//  TabLLMView.swift
//  HelloJohnXcode
//
//  Created by Johnny on 05/05/2025.
//

import Foundation
import SwiftUI

struct TabLLMView: View {
    @State private var userInput = ""
     @State private var extraInfo = ""
     @State private var responseText = ""
    
    // ✅ Hardcoded system prompt
    let systemPrompt = """
    You are Little-Green, an AI agent assisting John in managing project-related tasks for job-showcase purposes.
    You help with reviewing statuses, querying next actions, modifying plans, and offering discussion summaries.

    --- JSON Format Guide ---

    // MARK: - ProjectMeta
    {
        "project_id": "UUID",
        "project_name": "Short title",
        "focus": "Key frameworks or topic to highlight",
        "target_audience": "Intended audience (e.g. recruiter, engineer)",
        "description": "Main purpose or goal of the project",
        "current_action": "Most recent update or task completed",
        "next_action": "Planned next step or milestone",
        "skills": ["List", "Of", "Technologies", "Used"],
        "created_at": "YYYY-MM-DD",
        "updated_at": "YYYY-MM-DD"
    }

    // MARK: - ProjectAction
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

    You will always receive project__meta.json and project__actions.json content from John, and your job is to analyze them and assist.
    """
    
    
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🧠 LLM Playground")
                .font(.title2)

            TextField("User Input", text: $userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            TextField("Extra Info (optional)", text: $extraInfo)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .onChange(of: userInput) { newValue in
                    if newValue.contains("NaN") {
                        print("⚠️ User input contains NaN-like value, clearing")
                        userInput = ""
                    }
                }

            Button("🚀 Send to OpenAI") {
                
                // add proejc-info
                let projects: [ProjectMeta] = loadProjects(from: "project__meta.json").sorted { $0.updatedAt > $1.updatedAt }
                let actions: [ProjectAction] = loadActions(from: "project__actions.json").sorted { $0.updatedAt > $1.updatedAt }

                let metaSummary = projects
                    .prefix(3)  // only show top 3 updated
                    .enumerated()
                    .map { (index, project) in
                        let mirror = Mirror(reflecting: project)
                        let properties = mirror.children.compactMap { child in
                            if let label = child.label {
                                return "\(label): \(child.value)"
                            } else {
                                return nil
                            }
                        }
                        let formatted = properties.joined(separator: "\n")
                        return "\(index + 1). ProjectMeta\n\(formatted)"
                    }
                    .joined(separator: "\n\n")

                let actionSummary = actions
                    .prefix(5)
                    .enumerated()
                    .map { (index, action) in
                        let mirror = Mirror(reflecting: action)
                        let properties = mirror.children.compactMap { child in
                            if let label = child.label {
                                return "\(label): \(child.value)"
                            } else {
                                return nil
                            }
                        }
                        let formatted = properties.joined(separator: "\n")
                        return "\(index + 1). ProjectMeta\n\(formatted)"
                    }
                    .joined(separator: "\n\n")
                
                
                let combinedExtraInfo = """
                \(extraInfo)

                --- project list and project-purpose ---
                \(metaSummary)

                --- actions summary decending by time ---
                \(actionSummary)
                """
                
                print("may-14-debug-show-CombineText: ",combinedExtraInfo)
                testOpenAI(input: userInput, systemPrompt: systemPrompt, extraInfo: combinedExtraInfo) { result in
                    DispatchQueue.main.async {
                        responseText = result
                        print(responseText)
                    }
                }
            }

            ScrollView {
                
                // bot-say: gorup help robust the logic to prevent nan error
                Group {
                    if !responseText.isEmpty, !responseText.contains("NaN") {
                        Text(.init(responseText))  // ✅ Markdown enabled
                            .font(.body)
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
        .padding()
    }
}

