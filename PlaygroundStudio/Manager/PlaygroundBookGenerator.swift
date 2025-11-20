//
//  AIManager.swift
//  PlaygroundStudio
//
//  Created by User on 18/11/25.
//

import FoundationModels
import Observation

@Observable
final class PlaygroundBookGenerator{
    private var session: LanguageModelSession
    var playgroundProject: PlaygroundProject.PartiallyGenerated?
    var prompt: String?
    
    var error: Error?
    init(){
        self.session = LanguageModelSession(
            tools: [],
            instructions: Instructions {
             """
                Your job is to create a Swift Playground Book module and chapter as a teachers
             """
            })
    }
    
    func generateContent(prompt: String) async throws {
        let stream = session.streamResponse(
            generating: PlaygroundProject.self,
            includeSchemaInPrompt: false,
            options: GenerationOptions(sampling: .greedy)
        ) {
            self.prompt
        }

        for try await partialResponse in stream {
            playgroundProject = partialResponse.content
        }
    }
    
    func prewarm(){
        session.prewarm()
    }
}
