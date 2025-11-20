//
//  Untitled.swift
//  PlaygroundStudio
//
//  Created by octavianus on 18/11/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct SidebarView: View {
    @Binding var items: [PlaygroundChapter]
    @State private var selectedItem: PlaygroundChapter? = nil
    @State private var editingItemID: UUID? = nil
    @State private var editingModuleID: UUID? = nil
    @FocusState private var isEditingFocused: Bool
    @State private var expandedChapters: Set<UUID> = []

    @State private var dropTargetModuleID: UUID? = nil
    @State private var dropInsertAbove: Bool = true

    private func addNewChapter() {
        let count = items.count + 1
        let newItem = PlaygroundChapter(name: "New Chapter \(count)", modules: [])
        items.append(newItem)
        selectedItem = newItem
    }

    private func addNewSwiftFile() {
        // Ensure there's at least one chapter to receive the new module
        if items.isEmpty {
            let newChapter = PlaygroundChapter(name: "New Chapter 1", modules: [])
            items.append(newChapter)
            selectedItem = newChapter
        }

        // Resolve target chapter index: prefer selected, else last
        let targetIndex: Int = {
            if let selected = selectedItem, let idx = items.firstIndex(where: { $0.id == selected.id }) {
                return idx
            }
            return items.count - 1
        }()

        // Compute next file index within this chapter only
        let nextIndex = items[targetIndex].modules.count + 1
        let newModule = PlaygroundModules(name: "NewFile\(nextIndex).swift", moduleDescription: "")
        items[targetIndex].modules.append(newModule)
        expandedChapters.insert(items[targetIndex].id)
    }

    private func updateItemName(id: UUID, to newName: String) {
        if let idx = items.firstIndex(where: { $0.id == id }) {
            items[idx].name = newName
        }
    }

    private func updateModuleName(id: UUID, to newName: String) {
        for cIdx in items.indices {
            if let mIdx = items[cIdx].modules.firstIndex(where: { $0.id == id }) {
                items[cIdx].modules[mIdx].name = newName
                return
            }
        }
    }

    private func indexPathForModule(_ moduleID: UUID) -> (chapterIndex: Int, moduleIndex: Int)? {
        for cIdx in items.indices {
            if let mIdx = items[cIdx].modules.firstIndex(where: { $0.id == moduleID }) {
                return (cIdx, mIdx)
            }
        }
        return nil
    }

    private func moveModule(_ moduleID: UUID, toChapter targetChapterIndex: Int, at targetModuleIndex: Int?) {
        guard let source = indexPathForModule(moduleID) else { return }
        // Extract module
        let module = items[source.chapterIndex].modules.remove(at: source.moduleIndex)
        // Compute safe insertion index in target
        let insertIndex: Int
        if let targetModuleIndex { insertIndex = min(max(0, targetModuleIndex), items[targetChapterIndex].modules.count) }
        else { insertIndex = items[targetChapterIndex].modules.count }
        items[targetChapterIndex].modules.insert(module, at: insertIndex)
        expandedChapters.insert(items[targetChapterIndex].id)
    }

    private struct ModuleDropDelegate: DropDelegate {
        let moduleID: UUID
        let chapterID: UUID
        let itemsBinding: Binding<[PlaygroundChapter]>
        let setHover: (UUID?, Bool) -> Void
        let moveAction: (UUID, Int, Int?) -> Void
        let currentInsertAbove: () -> Bool

        func validateDrop(info: DropInfo) -> Bool {
            info.hasItemsConforming(to: [UTType.plainText])
        }

        func dropEntered(info: DropInfo) {
            setHover(moduleID, true)
        }

        func dropUpdated(info: DropInfo) -> DropProposal? {
            setHover(moduleID, true)
            return DropProposal(operation: .move)
        }

        func performDrop(info: DropInfo) -> Bool {
            setHover(nil, true)
            let providers = info.itemProviders(for: [UTType.plainText])
            guard let provider = providers.first else { return false }
            var handled = false
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { (item, _) in
                let idString: String?
                if let data = item as? Data, let s = String(data: data, encoding: .utf8) { idString = s }
                else if let s = item as? String { idString = s }
                else { idString = nil }
                guard let idString, let draggedID = UUID(uuidString: idString) else { return }
                DispatchQueue.main.async {
                    guard let chapterIndex = itemsBinding.wrappedValue.firstIndex(where: { $0.id == chapterID }),
                          let targetIndex = itemsBinding.wrappedValue[chapterIndex].modules.firstIndex(where: { $0.id == moduleID }) else { return }
                    let finalIndex = currentInsertAbove() ? targetIndex : targetIndex + 1
                    moveAction(draggedID, chapterIndex, finalIndex)
                    handled = true
                }
            }
            return handled
        }

        func dropExited(info: DropInfo) {
            setHover(nil, true)
        }
    }

    private struct ChapterRow: View {
        let chapter: PlaygroundChapter
        @Binding var expandedChapters: Set<UUID>
        @Binding var editingItemID: UUID?
        @Binding var selectedItem: PlaygroundChapter?
        @FocusState var isEditingFocused: Bool
        let updateName: (UUID, String) -> Void

        var body: some View {
            HStack(spacing: 6) {
                Button {
                    if expandedChapters.contains(chapter.id) {
                        expandedChapters.remove(chapter.id)
                    } else {
                        expandedChapters.insert(chapter.id)
                    }
                } label: {
                    let isExpanded = expandedChapters.contains(chapter.id)
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 16, height: 16, alignment: .center)
                }
                .buttonStyle(.plain)

                Image(systemName: chapter.iconName)

                if editingItemID == chapter.id {
                    TextField("Name", text: Binding(
                        get: { chapter.name },
                        set: { updateName(chapter.id, $0) }
                    ))
                    .focused($isEditingFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        editingItemID = nil
                        selectedItem = chapter
                    }
                    .onChange(of: isEditingFocused) { focused in
                        if !focused { editingItemID = nil }
                    }
                } else {
                    Text(chapter.name)
                        .font(.headline)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                editingItemID = chapter.id
                isEditingFocused = true
            }
        }
    }

    private struct ModuleRow: View {
        let chapterID: UUID
        let module: PlaygroundModules
        @Binding var items: [PlaygroundChapter]
        @Binding var editingModuleID: UUID?
        @FocusState var isEditingFocused: Bool
        @Binding var dropTargetModuleID: UUID?
        @Binding var dropInsertAbove: Bool
        let updateName: (UUID, String) -> Void
        let moveAction: (UUID, Int, Int?) -> Void

        var body: some View {
            HStack(spacing: 6) {
                Image(systemName: "text.alignleft")
                if editingModuleID == module.id {
                    TextField("Name", text: Binding(
                        get: { module.name },
                        set: { updateName(module.id, $0) }
                    ))
                    .focused($isEditingFocused)
                    .submitLabel(.done)
                    .onSubmit { editingModuleID = nil }
                    .onChange(of: isEditingFocused) { focused in
                        if !focused { editingModuleID = nil }
                    }
                } else {
                    Text(module.name)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                editingModuleID = module.id
                isEditingFocused = true
            }
            .onDrag { NSItemProvider(object: module.id.uuidString as NSString) }
            .overlay(alignment: .topLeading) {
                if dropTargetModuleID == module.id {
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(height: 2)
                        .offset(y: -1)
                }
            }
            .onDrop(of: [UTType.plainText], delegate: ModuleDropDelegate(
                moduleID: module.id,
                chapterID: chapterID,
                itemsBinding: $items,
                setHover: { id, above in
                    dropTargetModuleID = id
                    dropInsertAbove = above
                },
                moveAction: { draggedID, chapterIndex, targetIndex in
                    moveAction(draggedID, chapterIndex, targetIndex)
                },
                currentInsertAbove: { dropInsertAbove }
            ))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: addNewChapter) {
                    Label("New Chapter", systemImage: "folder.badge.plus")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Add a new Chapter")

                Button(action: addNewSwiftFile) {
                    Label("New Module", systemImage: "plus.square.on.square")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Add a new Module")
            }
            .padding([.top, .horizontal], 8)
            .padding(.bottom, 2)

            List {
                ForEach(items, id: \.id) { chapter in
                    Section {
                        ChapterRow(
                            chapter: chapter,
                            expandedChapters: $expandedChapters,
                            editingItemID: $editingItemID,
                            selectedItem: $selectedItem,
                            isEditingFocused: _isEditingFocused,
                            updateName: { id, newName in updateItemName(id: id, to: newName) }
                        )
                        .onDrop(of: [UTType.plainText], isTargeted: nil) { providers in
                            guard let provider = providers.first else { return false }
                            var handled = false
                            _ = provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                                let idString: String?
                                if let data = item as? Data, let s = String(data: data, encoding: .utf8) { idString = s }
                                else if let s = item as? String { idString = s }
                                else { idString = nil }
                                if let idString, let uuid = UUID(uuidString: idString), let chapterIndex = items.firstIndex(where: { $0.id == chapter.id }) {
                                    DispatchQueue.main.async { moveModule(uuid, toChapter: chapterIndex, at: nil) }
                                    handled = true
                                }
                            }
                            return handled
                        }

                        // Module rows (only when expanded)
                        if expandedChapters.contains(chapter.id) {
                            ForEach(chapter.modules, id: \.id) { module in
                                ModuleRow(
                                    chapterID: chapter.id,
                                    module: module,
                                    items: $items,
                                    editingModuleID: $editingModuleID,
                                    isEditingFocused: _isEditingFocused,
                                    dropTargetModuleID: $dropTargetModuleID,
                                    dropInsertAbove: $dropInsertAbove,
                                    updateName: { id, newName in updateModuleName(id: id, to: newName) },
                                    moveAction: { draggedID, chapterIndex, targetIndex in
                                        moveModule(draggedID, toChapter: chapterIndex, at: targetIndex)
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Sidebar")
            .id(items.map { $0.id })
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var items: [PlaygroundChapter] = PlaygroundChapter.sample
        var body: some View {
            SidebarView(items: $items)
                .frame(minWidth: 300, minHeight: 200)
        }
    }
    return PreviewWrapper()
}
