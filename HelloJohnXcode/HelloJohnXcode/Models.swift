//
//  Models.swift
//  HelloJohnXcode
//
//  Created by Johnny on 04/05/2025.
//

import Foundation

// MARK: - Project Model
struct ProjectMeta: Codable, Identifiable {
    let id: String
    let projectName: String
    let focus: String
    let targetAudience: String
    let description: String
    let currentAction: String
    let nextAction: String
    let skills: [String]
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id = "project_id"
        case projectName = "project_name"
        case focus, targetAudience = "target_audience", description
        case currentAction = "current_action"
        case nextAction = "next_action"
        case skills, createdAt = "created_at", updatedAt = "updated_at"
    }
}
// MARK: - Action Model
struct ProjectAction: Codable, Identifiable {
    let id: String
    let projectId: String
    let description: String
    let status: String
    let owner: String
    let relatedInfo: String
    let createdAt: String
    let updatedAt: String
    let nextFollowup: String

    enum CodingKeys: String, CodingKey {
        case id = "action_id"
        case projectId = "project_id"
        case description = "action_description"
        case status = "action_status"
        case owner = "action_owner"
        case relatedInfo = "related_info"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case nextFollowup = "next_followup"
    }
}

// MARK: - Load JSON helpers
func loadProjects(from fileName: String) -> [ProjectMeta] {
    loadJSON(fileName: fileName)
}

func loadActions(from fileName: String) -> [ProjectAction] {
    loadJSON(fileName: fileName)
}

private func loadJSON<T: Decodable>(fileName: String) -> [T] {
    let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent(fileName)

    do {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([T].self, from: data)
    } catch {
        print("❌ Failed to decode \(fileName): \(error)")
        return []
    }
}



// load open-api token
func loadEnvToken() -> String {
    let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("JA_ENV.json")

    do {
        let data = try Data(contentsOf: fileURL)
        if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: String]],
           let token = jsonArray.first?["CLOSE_API_TOKEN"] {
            return token
        }
    } catch {
        print("❌ Failed to load CLOSE_API_TOKEN: \(error)")
    }

    return "❌ Token Not Found"
}



