//
//  ActionCard.swift
//  PlaygroundStudio
//
//  Created by User on 18/11/25.
//
import Foundation

struct ActionGroup: WalkthroughContent,Identifiable, Hashable {
    let id = UUID()
    var title: String
    var chapters: [ActionCard]
}

struct ActionCard: Identifiable, Hashable {
    let id = UUID()
    var systemName: String          // e.g. "FirstChapter"
    var title: String               // e.g. "Create your own story"
    var description: String
    var actionTitle: String         // text button title
}
