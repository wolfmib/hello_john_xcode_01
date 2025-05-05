//
//  TabOutputView.swift
//  HelloJohnXcode
//
//  Created by Johnny on 04/05/2025.
//

import Foundation
import SwiftUI


struct TabOutputView: View {
    // updated sorted
    @State private var projects: [ProjectMeta] = loadProjects(from: "project__meta.json").sorted { $0.updatedAt > $1.updatedAt }
    @State private var  actions: [ProjectAction] = loadActions(from: "project__actions.json").sorted { $0.updatedAt > $1.updatedAt }

    
    
    // implement view as bulle-point may-03-2025
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) { // increased spacing for double line effect
                Text("📁 Loaded Projects")
                    .font(.headline)

                ForEach(projects) { project in
                    Text("""
                    • Project Name: \(project.projectName)
                    • Current Action: \(project.currentAction)
                    • Created At: \(project.createdAt)
                    """)
                    .font(.subheadline)
                }

                Divider().padding(.vertical)

                Text("📌 Loaded Actions")
                    .font(.headline)

                ForEach(actions) { action in
                    Text("""
                    • Project ID: \(action.projectId)
                    • Description: \(action.description)
                    • Created At: \(action.createdAt)
                    • Status: [\(action.status)]
                    """)
                    .font(.caption)
                }
            }
            .padding()
        }
    }
}

