//
//  API.swift
//  LiveObjectRecognition
//
//  Created by Raphael Iniesta Reis on 23/04/25.
//

import Foundation

struct GitHubFile: Decodable {
    let content: String
}

struct Pessoas: Decodable {
    var pessoas: Int
}

func fetchPessoas() async throws -> Int {
    let token = ""
    let owner = "RaphaelIniesta"
    let repo = "JSONContadorDeGente"
    let path = "pessoas.json"
    let branch = "main"
    
    let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/contents/\(path)?ref=\(branch)")!
    
    var request = URLRequest(url: url)
    request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
    
    let (data, _) = try await URLSession.shared.data(for: request)
    
    let gitHubFile = try JSONDecoder().decode(GitHubFile.self, from: data)
    
    let cleanContent = gitHubFile.content
        .replacingOccurrences(of: "\n", with: "")
        .replacingOccurrences(of: "\r", with: "")
    
    guard let jsonData = Data(base64Encoded: cleanContent) else {
        throw NSError(domain: "Base64Error", code: 0, userInfo: nil)
    }
    
    let decoded = try JSONDecoder().decode(Pessoas.self, from: jsonData)
    
    return decoded.pessoas
}
