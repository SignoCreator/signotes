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
    let canDropItems: ([LibraryDragItem], UUID?) -> Bool

    @Binding var activeDragItem: LibraryDragItem?

    @State private var targetedFolderID: UUID?

    private let columns = [
        GridItem(.adaptive(minimum: 136, maximum: 176), spacing: 22, alignment: .top)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
            ForEach(folders) { folder in
                let dragItem = LibraryDragItem.folder(folder.id)
                let isActivelyDragged = activeDragItem == dragItem
                let canDropActiveItem = activeDragItem.map { canDropItems([$0], folder.id) } ?? false

                LibraryFolderTile(
                    title: folder.name,
                    subtitle: "Cartella",
                    color: Color(hex: folder.colorHex) ?? .yellow
                ) {
                    onSelectFolder(folder)
                }
                .opacity(isActivelyDragged ? 0 : 1)
                .draggable(dragItem) {
                    LibraryFolderTile(
                        title: folder.name,
                        subtitle: "Cartella",
                        color: Color(hex: folder.colorHex) ?? .yellow
                    ) {}
                    .frame(width: 154)
                    .onAppear {
                        activeDragItem = dragItem
                    }
                    .onDisappear {
                        if activeDragItem == dragItem {
                            activeDragItem = nil
                        }
                    }
                }
                .libraryDropTarget(isTargeted: targetedFolderID == folder.id && canDropActiveItem)
                .dropDestination(for: LibraryDragItem.self) { items, _ in
                    guard canDropItems(items, folder.id) else {
                        activeDragItem = nil
                        return false
                    }

                    onDropItems(items, folder.id)
                    activeDragItem = nil
                    return true
                } isTargeted: { isTargeted in
                    targetedFolderID = isTargeted && canDropActiveItem ? folder.id : nil
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
                let dragItem = LibraryDragItem.note(note.id)
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
                .opacity(activeDragItem == dragItem ? 0 : 1)
                .draggable(dragItem) {
                    LibraryNoteTile(
                        title: note.title,
                        subtitle: "\(note.pageIDs.count) pagina",
                        color: Color(hex: note.colorHex) ?? .blue
                    )
                    .frame(width: 154)
                    .onAppear {
                        activeDragItem = dragItem
                    }
                    .onDisappear {
                        if activeDragItem == dragItem {
                            activeDragItem = nil
                        }
                    }
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
