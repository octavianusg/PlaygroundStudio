//
//  EditorView.swift
//  PlaygroundStudio
//
//  Created by octavianus on 18/11/25.
//

import SwiftUI
import CodeEditorView
import LanguageSupport

/// Top banner that shows the guided tutorial hint, similar to Swift Playgrounds.
struct TutorialBannerView: View {
    let title: String
    let bodyText: String

    @Binding var currentStep: Int
    let totalSteps: Int

    var onBack: (() -> Void)?
    var onNext: (() -> Void)?
    var onClose: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                // Back button and title
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                }

                Spacer()

                // Close button
                if let onClose {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(bodyText)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
                .disabled(currentStep == 1)
                .opacity(currentStep == 1 ? 0.3 : 1.0)

                // Page indicator in the center
                Spacer()
                Text("\(currentStep) of \(totalSteps)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()

                // Next button on the right
                Button(action: { onNext?() }) {
                    HStack(spacing: 4) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(radius: 8, y: 4)
        .padding([.horizontal, .top])
    }
}

/// Main editor view combining the tutorial banner and a code editor.
struct EditorView: View {
    // MARK: - Tutorial state
    @State private var currentStep: Int = 2
    private let totalSteps: Int = 10
    @State private var isTutorialVisible: Bool = true

    // MARK: - Code editor state
    @State private var source: String = """
import SwiftUI\n\nstruct FirstChapter: Story {\n    var myStory: some Prose {\n        TitlePage {\n            Picture(.spaceWhale)\n            Chapter(number: 1)\n            Title(\\"Your Title\\")\n        }\n    }\n}\n\nstruct FirstChapterView_Previews: PreviewProvider {\n    static var previews: some View {\n        StoryNodePresenter(node: FirstChapter().myStory.storyNode, book: MyStoryBook())\n            .storyNodeBackgroundStyle()\n    }\n}\n
"""

    @State private var position: CodeEditor.Position = .init()
    @State private var messages: Set<TextLocated<Message>> = []

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            if isTutorialVisible {
                TutorialBannerView(
                    title: "Create your own story",
                    bodyText: "The first chapter of your short story is an important one. You want to catch your reader's attention right from the start to set the scene.\n\nTo add the title of your chapter, edit Title(\"Your Title\").",
                    currentStep: $currentStep,
                    totalSteps: totalSteps,
                    onBack: handleBack,
                    onNext: handleNext,
                    onClose: handleClose
                )
                .transition(.move(edge: .top).combined(with: .opacity))

                Divider()
                    .transition(.opacity)
            }

            // Code editor area
            CodeEditor(
                text: $source,
                position: $position,
                messages: $messages,
                language: .swift()
            )
            .environment(\.codeEditorTheme,
                         colorScheme == .dark ? Theme.defaultDark : Theme.defaultLight)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .textBackgroundColor))
        }
        .animation(.easeInOut(duration: 0.25), value: isTutorialVisible)
    }

    // MARK: - Tutorial navigation handlers

    private func handleBack() {
        guard currentStep > 1 else { return }
        currentStep -= 1
    }

    private func handleNext() {
        guard currentStep < totalSteps else { return }
        currentStep += 1
    }

    private func handleClose() {
        withAnimation {
            isTutorialVisible = false
        }
    }
}

struct EditorView_Previews: PreviewProvider {
    static var previews: some View {
        EditorView()
            .frame(minWidth: 700, minHeight: 500)
    }
}
