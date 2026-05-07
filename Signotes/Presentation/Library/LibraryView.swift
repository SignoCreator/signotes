import SwiftUI

struct LibraryView: View {
    @StateObject var viewModel: LibraryViewModel

    let notesRepository: NotesRepository
    let drawingRepository: DrawingRepository

    var body: some View {
        NavigationSplitView {
            List(selection: selectedRootFolderBinding) {
                Section("Cartelle") {
                    ForEach(viewModel.rootFolders) { folder in
                        Label(folder.name, systemImage: "folder")
                            .tag(folder.id)
                    }
                }
            }
            .navigationTitle("Signotes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task {
                            await viewModel.createRootFolder()
                        }
                    } label: {
                        Label("Nuova cartella", systemImage: "folder.badge.plus")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        } content: {
            LibraryFolderContentView(
                folder: viewModel.currentFolder,
                parentFolder: viewModel.parentFolder,
                path: viewModel.currentPath,
                childFolders: viewModel.visibleChildFolders,
                notes: viewModel.visibleNotes,
                notesRepository: notesRepository,
                drawingRepository: drawingRepository,
                onSelectFolder: viewModel.selectFolder,
                onNavigateBack: viewModel.navigateToParentFolder,
                onCreateFolder: {
                    Task {
                        await viewModel.createChildFolder()
                    }
                },
                onCreateNote: {
                    Task {
                        await viewModel.createNote()
                    }
                }
            )
        } detail: {
            ContentUnavailableView(
                "Seleziona una lezione",
                systemImage: "square.and.pencil",
                description: Text("Apri una nota dalla libreria.")
            )
            .navigationTitle("Editor")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await viewModel.load()
        }
        .alert("Signotes error", isPresented: errorBinding) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
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

    private var selectedRootFolderBinding: Binding<UUID?> {
        Binding(
            get: { viewModel.selectedRootFolderID },
            set: { viewModel.selectRootFolder(id: $0) }
        )
    }
}

private struct LibraryFolderContentView: View {
    let folder: NotebookFolder?
    let parentFolder: NotebookFolder?
    let path: [NotebookFolder]
    let childFolders: [NotebookFolder]
    let notes: [NoteDocument]
    let notesRepository: NotesRepository
    let drawingRepository: DrawingRepository
    let onSelectFolder: (NotebookFolder) -> Void
    let onNavigateBack: () -> Void
    let onCreateFolder: () -> Void
    let onCreateNote: () -> Void

    var body: some View {
        List {
            if let folder {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(folder.name)
                            .font(.title2.weight(.semibold))
                        Text(path.map(\.name).joined(separator: " / "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 6)
                }
            }

            if childFolders.isEmpty && notes.isEmpty {
                ContentUnavailableView(
                    "Cartella vuota",
                    systemImage: "folder",
                    description: Text("Crea una lezione o una sottocartella.")
                )
                .listRowBackground(Color.clear)
            }

            if !childFolders.isEmpty {
                Section("Sottocartelle") {
                    ForEach(childFolders) { folder in
                        Button {
                            onSelectFolder(folder)
                        } label: {
                            Label(folder.name, systemImage: "folder")
                        }
                    }
                }
            }

            if !notes.isEmpty {
                Section("Lezioni") {
                    ForEach(notes) { note in
                        NavigationLink {
                            NoteEditorView(
                                viewModel: NoteEditorViewModel(
                                    noteID: note.id,
                                    notesRepository: notesRepository,
                                    drawingRepository: drawingRepository
                                )
                            )
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.title)
                                    .font(.headline)
                                Text("\(note.pageIDs.count) pagina")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Cartella")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if parentFolder != nil {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onNavigateBack()
                    } label: {
                        Label("Indietro", systemImage: "chevron.left")
                    }
                }
            }

            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    onCreateFolder()
                } label: {
                    Label("Nuova sottocartella", systemImage: "folder.badge.plus")
                }

                Button {
                    onCreateNote()
                } label: {
                    Label("Nuova lezione", systemImage: "doc.badge.plus")
                }
            }
        }
    }
}
