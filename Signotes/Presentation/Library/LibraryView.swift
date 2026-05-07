import SwiftUI

struct LibraryView: View {
    @StateObject var viewModel: LibraryViewModel

    let notesRepository: NotesRepository
    let drawingRepository: DrawingRepository

    var body: some View {
        NavigationSplitView {
            List(selection: $viewModel.selectedFolderID) {
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
                        viewModel.createFolder()
                    } label: {
                        Label("Nuova cartella", systemImage: "folder.badge.plus")
                    }
                }
            }
        } content: {
            LibraryFolderContentView(
                folder: viewModel.selectedFolder,
                childFolders: viewModel.visibleChildFolders,
                notes: viewModel.visibleNotes,
                notesRepository: notesRepository,
                drawingRepository: drawingRepository,
                onSelectFolder: viewModel.selectFolder,
                onCreateFolder: viewModel.createFolder,
                onCreateNote: viewModel.createNote
            )
        } detail: {
            ContentUnavailableView(
                "Seleziona una lezione",
                systemImage: "square.and.pencil",
                description: Text("Apri una nota dalla libreria.")
            )
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
}

private struct LibraryFolderContentView: View {
    let folder: NotebookFolder?
    let childFolders: [NotebookFolder]
    let notes: [NoteDocument]
    let notesRepository: NotesRepository
    let drawingRepository: DrawingRepository
    let onSelectFolder: (NotebookFolder) -> Void
    let onCreateFolder: () -> Void
    let onCreateNote: () -> Void

    var body: some View {
        List {
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
        .navigationTitle(folder?.name ?? "Libreria")
        .toolbar {
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
