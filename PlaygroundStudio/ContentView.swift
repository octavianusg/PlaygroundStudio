//
//  ContentView.swift
//  PlaygroundStudio
//
//  Created by octavianus on 18/11/25.
//

import SwiftUI

struct ContentView: View {

    //Data
    @State var sidebarItems: [SidebarItem]
    @State var walkthrough: Walkthrough?
    
    
    private enum RightPaneMode {
        case preview
        case walkthrough
    }
    @State private var rightPaneMode: RightPaneMode = .preview
    
    var body: some View {
        GeometryReader { proxy in
            NavigationSplitView {
                SidebarView(items: $sidebarItems)
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
    ContentView(
        sidebarItems: SidebarItem.sample, walkthrough: Walkthrough.sample
    )
}
