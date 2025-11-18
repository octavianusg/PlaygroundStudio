//
//  WalkthroughStep.swift
//  PlaygroundStudio
//
//  Created by User on 18/11/25.
//


import Foundation

public struct FileContent: Equatable {
    public var title: String
    public var swiftSource: String
    public var steps: [FileStep]

    public init(title: String, swiftSource: String, steps: [FileStep]) {
        self.title = title
        self.swiftSource = swiftSource
        self.steps = steps
    }
}

public struct FileStep: Identifiable, Equatable {
    public let id = UUID()
    public var title: String
    public var body: String

    public init(title: String, body: String) {
        self.title = title
        self.body = body
    }
}



public extension FileContent {
    static let sample: FileContent = .init(
        title: "Create your own story",
        swiftSource: """
                    import SwiftUI

                    struct FirstChapter: Story {
                        var myStory: some Prose {
                            TitlePage {
                                Picture(.spaceWhale)
                                Chapter(number: 1)
                                Title(\"Your Title\")
                            }
                        }
                    }

                    struct FirstChapterView_Previews: PreviewProvider {
                        static var previews: some View {
                            StoryNodePresenter(node: FirstChapter().myStory.storyNode, book: MyStoryBook())
                                .storyNodeBackgroundStyle()
                        }
                    }
                """
        ,
        steps: [
            FileStep(
                title: "Create your own story",
                body: "The first chapter of your short story is an important one. You want to catch your reader's attention right from the start to set the scene.\n\nTo add the title of your chapter, edit Title(\"Your Title\")."
            ),
            FileStep(
                title: "Add a picture",
                body: "Try changing the picture or adding another element to your title page."
            )
        ]
    )
}
