//
//  DescriptionCard.swift
//  PlaygroundStudio
//
//  Created by User on 18/11/25.
//
import Foundation

struct DescriptionCard: WalkthroughContent, Identifiable, Hashable {
    let id = UUID()
    var title: String
    var body: String
    var buttonTitle: String
    var image: String?
}


