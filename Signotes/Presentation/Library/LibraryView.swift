import SwiftUI

struct LibraryView: View {
    @StateObject var viewModel: LibraryViewModel
    @State private var editorMode: LibraryItemEditorMode?
    @State private var deletionRequest: LibraryDeletionRequest?
    @State private var activeDragItem: LibraryDragItem?
    @State private var isRootDropTargeted = false
    @State private var isParentDropTargeted = false
    @State private var isBackDropTargeted = false

    let notesRepository: NotesRepository
    let drawingRepository: DrawingRepository

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        LibraryHeaderView(
                            title: viewModel.currentFolder?.name ?? "Signotes",
                            path: pathTitle
                        )
                        .libraryParentDropTarget(
                            isEnabled: canDropActiveItem(toFolderID: parentDropTargetFolderID),
                            isTargeted: isParentDropTargeted
                        )
                        .dropDestination(for: LibraryDragItem.self) { items, _ in
                            guard viewModel.currentFolderID != nil,
                                  canDropDraggedItems(items, toFolderID: parentDropTargetFolderID) else {
                                clearDragState()
                                return false
                            }

                            moveDraggedItems(items, targetFolderID: parentDropTargetFolderID)
                            clearDragState()
                            return true
                        } isTargeted: { isTargeted in
                            isParentDropTargeted = isTargeted && canDropActiveItem(toFolderID: parentDropTargetFolderID)
                        }

