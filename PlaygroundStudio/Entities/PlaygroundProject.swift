//
//  PlaygroundProject.swift
//  PlaygroundStudio
//
//  Created by User on 20/11/25.
//

import Foundation
import FoundationModels


@Generable
struct PlaygroundProject: Identifiable, Codable, Hashable {
    
    var id = UUID()
    
    @Guide(description: "name of the project")
    var name: String
    
    @Guide(description: """
                This will be desription of the
                1. **A brief Feynman-style explanation** of the concept written for the student’s level.
                2. **Three sequenced activities**, each containing:
                   * **Title**
                   * **Concept focus**
                   * **SpriteKit setup** (nodes, physics bodies, asset pack items, layout)
                   * **Gesture-based interactions** (detailed, step-by-step)
                   * **Feedback mechanics** (collisions, gravity changes, animations, sounds, visual states)
                   * **Learner discovery**: what the student should realize through the interaction
""")
    var description: String
    
    @Guide(description: "All chapters needed for the teachers complete the learning objective")
    var chapters: [PlaygroundChapter]
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case chapters
    }

    init(id: UUID = UUID(), name: String, description: String, chapters: [PlaygroundChapter]) {
        self.id = id
        self.name = name
        self.description = description
        self.chapters = chapters
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let description = try container.decode(String.self, forKey: .description)
        let chapters = try container.decode([PlaygroundChapter].self, forKey: .chapters)
        self.init(id: id, name: name, description: description, chapters: chapters)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(chapters, forKey: .chapters)
    }

    static func == (lhs: PlaygroundProject, rhs: PlaygroundProject) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    
    static var sample: PlaygroundProject = PlaygroundProject(id: UUID(),
                                                             name: "The Fair Share Slicer",
                                                             description: "",
                                                             chapters: [
                                                                .init(name: "Pages", modules: [
                                                                    .init(name: "The Fair Share Slicer", moduleDescription: ""),
                                                                    .init(name: "The Shape Splitter Challenge", moduleDescription: ""),
                                                                    .init(name: "The Fraction Size Sorter", moduleDescription: "")
                                                                ])
                                                             ])
    
}

