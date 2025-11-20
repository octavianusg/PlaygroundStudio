//
//  EditorView.swift
//  PlaygroundStudio
//
//  Created by octavianus on 18/11/25.
//

import SwiftUI
import CodeEditorView
import LanguageSupport

struct EditorView: View {
    // MARK: - Data source
    @State private var content: FileContent = .sample
    
    
    // In Page Data
    @State private var currentStepIndex: Int = 0
    private var totalSteps: Int { content.steps?.count ?? 0 }
    @State private var isTutorialVisible: Bool = true
    @State private var source: String
    @State private var position: CodeEditor.Position = .init()
    @State private var messages: Set<TextLocated<Message>> = []

    @Environment(\.colorScheme) private var colorScheme

    init() {
        _source = State(initialValue: FileContent.sample.swiftSource)
    }

    var body: some View {
        VStack(spacing: 0) {
            if isTutorialVisible , let steps = content.steps{
                TutorialBannerView(
                    fileStep: steps[currentStepIndex],
                    currentStep: Binding(
                        get: { currentStepIndex + 1 },
                        set: { newValue in
                            let newIndex = max(0, min(totalSteps - 1, newValue - 1))
                            currentStepIndex = newIndex
                        }
                    ),
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
        guard currentStepIndex > 0 else { return }
        currentStepIndex -= 1
    }

    private func handleNext() {
        guard currentStepIndex < totalSteps - 1 else { return }
        currentStepIndex += 1
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
