//
//  ContentView.swift
//  PlaygroundStudio
//
//  Created by octavianus on 18/11/25.
//

import SwiftUI

struct ContentView: View {

    //Data
    @State var project: PlaygroundProject
    @State var walkthrough: Walkthrough?
    
    init(project: PlaygroundProject, walkthrough: Walkthrough?) {
        self._project = State(initialValue: project)
        self._walkthrough = State(initialValue: walkthrough)
    }
    
    private enum RightPaneMode {
        case preview
        case walkthrough
    }
    
    @State private var rightPaneMode: RightPaneMode = .preview
    
    var body: some View {
        GeometryReader { proxy in
            NavigationSplitView {
                SidebarView(items: $project.chapters)
            } content: {
                EditorView()
            } detail: {
                Group {
                    switch rightPaneMode {
                    case .preview:
                        PreviewView()
                    case .walkthrough:
                        WalkthroughView(walkthrough: Walkthrough.sample)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    //
                } label: {
                    Text("Open in XCode")
                }
                .help("Show live preview")
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                
                Button {
                    rightPaneMode = .preview
                } label: {
                    Label("Preview", systemImage: "rectangle.and.text.magnifyingglass")
                }
                .help("Show live preview")
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(rightPaneMode == .preview ? .accentColor : .secondary)

                Button {
                    rightPaneMode = .walkthrough
                } label: {
                    Label("Walkthrough", systemImage: "text.book.closed")
                }
                .help("Show walkthrough")
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(rightPaneMode == .walkthrough ? .accentColor : .secondary)
            }
        }
    }
}

#Preview {
    ContentView(project: PlaygroundProject(name: "math", description: "test", chapters: [
        PlaygroundChapter(name: "trigonomtry", modules: [
            PlaygroundModules(name: "sin", moduleDescription: "hello")
        ])
        
    ]), walkthrough: nil)
}
