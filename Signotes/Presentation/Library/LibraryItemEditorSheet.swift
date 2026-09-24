import SwiftUI

enum LibraryItemEditorMode: Identifiable {
    case createFolder
    case createNote
    case editFolder(NotebookFolder)
    case editNote(NoteDocument)

    var id: String {
        switch self {
        case .createFolder:
            "create-folder"
        case .createNote:
            "create-note"
        case let .editFolder(folder):
            "edit-folder-\(folder.id.uuidString)"
        case let .editNote(note):
            "edit-note-\(note.id.uuidString)"
        }
    }

    var title: String {
        switch self {
        case .createFolder:
            "New folder"
        case .createNote:
            "New note"
        case .editFolder:
            "Edit folder"
        case .editNote:
            "Edit note"
        }
    }

    var textFieldTitle: String {
        switch self {
        case .createFolder, .editFolder:
            "Folder name"
        case .createNote, .editNote:
            "Note title"
        }
    }

    var initialName: String {
        switch self {
        case .createFolder, .createNote:
            ""
        case let .editFolder(folder):
            folder.name
        case let .editNote(note):
            note.title
        }
    }

    var initialColorHex: String {
        switch self {
        case .createFolder:
            LibraryColorPalette.folderDefault
        case .createNote:
            LibraryColorPalette.noteDefault
        case let .editFolder(folder):
            folder.colorHex ?? LibraryColorPalette.folderDefault
        case let .editNote(note):
            note.colorHex ?? LibraryColorPalette.noteDefault
        }
    }

    var confirmationTitle: String {
        switch self {
        case .createFolder, .createNote:
            "Create"
        case .editFolder, .editNote:
            "Save"
        }
    }
}

struct LibraryItemEditorSheet: View {
    let mode: LibraryItemEditorMode
    let onCancel: () -> Void
    let onConfirm: (String, String) -> Void

    @State private var name: String
    @State private var selectedColorHex: String

    init(
        mode: LibraryItemEditorMode,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping (String, String) -> Void
    ) {
        self.mode = mode
        self.onCancel = onCancel
        self.onConfirm = onConfirm
        _name = State(initialValue: mode.initialName)
        _selectedColorHex = State(initialValue: mode.initialColorHex)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(mode.textFieldTitle, text: $name)
                        .textInputAutocapitalization(.sentences)
                }

                Section("Color") {
                    HStack(spacing: 14) {
                        ForEach(LibraryColorPalette.colors, id: \.self) { colorHex in
                            Button {
                                selectedColorHex = colorHex
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: colorHex) ?? .accentColor)
                                        .frame(width: 34, height: 34)

                                    if selectedColorHex == colorHex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(colorHex)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.confirmationTitle) {
                        onConfirm(trimmedName, selectedColorHex)
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
