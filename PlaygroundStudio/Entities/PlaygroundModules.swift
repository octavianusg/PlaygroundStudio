//
//  SidebarItem.swift
//  PlaygroundStudio
//
//  Created by User on 18/11/25.
//
import Foundation
import FoundationModels

#if canImport(Foundation)
extension FileContent {
    // Adjust these to match your actual FileContent API
    init?(data: Data) {
        // If FileContent already has a data-based initializer, call it here.
        // Otherwise, return nil to keep decoding resilient.
        return nil
    }

    var dataRepresentation: Data? { nil }
}
#endif

@Generable
struct PlaygroundModules: Identifiable, Codable, Hashable {

    var id = UUID()
    
    @Guide(description: "Name of the module")
    var name: String
    
    @Guide(description: "Describe the objective of this modules on what the students can archieve")
    var moduleDescription: String

    @Guide(description: "The swift code content")
    var content: FileContent?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case moduleDescription = "description"
        case content
    }

    init(id: UUID = UUID(), name: String, moduleDescription: String, content: FileContent? = nil) {
        self.id = id
        self.name = name
        self.moduleDescription = moduleDescription
        self.content = content
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        let name = try container.decode(String.self, forKey: .name)
        let moduleDescription = try container.decode(String.self, forKey: .moduleDescription)
        let content: FileContent?
        if let contentData = try? container.decode(Data.self, forKey: .content) {
            // Initialize FileContent from raw data if your type supports it; otherwise keep nil
            content = FileContent(data: contentData)
        } else {
            content = nil
        }
        self.init(id: id, name: name, moduleDescription: moduleDescription, content: content)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(moduleDescription, forKey: .moduleDescription)
        if let content = content, let data = content.dataRepresentation {
            try container.encode(data, forKey: .content)
        }
    }

    static func ==(lhs: PlaygroundModules, rhs: PlaygroundModules) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