                        if viewModel.visibleChildFolders.isEmpty && viewModel.visibleNotes.isEmpty {
                            ContentUnavailableView(
                                "No items",
                                systemImage: "folder",
                                description: Text(emptyStateDescription)
                            )
                            .frame(maxWidth: .infinity, minHeight: 360)
                        } else {
                            LibraryGridView(
                                folders: viewModel.visibleChildFolders,
                                notes: viewModel.visibleNotes,
                                notesRepository: notesRepository,
                                drawingRepository: drawingRepository,
                                onSelectFolder: viewModel.selectFolder,
                                onEditFolder: { editorMode = .editFolder($0) },
                                onDeleteFolder: { deletionRequest = .folder($0) },
                                onEditNote: { editorMode = .editNote($0) },
                                onDeleteNote: { deletionRequest = .note($0) },
                                onDropItems: { items, targetFolderID in
                                    moveDraggedItems(items, targetFolderID: targetFolderID)
                                },
                                canDropItems: canDropDraggedItems,
                                activeDragItem: $activeDragItem
                            )
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .libraryRootDropTarget(
                    isEnabled: viewModel.currentFolderID == nil,
                    isTargeted: isRootDropTargeted
                )
                .dropDestination(for: LibraryDragItem.self) { items, _ in
                    guard viewModel.currentFolderID == nil else {
                        clearDragState()
                        return false
                    }

                    guard canDropDraggedItems(items, toFolderID: nil) else {
                        clearDragState()
                        return false
                    }

                    moveDraggedItems(items, targetFolderID: nil)
                    clearDragState()
                    return true
                } isTargeted: { isTargeted in
                    isRootDropTargeted = isTargeted && canDropActiveItem(toFolderID: nil)
                }
            }
            .navigationTitle("Signotes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if viewModel.currentFolderID != nil {
                        Button {
                            viewModel.navigateToParentFolder()
                        } label: {
                            Image(systemName: "chevron.backward")
                                .frame(width: 36, height: 36)
                        }
                        .libraryBackDropTarget(isTargeted: isBackDropTargeted)
                        .dropDestination(for: LibraryDragItem.self) { items, _ in
                            guard canDropDraggedItems(items, toFolderID: parentDropTargetFolderID) else {
                                clearDragState()
                                return false
                            }

                            moveDraggedItems(items, targetFolderID: parentDropTargetFolderID)
                            clearDragState()
                            return true
                        } isTargeted: { isTargeted in
                            isBackDropTargeted = isTargeted && canDropActiveItem(toFolderID: parentDropTargetFolderID)
                        }
                        .accessibilityLabel("Back")
                    }
                }

                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        editorMode = .createFolder
                    } label: {
                        Label("New folder", systemImage: "folder.badge.plus")
                    }

                    Button {
                        editorMode = .createNote
                    } label: {
                        Label("New note", systemImage: "doc.badge.plus")
                    }
                    .disabled(viewModel.currentFolderID == nil)
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .sheet(item: $editorMode) { mode in
            LibraryItemEditorSheet(
                mode: mode,
                onCancel: {
                    editorMode = nil
                },
                onConfirm: { name, colorHex in
                    Task {
                        await applyEditorMode(mode, name: name, colorHex: colorHex)
                        editorMode = nil
                    }
                }
            )
        }
        .confirmationDialog(
            deletionRequest?.title ?? "",
            isPresented: deletionConfirmationBinding,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                guard let deletionRequest else {
                    return
                }

                Task {
                    await applyDeletion(deletionRequest)
                    self.deletionRequest = nil
                }
            }

            Button("Cancel", role: .cancel) {
                deletionRequest = nil
            }
        } message: {
            Text(deletionRequest?.message ?? "")
        }
        .alert("Signotes error", isPresented: errorBinding) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var pathTitle: String {
        let names = viewModel.currentPath.map(\.name)
        guard !names.isEmpty else {
            return "Root"
        }

        return (["Signotes"] + names).joined(separator: " / ")
    }

    private var emptyStateDescription: String {
        viewModel.currentFolderID == nil
            ? "Create a folder to get started."
            : "Create a note or a subfolder."
    }

    private var parentDropTargetFolderID: UUID? {
        viewModel.parentFolder?.id
    }

    private var deletionConfirmationBinding: Binding<Bool> {
        Binding(
            get: { deletionRequest != nil },
            set: { isPresented in
                if !isPresented {
                    deletionRequest = nil
                }
            }
        )
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.errorMessage = nil
                }
            }
        )
    }

    private func applyEditorMode(_ mode: LibraryItemEditorMode, name: String, colorHex: String) async {
        switch mode {
        case .createFolder:
            if viewModel.currentFolderID == nil {
                await viewModel.createRootFolder(name: name, colorHex: colorHex)
            } else {
                await viewModel.createChildFolder(name: name, colorHex: colorHex)
            }
        case .createNote:
            await viewModel.createNote(title: name, colorHex: colorHex)
        case let .editFolder(folder):
            await viewModel.updateFolder(id: folder.id, name: name, colorHex: colorHex)
        case let .editNote(note):
            await viewModel.updateNote(id: note.id, title: name, colorHex: colorHex)
        }
    }

    private func applyDeletion(_ request: LibraryDeletionRequest) async {
        switch request {
        case let .folder(folder):
            await viewModel.deleteFolder(id: folder.id)
        case let .note(note):
            await viewModel.deleteNote(id: note.id)
        }
    }

    private func moveDraggedItems(_ items: [LibraryDragItem], targetFolderID: UUID?) {
        Task {
            await viewModel.moveDraggedItems(items, toFolderID: targetFolderID)
        }
    }

    private func canDropActiveItem(toFolderID targetFolderID: UUID?) -> Bool {
        guard let activeDragItem else {
            return false
        }

        return canDropDraggedItems([activeDragItem], toFolderID: targetFolderID)
    }

    private func canDropDraggedItems(_ items: [LibraryDragItem], toFolderID targetFolderID: UUID?) -> Bool {
        viewModel.canDropDraggedItems(items, toFolderID: targetFolderID)
    }

    private func clearDragState() {
        activeDragItem = nil
        isRootDropTargeted = false
        isParentDropTargeted = false
        isBackDropTargeted = false
    }
}

private extension View {
    func libraryRootDropTarget(isEnabled: Bool, isTargeted: Bool) -> some View {
        overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isEnabled && isTargeted ? Color.accentColor.opacity(0.55) : Color.clear,
                    style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                )
                .padding(10)
                .animation(.snappy(duration: 0.16), value: isTargeted)
        }
    }

    func libraryParentDropTarget(isEnabled: Bool, isTargeted: Bool) -> some View {
        overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isEnabled && isTargeted ? Color.accentColor.opacity(0.58) : Color.clear,
                    style: StrokeStyle(lineWidth: 2, dash: [7, 5])
                )
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isEnabled && isTargeted ? Color.accentColor.opacity(0.08) : Color.clear)
                }
                .animation(.snappy(duration: 0.16), value: isTargeted)
        }
    }

    func libraryBackDropTarget(isTargeted: Bool) -> some View {
        background {
            Circle()
                .fill(isTargeted ? Color.accentColor.opacity(0.14) : Color.clear)
                .animation(.snappy(duration: 0.16), value: isTargeted)
        }
    }
}
