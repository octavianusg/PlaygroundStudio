//
//  WalkthroughView.swift
//  PlaygroundStudio
//
//  Created by octavianus on 18/11/25.
//

import SwiftUI

struct WalkthroughView: View {

    // Intro content
    @ObservedObject var walkthrough: Walkthrough

    // Editing state
    @State private var isEditing: Bool = false
    @State private var isShowingEditor: Bool = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    ForEach(walkthrough.content, id: \.title) { content in
                        if let descriptionCard = content as? DescriptionCard {
                            descriptionCardView(for: descriptionCard)
                        }
                        if let actionCard = content as? ActionGroup {
                            actionCardView(for: actionCard)
                        }

                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 40)
            }

            // Top-right edit toggle
            VStack {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut) {
                            isEditing.toggle()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isEditing ? "pencil.circle.fill" : "pencil.circle")
                            Text(isEditing ? "Done Editing" : "Edit")
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.regularMaterial)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 24)
                    .padding(.top, 16)
                }
                Spacer()
            }

            // Bottom trailing global add button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Menu {
                        Button("New Description") {
                            appendNewDescriptionCard()
                        }
                        Button("New Guide") {
                            appendNewActionGroup()
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .padding()
                            .background(.regularMaterial)
                            .clipShape(Circle())
                            .shadow(radius: 10, y: 4)
                    }
                    .menuStyle(.borderlessButton)
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $isShowingEditor) {
            EditorView()
        }
    }

    private func descriptionCardView(for card: DescriptionCard) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.gray.opacity(0.12))
                .frame(height: 160)
                .overlay(
                    Image(systemName: "photo.on.rectangle.angled")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.secondary.opacity(0.7))
                        .frame(width: 60, height: 60)
                )

            VStack(alignment: .leading, spacing: 16) {
                if isEditing {
                    TextField("Title", text: .constant(card.title))
                        .font(.title3.weight(.semibold))
                } else {
                    Text(card.title)
                        .font(.title3.weight(.semibold))
                }

                if isEditing {
                    TextEditor(text: .constant(card.body))
                        .frame(minHeight: 80)
                        .font(.body)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.secondary.opacity(0.2))
                        )
                } else {
                    Text(card.body)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    // Hook up card-specific action later
                } label: {
                    Text(card.buttonTitle)
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 6)
        )
    }

    // MARK: Guide Section

    private func actionCardView(for actionGroup: ActionGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(actionGroup.title)
                    .font(.title2.weight(.bold))
                Spacer()
                Button {
                    appendChapter(to: actionGroup)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            ForEach(actionGroup.chapters) { chapter in
                guideCard(for: chapter)
            }
        }
    }

    private func guideCard(for guide: ActionCard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "swift")
                    .foregroundColor(.secondary)
                Text(guide.systemName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
            }

            if isEditing {
                TextField("Chapter title", text: .constant(guide.title))
                    .font(.headline)
            } else {
                Text(guide.title)
                    .font(.headline)
            }

            if isEditing {
                TextEditor(text: .constant(guide.description))
                    .frame(minHeight: 60)
                    .font(.subheadline)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary.opacity(0.2))
                    )
            } else {
                Text(guide.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                // Navigate to associated file / chapter
            } label: {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.blue)
                    Text(guide.actionTitle)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.primary.opacity(0.07))
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func appendChapter(to group: ActionGroup) {
        guard let groupIndex = walkthrough.content.firstIndex(where: { ($0 as? ActionGroup)?.id == group.id }) else { return }
        var currentGroup = walkthrough.content[groupIndex] as! ActionGroup
        let chapterIndex = currentGroup.chapters.count + 1
        let newChapter = ActionCard(systemName: "Chapter\(chapterIndex)", title: "New chapter \(chapterIndex)", description: "Describe this chapter...", actionTitle: "Open chapter \(chapterIndex)")
        currentGroup.chapters.append(newChapter)
        walkthrough.content[groupIndex] = currentGroup
    }

    private func appendNewActionGroup() {
        let index = walkthrough.content.filter { $0 is ActionGroup }.count + 1
        let newGroup = ActionGroup(title: "New guide \(index)", chapters: [])
        walkthrough.content.append(newGroup)
    }

    private func appendNewDescriptionCard() {
        let index = walkthrough.content.filter { $0 is DescriptionCard }.count + 1
        let card = DescriptionCard(title: "New description \(index)", body: "Describe this section...", buttonTitle: "Action \(index)")
        walkthrough.content.append(card)
    }
}

// MARK: - Preview

struct WalkthroughView_Previews: PreviewProvider {
    static var previews: some View {
        WalkthroughView(walkthrough: Walkthrough.sample)
            .frame(minWidth: 500, minHeight: 900)
    }
}
