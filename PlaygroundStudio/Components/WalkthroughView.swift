//
//  WalkthroughView.swift
//  PlaygroundStudio
//
//  Created by octavianus on 18/11/25.
//

import SwiftUI

// MARK: - Models


struct DescriptionCard: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var body: String
    var buttonTitle: String
}

struct WalkthroughGuide: Identifiable, Hashable {
    let id = UUID()
    var systemName: String          // e.g. "FirstChapter"
    var title: String               // e.g. "Create your own story"
    var description: String
    var actionTitle: String         // text button title
}

struct GuideGroup: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var chapters: [WalkthroughGuide]
}

struct WalkthroughView: View {

    // Intro content
    @State private var introTitle: String = "In this sample, you get the opportunity to write two different stories."
    @State private var introDescription: String =
    """
The first is a linear short story, like one you might find in a book at the library. You’ll write three chapters for this short story, and after changing up the cover and adding a dedication, you’ll have your own electronic book.

For the second story, you create different paths that take your reader on different journeys, depending on their choices. Which kind of story inspires the author in you?

It’s time to harness your creative writing skills.
"""
    @State private var introButtonTitle: String = "Start Walkthrough"

    // Guides grouped into sections with chapters
    @State private var guideGroups: [GuideGroup] = [
        GuideGroup(
            title: "Story challenges",
            chapters: [
                WalkthroughGuide(
                    systemName: "FirstChapter",
                    title: "Create your own story",
                    description: "Create your own short story based on the image and story suggestions in this challenge.",
                    actionTitle: "Create your own story"
                ),
                WalkthroughGuide(
                    systemName: "SecondChapter",
                    title: "Keep the story going",
                    description: "Keep building your book by adding a second chapter.",
                    actionTitle: "Keep the story going"
                ),
                WalkthroughGuide(
                    systemName: "ThirdChapter",
                    title: "Finish strong",
                    description: "Wrap up your book by writing a compelling final chapter.",
                    actionTitle: "Finish your story"
                )
            ]
        )
    ]

    // Editing state
    @State private var isEditing: Bool = false
    @State private var isShowingEditor: Bool = false

    // Description component cards (image + title + description + button)
    @State private var descriptionCards: [DescriptionCard] = []

    // MARK: Actions

    private func addNewGuide() {
        let index = guideGroups.count + 1
        let newGroup = GuideGroup(
            title: "New guide \(index)",
            chapters: []
        )
        guideGroups.append(newGroup)
    }

    private func addNewDescriptionCard() {
        let index = descriptionCards.count + 1
        let card = DescriptionCard(
            title: "New description \(index)",
            body: "Describe this section...",
            buttonTitle: "Action \(index)"
        )
        descriptionCards.append(card)
    }

    var body: some View {
        ZStack {
            ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                introSection
                ForEach($descriptionCards) { $card in
                    descriptionCardView(for: $card)
                }
                guideSection
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
                            addNewDescriptionCard()
                        }
                        Button("New Guide") {
                            addNewGuide()
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

    // MARK: Intro Section

    private var introSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header image placeholder (replace with your asset)
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.orange, Color.yellow, Color.green],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 220)
                .overlay(
                    Image(systemName: "book.closed.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 80, height: 80)
                )

            VStack(alignment: .leading, spacing: 16) {
                if isEditing {
                    TextField("Intro title", text: $introTitle)
                        .font(.title2.weight(.semibold))
                } else {
                    Text(introTitle)
                        .font(.title2.weight(.semibold))
                }

                if isEditing {
                    TextEditor(text: $introDescription)
                        .frame(minHeight: 140)
                        .font(.body)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.2))
                        )
                } else {
                    Text(introDescription)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    isShowingEditor = true
                } label: {
                    Text(introButtonTitle)
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: .black.opacity(0.15), radius: 18, x: 0, y: 8)
        )
    }

    private func descriptionCardView(for card: Binding<DescriptionCard>) -> some View {
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
                    TextField("Title", text: card.title)
                        .font(.title3.weight(.semibold))
                } else {
                    Text(card.wrappedValue.title)
                        .font(.title3.weight(.semibold))
                }

                if isEditing {
                    TextEditor(text: card.body)
                        .frame(minHeight: 80)
                        .font(.body)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.secondary.opacity(0.2))
                        )
                } else {
                    Text(card.wrappedValue.body)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    // Hook up card-specific action later
                } label: {
                    Text(card.wrappedValue.buttonTitle)
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

    private var guideSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach($guideGroups) { $group in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        if isEditing {
                            TextField("Guide title", text: $group.title)
                                .font(.title2.weight(.bold))
                        } else {
                            Text($group.wrappedValue.title)
                                .font(.title2.weight(.bold))
                        }

                        Spacer()

                        Button {
                            addChapter(to: $group.wrappedValue)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }

                    ForEach($group.chapters) { $chapter in
                        guideCard(for: $chapter)
                    }
                }
            }
        }
    }

    private func guideCard(for guide: Binding<WalkthroughGuide>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "swift")
                    .foregroundColor(.secondary)
                Text(guide.wrappedValue.systemName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
            }

            if isEditing {
                TextField("Chapter title", text: guide.title)
                    .font(.headline)
            } else {
                Text(guide.wrappedValue.title)
                    .font(.headline)
            }

            if isEditing {
                TextEditor(text: guide.description)
                    .frame(minHeight: 60)
                    .font(.subheadline)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary.opacity(0.2))
                    )
            } else {
                Text(guide.wrappedValue.description)
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
                    Text(guide.wrappedValue.actionTitle)
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

    private func addChapter(to group: GuideGroup) {
        guard let groupIndex = guideGroups.firstIndex(where: { $0.id == group.id }) else { return }
        let chapterIndex = guideGroups[groupIndex].chapters.count + 1
        let newChapter = WalkthroughGuide(
            systemName: "Chapter\(chapterIndex)",
            title: "New chapter \(chapterIndex)",
            description: "Describe this chapter...",
            actionTitle: "Open chapter \(chapterIndex)"
        )
        guideGroups[groupIndex].chapters.append(newChapter)
    }
}

// MARK: - Preview

struct WalkthroughView_Previews: PreviewProvider {
    static var previews: some View {
        WalkthroughView()
            .frame(minWidth: 500, minHeight: 900)
    }
}
