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
    let onDropItems: ([LibraryDragItem], UUID?) -> Void

    @State private var targetedFolderID: UUID?

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
                .draggable(LibraryDragItem.folder(folder.id))
                .libraryDropTarget(isTargeted: targetedFolderID == folder.id)
                .dropDestination(for: LibraryDragItem.self) { items, _ in
                    onDropItems(items, folder.id)
                    return true
                } isTargeted: { isTargeted in
                    targetedFolderID = isTargeted ? folder.id : nil
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
                .draggable(LibraryDragItem.note(note.id))
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

private extension View {
    func libraryDropTarget(isTargeted: Bool) -> some View {
        overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isTargeted ? Color.accentColor.opacity(0.70) : Color.clear,
                    lineWidth: 2
                )
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isTargeted ? Color.accentColor.opacity(0.10) : Color.clear)
                }
                .animation(.snappy(duration: 0.16), value: isTargeted)
        }
    }
}
