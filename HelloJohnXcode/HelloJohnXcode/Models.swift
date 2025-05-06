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


// load josn
func loadJSONPreview(fileName: String) -> String {
    let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent(fileName)
    
    do {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)
        return lines.prefix(3).joined(separator: "\n") // show only first 3 lines
    } catch {
        return "❌ Failed to load \(fileName): \(error.localizedDescription)"
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


//Little Green use temparedu 0.3 to make the summary correct (less creativity)
func testOpenAI(input: String, systemPrompt: String = "", extraInfo: String = "", temperature: Double = 0.3, completion: @escaping (String) -> Void) {
    guard let token = loadCloseApiToken() else {
        completion("❌ Token not loaded")
        return
    }

    let url = URL(string: "https://api.openai.com/v1/chat/completions")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let messages: [[String: Any]] = [
        ["role": "system", "content": systemPrompt],
        ["role": "user", "content": "\(input)\n\nContext:\n\(extraInfo)"]
    ]

    let body: [String: Any] = [
        "model": "gpt-4o",
        "temperature": temperature,
        "messages": messages
    ]

    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
    } catch {
        completion("❌ Failed to serialize request body: \(error.localizedDescription)")
        return
    }

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion("❌ API Error: \(error.localizedDescription)")
            return
        }

        guard let data = data else {
            completion("❌ No data received from API")
            return
        }

        // Attempt to parse the response
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                completion("\n" + content)
            } else {
                // Log the raw response for debugging
                let rawResponse = String(data: data, encoding: .utf8) ?? "Unable to decode response"
                print("⚠️ Unexpected API format. Raw response: \(rawResponse)")
                completion("⚠️ Unexpected API format")
            }
        } catch {
            let rawResponse = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("❌ Failed to parse JSON. Error: \(error.localizedDescription). Raw response: \(rawResponse)")
            completion("❌ Failed to parse API response")
        }
    }.resume()
}


