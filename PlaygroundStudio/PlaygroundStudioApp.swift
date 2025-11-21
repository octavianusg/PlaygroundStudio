//
//  PlaygroundStudioApp.swift
//  PlaygroundStudio
//
//  Created by octavianus on 18/11/25.
//

import SwiftUI

@main
struct PlaygroundStudioApp: App {
    var body: some Scene {
        WindowGroup {
            if #available(macOS 26.0, *) {
                PromptInputView(prompt: PromptInput())
            } else {
                Text("Not Available")
            }
        }
        
        WindowGroup(id: "content", for: PlaygroundProject.self) { project in
            if let project = project.wrappedValue {
                ContentView(
                    project: project ,
                    walkthrough: nil
                )
            } else {
                Text("No Project")
            }
        }
    }
}
