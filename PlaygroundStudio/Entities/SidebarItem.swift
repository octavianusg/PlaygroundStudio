//
//  SidebarItem.swift
//  PlaygroundStudio
//
//  Created by User on 18/11/25.
//
import Foundation

struct SidebarItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var iconName: String
    var children: [SidebarItem]?
    var content: FileContent?

    static func ==(lhs: SidebarItem, rhs: SidebarItem) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension SidebarItem {
    static let sample: [SidebarItem] =  [
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
}
