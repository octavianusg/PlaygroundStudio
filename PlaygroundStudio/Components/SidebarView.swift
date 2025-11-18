//
//  Untitled.swift
//  PlaygroundStudio
//
//  Created by octavianus on 18/11/25.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct SidebarView: View {
    @Binding var items: [SidebarItem]
    @State private var selectedItem: SidebarItem? = nil
    @State private var editingItemID: UUID? = nil
    @FocusState private var isEditingFocused: Bool

    // MARK: - Drag & Drop helpers
    private func indexPathForItem(id: UUID) -> (folderIndex: Int?, itemIndex: Int)? {
        // Look for a top-level item
        if let topIndex = items.firstIndex(where: { $0.id == id }) {
            return (folderIndex: nil, itemIndex: topIndex)
        }
        // Look inside folders
        for (folderIdx, folder) in items.enumerated() {
            if let children = folder.children, let childIdx = children.firstIndex(where: { $0.id == id }) {
                return (folderIndex: folderIdx, itemIndex: childIdx)
            }
        }
        return nil
    }

    private func moveFile(withId fileId: UUID, toFolderAt targetFolderIndex: Int) {
        // Ensure target folder has children array
        if items[targetFolderIndex].children == nil { items[targetFolderIndex].children = [] }

        // Find and remove the file from its current location (only files are draggable)
        if let path = indexPathForItem(id: fileId) {
            if let folderIndex = path.folderIndex, let children = items[folderIndex].children {
                // Moving from inside a folder
                let file = children[path.itemIndex]
                guard file.children == nil else { return } // don't move folders as files
                items[folderIndex].children!.remove(at: path.itemIndex)
                items[targetFolderIndex].children!.append(file)
                selectedItem = file
            } else {
                // Moving from top level
                let file = items[path.itemIndex]
                guard file.children == nil else { return }
                items.remove(at: path.itemIndex)
                items[targetFolderIndex].children!.append(file)
                selectedItem = file
            }
        }
    }

    private func addNewFolder() {
        let folders = items.filter { $0.children != nil }
        let folderCount = folders.count + 1
        let newFolder = SidebarItem(name: "New Folder \(folderCount)", iconName: "folder.fill", children: [])
        items.append(newFolder)
        selectedItem = newFolder
    }

    private func addNewSwiftFile() {
        // Resolve a target folder index: prefer "Chapters", else first folder
        let targetFolderIndex: Int? = {
            if let chaptersIndex = items.firstIndex(where: { $0.name == "Chapters" && $0.children != nil }) {
                return chaptersIndex
            }
            return items.firstIndex(where: { $0.children != nil })
        }()

        if let folderIndex = targetFolderIndex {
            // Ensure the folder has a children array to mutate
            if items[folderIndex].children == nil {
                items[folderIndex].children = []
            }
            // Compute next file index within this folder only
            let swiftFilesInFolder = items[folderIndex].children!.filter { $0.iconName == "doc.text" }
            let fileCount = swiftFilesInFolder.count + 1
            let newFile = SidebarItem(name: "NewFile\(fileCount).swift", iconName: "doc.text")
            // Append directly into the binding's nested array to trigger an update
            items[folderIndex].children!.append(newFile)
            selectedItem = newFile
        } else {
            // No folders: create one and then add the first file
            items.append(SidebarItem(name: "New Folder 1", iconName: "folder.fill", children: []))
            let newFile = SidebarItem(name: "NewFile1.swift", iconName: "doc.text")
            let lastIndex = items.count - 1
            items[lastIndex].children!.append(newFile)
            selectedItem = newFile
        }
    }

    private func updateItemName(id: UUID, to newName: String) {
        // Update top-level
        if let idx = items.firstIndex(where: { $0.id == id }) {
            items[idx].name = newName
            return
        }
        // Update inside folders
        for folderIndex in items.indices {
            if items[folderIndex].children == nil { continue }
            if let childIdx = items[folderIndex].children!.firstIndex(where: { $0.id == id }) {
                items[folderIndex].children![childIdx].name = newName
                return
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: addNewFolder) {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Add a new folder")

                Button(action: addNewSwiftFile) {
                    Label("New Swift File", systemImage: "plus.square.on.square")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Add a new Swift file")
            }
            .padding([.top, .horizontal], 8)
            .padding(.bottom, 2)
            
            List(items, children: \.children, selection: $selectedItem) { item in
                if item.children != nil {
                    HStack(spacing: 4) {
                        Image(systemName: item.iconName)
                        if editingItemID == item.id {
                            TextField("Name", text: Binding(
                                get: { item.name },
                                set: { updateItemName(id: item.id, to: $0) }
                            ))
                            .focused($isEditingFocused)
                            .onSubmit { editingItemID = nil }
                            .onChange(of: isEditingFocused) { focused in
                                if !focused { editingItemID = nil }
                            }
                        } else {
                            Text(item.name)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        editingItemID = item.id
                        isEditingFocused = true
                    }
                    .onDrop(of: [.plainText], isTargeted: nil) { providers in
                        // Try to read a UUID string from the drag payload
                        guard let provider = providers.first else { return false }
                        var handled = false
                        let _ = provider.loadObject(ofClass: String.self) { object, _ in
                            if let idString = object, let uuid = UUID(uuidString: idString),
                               let folderIndex = items.firstIndex(where: { $0.id == item.id }) {
                                DispatchQueue.main.async {
                                    moveFile(withId: uuid, toFolderAt: folderIndex)
                                }
                                handled = true
                            }
                        }
                        return handled
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: item.iconName)
                        if editingItemID == item.id {
                            TextField("Name", text: Binding(
                                get: { item.name },
                                set: { updateItemName(id: item.id, to: $0) }
                            ))
                            .focused($isEditingFocused)
                            .onSubmit { editingItemID = nil }
                            .onChange(of: isEditingFocused) { focused in
                                if !focused { editingItemID = nil }
                            }
                        } else {
                            Text(item.name)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        editingItemID = item.id
                        isEditingFocused = true
                    }
                    .onDrag {
                        NSItemProvider(object: item.id.uuidString as NSString)
                    }
                    .background(
                        NavigationLink(value: item) { EmptyView() }
                            .opacity(0)
                    )
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Sidebar")
        }
    }
}

struct SidebarView_Previews: PreviewProvider {
    struct Wrapper: View {
        @State var data: [SidebarItem] = [
            SidebarItem(name: "Lessons", iconName: "folder.fill", children: [
                SidebarItem(name: "Lesson 1", iconName: "doc.text"),
                SidebarItem(name: "Lesson 2", iconName: "doc.text")
            ]),
            SidebarItem(name: "Challenges", iconName: "folder.fill", children: [
                SidebarItem(name: "Challenge 1", iconName: "doc.text"),
                SidebarItem(name: "Challenge 2", iconName: "doc.text"),
                SidebarItem(name: "Advanced", iconName: "folder.fill", children: [
                    SidebarItem(name: "Challenge 3", iconName: "doc.text")
                ])
            ]),
            SidebarItem(name: "Welcome", iconName: "doc.text")
        ]
        var body: some View {
            SidebarView(items: $data)
                .frame(minWidth: 300, minHeight: 200)
        }
    }

    static var previews: some View {
        Wrapper()
    }
}
