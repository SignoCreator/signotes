import SwiftUI

struct LibraryGridView: View {
    let folders: [NotebookFolder]
    let notes: [NoteDocument]
    let notesRepository: NotesRepository
    let drawingRepository: DrawingRepository
    let onSelectFolder: (NotebookFolder) -> Void
    let onEditFolder: (NotebookFolder) -> Void
    let onDeleteFolder: (NotebookFolder) -> Void
    let onEditNote: (NoteDocument) -> Void
    let onDeleteNote: (NoteDocument) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 136, maximum: 176), spacing: 22, alignment: .top)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
            ForEach(folders) { folder in
                LibraryFolderTile(
                    title: folder.name,
                    subtitle: "Cartella",
                    color: Color(hex: folder.colorHex) ?? .yellow
                ) {
                    onSelectFolder(folder)
                }
                .contextMenu {
                    Button {
                        onEditFolder(folder)
                    } label: {
                        Label("Modifica", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        onDeleteFolder(folder)
                    } label: {
                        Label("Elimina", systemImage: "trash")
                    }
                }
            }

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
                    LibraryNoteTile(
                        title: note.title,
                        subtitle: "\(note.pageIDs.count) pagina",
                        color: Color(hex: note.colorHex) ?? .blue
                    )
                }
                .buttonStyle(LibraryTileButtonStyle())
                .contextMenu {
                    Button {
                        onEditNote(note)
                    } label: {
                        Label("Modifica", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        onDeleteNote(note)
                    } label: {
                        Label("Elimina", systemImage: "trash")
                    }
                }
            }
        }
    }
}
