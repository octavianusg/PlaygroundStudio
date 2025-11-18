//
//  Walkthrough.swift
//  PlaygroundStudio
//
//  Created by User on 18/11/25.
//

import Foundation
import Combine

protocol WalkthroughContent {
    var title: String { get set }
}

final class Walkthrough: ObservableObject {
    @Published var content: [WalkthroughContent]

    init(content: [WalkthroughContent]) {
        self.content = content
    }
}

extension Walkthrough {
    static var sample = Walkthrough(
        content: [
            DescriptionCard(
                title: "In this sample, you get the opportunity to write two different stories.",
                body:     """
                        The first is a linear short story, like one you might find in a book at the library. You’ll write three chapters for this short story, and after changing up the cover and adding a dedication, you’ll have your own electronic book.

                        For the second story, you create different paths that take your reader on different journeys, depending on their choices. Which kind of story inspires the author in you?

                        It’s time to harness your creative writing skills.
                        """
                , buttonTitle: "Start Walkthrough"),
            ActionGroup(title: "Story challenges", chapters: [
                ActionCard(
                    systemName: "FirstChapter",
                    title: "Create your own story",
                    description: "Create your own short story based on the image and story suggestions in this challenge.",
                    actionTitle: "Create your own story"
                ),
                ActionCard(
                    systemName: "SecondChapter",
                    title: "Keep the story going",
                    description: "Keep building your book by adding a second chapter.",
                    actionTitle: "Keep the story going"
                ),
                ActionCard(
                    systemName: "ThirdChapter",
                    title: "Finish strong",
                    description: "Wrap up your book by writing a compelling final chapter.",
                    actionTitle: "Finish your story"
                )
            ])
        ]
    )
}
