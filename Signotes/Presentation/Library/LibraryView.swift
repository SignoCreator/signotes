import SwiftUI

struct LibraryView: View {
    @StateObject var viewModel: LibraryViewModel
    @State private var editorMode: LibraryItemEditorMode?
    @State private var deletionRequest: LibraryDeletionRequest?

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
                            path: pathTitle,
                            canNavigateBack: viewModel.currentFolderID != nil,
                            onNavigateBack: viewModel.navigateToParentFolder
                        )

                        if viewModel.visibleChildFolders.isEmpty && viewModel.visibleNotes.isEmpty {
                            ContentUnavailableView(
                                "Nessun elemento",
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
                                onDeleteNote: { deletionRequest = .note($0) }
                            )
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle("Signotes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        editorMode = .createFolder
                    } label: {
                        Label("Nuova cartella", systemImage: "folder.badge.plus")
                    }

                    Button {
                        editorMode = .createNote
                    } label: {
                        Label("Nuova lezione", systemImage: "doc.badge.plus")
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
            Button("Elimina", role: .destructive) {
                guard let deletionRequest else {
                    return
                }

                Task {
                    await applyDeletion(deletionRequest)
                    self.deletionRequest = nil
                }
            }

            Button("Annulla", role: .cancel) {
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
            ? "Crea una cartella per iniziare."
            : "Crea una lezione o una sottocartella."
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
}
