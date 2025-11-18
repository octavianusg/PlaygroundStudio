//
//  Untitled.swift
//  PlaygroundStudio
//
//  Created by octavianus on 18/11/25.
//

import SwiftUI

struct SidebarItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var iconName: String
    var children: [SidebarItem]?

    static func ==(lhs: SidebarItem, rhs: SidebarItem) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct SidebarView: View {
    let items: [SidebarItem]
    @State private var selectedItem: SidebarItem? = nil
    
    var body: some View {
            List(items, children: \.children, selection: $selectedItem) { item in
                if item.children != nil {
                    Label(item.name, systemImage: item.iconName)
                } else {
                    NavigationLink(value: item) {
                        Label(item.name, systemImage: item.iconName)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Sidebar")
    }
}

struct SidebarView_Previews: PreviewProvider {
    // Sample nested data for preview (folders with pages)
    static let sampleData: [SidebarItem] = [
        SidebarItem(name: "Lessons", iconName: "folder.fill", children: [
            SidebarItem(name: "Lesson 1", iconName: "doc.text"),
            SidebarItem(name: "Lesson 2", iconName: "doc.text")
        ]),
        SidebarItem(name: "Challenges", iconName: "folder.fill", children: [
            SidebarItem(name: "Challenge 1", iconName: "doc.text"),
            SidebarItem(name: "Challenge 2", iconName: "doc.text"),
            SidebarItem(name: "Advanced", iconName: "folder.fill", children: [
                SidebarItem(name: "Challenge 3", iconName: "doc.text")
            ])
        ]),
        SidebarItem(name: "Welcome", iconName: "doc.text")
    ]
    
    static var previews: some View {
        SidebarView(items: sampleData)
            .frame(minWidth: 300, minHeight: 200)  // set a reasonable frame for preview
    }
}

