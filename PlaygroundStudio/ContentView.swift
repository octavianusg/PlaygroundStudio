//
//  ContentView.swift
//  PlaygroundStudio
//
//  Created by octavianus on 18/11/25.
//

import SwiftUI

struct ContentView: View {

    // MARK: - Right pane mode

    private enum RightPaneMode {
        case preview
        case walkthrough
    }

    @State private var rightPaneMode: RightPaneMode = .preview

    // Sidebar data
    @State private var sidebarItems: [SidebarItem] = [
        SidebarItem(name: "Chapters", iconName: "folder.fill", children: [
            SidebarItem(name: "FirstChapter.swift", iconName: "doc.text"),
            SidebarItem(name: "SecondChapter.swift", iconName: "doc.text"),
            SidebarItem(name: "ThirdChapter.swift", iconName: "doc.text")
        ]),
        SidebarItem(name: "Walkthroughs", iconName: "folder.fill", children: [
            SidebarItem(name: "Story Walkthrough", iconName: "book"),
            SidebarItem(name: "Advanced Tips", iconName: "lightbulb")
        ])
    ]

    var body: some View {
        GeometryReader { proxy in
            NavigationSplitView {
                SidebarView(items: sidebarItems)
            } content: {
                EditorView()
            } detail: {
                Group {
                    switch rightPaneMode {
                    case .preview:
                        PreviewView()
                    case .walkthrough:
                        WalkthroughView()
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
    ContentView()
}
