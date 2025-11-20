import SwiftUI
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(macOS 26.0, *)
struct PromptInputView: View {
    @State var prompt: String = ""
    @State var output: String = ""
    var onSubmit: (() -> Void)?
    var onClear: (() -> Void)?
    
    @State private var isResponding = false
    
    @Environment(\.openWindow) private var openWindow
    
    #if canImport(FoundationModels)
        @State private var playgroundGenerator: PlaygroundBookGenerator?
    #endif

    // MARK: - Subviews to help the type-checker
    @ViewBuilder
    private func PromptControls() -> some View {
        HStack {
            Button("Generate new Swift Playground Book") {
                Task { await generate() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isResponding || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Button("Clear") {
                prompt = ""
                output = ""
                onClear?()
            }
            .buttonStyle(.bordered)
        }
        .task {
            #if canImport(FoundationModels)
            playgroundGenerator = PlaygroundBookGenerator()
            playgroundGenerator?.prewarm()
            #endif
        }
    }

    @ViewBuilder
    private func ProjectSummaryView() -> some View {
        #if canImport(FoundationModels)
        if let project = playgroundGenerator?.playgroundProject {
            VStack(alignment: .leading, spacing: 12) {
                if let description = project.description {
                    Text("Project Description")
                        .font(.headline)
                    Text(description)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(4)
                }

                if let chapters = project.chapters, !chapters.isEmpty {
                    Text("Chapters")
                        .font(.headline)
                    ForEach(Array(chapters.enumerated()), id: \.offset) { _, chapter in
                        VStack(alignment: .leading, spacing: 6) {
                            if let title = chapter.name { Text(title).font(.subheadline).bold() }
                            if let chapterDescription = chapter.description {
                                Text(chapterDescription)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            if let modules = chapter.modules, !modules.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Modules").font(.footnote).bold()
                                    ForEach(Array(modules.enumerated()), id: \.offset) { _, module in
                                        VStack(alignment: .leading, spacing: 2) {
                                            if let moduleName = module.name { Text(moduleName).font(.footnote) }
                                            if let moduleDescription = module.moduleDescription {
                                                Text(moduleDescription)
                                                    .font(.system(.footnote, design: .monospaced))
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                Button {
                    if let fullProject = playgroundGenerator?.playgroundProject {
                        //openWindow(id: "content", value: fullProject)
                    }
                } label: { Text("Open Result in New Window") }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
        } else {
            Text("No project generated yet.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
        }
        #else
        Text("FoundationModels not available in this build.")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
        #endif
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Generative Prompt")
                .font(.headline)

            HStack {
                TextField("Type your prompt…", text: $prompt, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.roundedBorder)
            }

            PromptControls()

            ScrollView {
                ProjectSummaryView()
            }
            .background(Color.secondary)
            .cornerRadius(8)
        }
        .padding()
    }
    
    private func generate() async {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else { return }
        
        isResponding = true
        defer {
            isResponding = false
        }
        
        #if canImport(FoundationModels)
        do {
            let _ = try? await playgroundGenerator?.generateContent(prompt: trimmedPrompt)
            onSubmit?()
            //openWindow(value: trimmedPrompt)
        } catch {
            output = "Error: \(error.localizedDescription)"
        }
        #else
        output = "(Simulated) \(trimmedPrompt)"
        onSubmit?()
        #endif
    }
}

#Preview{
    if #available(macOS 26.0, *) {
        PromptInputView()
            .previewDisplayName("Prompt Input")
    } else {
        // Fallback on earlier versions
        Text("Mac not supported")
    }
}
