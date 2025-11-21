//
//  PlaygroundChapter.swift
//  PlaygroundStudio
//
//  Created by User on 20/11/25.
//

import Foundation
import FoundationModels

@Generable
struct PlaygroundChapter: Identifiable, Codable, Hashable {

    var id = UUID()
    
    @Guide(description: "Name of the module or chapter depending on the kind of item.This will be the name of the playground chapter")
    var name: String
    
    @Guide(description: "Describe the objective of this chapter on what the students can archieve and what the playground experiences will do")
    var description: String = ""
    
    @Guide(description: "The modules that is needed which will contain the swift content and step by step instructions")
    var modules: [PlaygroundModules]
    
    var iconName: String = ""
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case modules
        case iconName
    }

    init(id: UUID = UUID(), name: String, description: String = "", modules: [PlaygroundModules], iconName: String = "document.on.document") {
        self.id = id
        self.name = name
        self.description = description
        self.modules = modules
        self.iconName = iconName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        let name = try container.decode(String.self, forKey: .name)
        let description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        let modules = try container.decode([PlaygroundModules].self, forKey: .modules)
        let iconName = try container.decodeIfPresent(String.self, forKey: .iconName) ?? "document.on.document"
        self.init(id: id, name: name, description: description, modules: modules, iconName: iconName)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(modules, forKey: .modules)
        try container.encode(iconName, forKey: .iconName)
    }

    static func ==(lhs: PlaygroundChapter, rhs: PlaygroundChapter) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static let sample: [PlaygroundChapter] = {
        let modules: [PlaygroundModules] = [
            PlaygroundModules(name: "Introduction", moduleDescription: ""),
            PlaygroundModules(name: "GettingStarted.swift", moduleDescription: "")
        ]
        var chapter = PlaygroundChapter(name: "Sample Chapter", modules: modules)
        return [chapter]
    }()
}

