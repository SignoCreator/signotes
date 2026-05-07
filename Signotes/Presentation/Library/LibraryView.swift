import SwiftUI

struct LibraryView: View {
    @StateObject var viewModel: LibraryViewModel
    @State private var creationRequest: LibraryCreationRequest?

    let notesRepository: NotesRepository
    let drawingRepository: DrawingRepository

    private let columns = [
        GridItem(.adaptive(minimum: 136, maximum: 176), spacing: 22, alignment: .top)
    ]

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
                            LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                                ForEach(viewModel.visibleChildFolders) { folder in
                                    LibraryFolderTile(
                                        title: folder.name,
                                        subtitle: "Cartella",
                                        color: Color(hex: folder.colorHex) ?? .yellow
                                    ) {
                                        viewModel.selectFolder(folder)
                                    }
                                }

                                ForEach(viewModel.visibleNotes) { note in
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
                                }
                            }
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
                        creationRequest = .folder
                    } label: {
                        Label("Nuova cartella", systemImage: "folder.badge.plus")
                    }

                    Button {
                        creationRequest = .note
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
        .sheet(item: $creationRequest) { request in
            LibraryCreationSheet(
                request: request,
                onCancel: {
                    creationRequest = nil
                },
                onConfirm: { name, colorHex in
                    Task {
                        switch request {
                        case .folder:
                            if viewModel.currentFolderID == nil {
                                await viewModel.createRootFolder(name: name, colorHex: colorHex)
                            } else {
                                await viewModel.createChildFolder(name: name, colorHex: colorHex)
                            }
                        case .note:
                            await viewModel.createNote(title: name, colorHex: colorHex)
                        }

                        creationRequest = nil
                    }
                }
            )
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

private enum LibraryCreationRequest: Identifiable {
    case folder
    case note

    var id: String {
        switch self {
        case .folder: "folder"
        case .note: "note"
        }
    }

    var title: String {
        switch self {
        case .folder: "Nuova cartella"
        case .note: "Nuova lezione"
        }
    }

    var textFieldTitle: String {
        switch self {
        case .folder: "Nome cartella"
        case .note: "Titolo lezione"
        }
    }

    var defaultColorHex: String {
        switch self {
        case .folder: "#F2C94C"
        case .note: "#4F8BFF"
        }
    }
}

private struct LibraryCreationSheet: View {
    let request: LibraryCreationRequest
    let onCancel: () -> Void
    let onConfirm: (String, String) -> Void

    @State private var name = ""
    @State private var selectedColorHex: String

    private let colors = [
        "#F2C94C",
        "#4F8BFF",
        "#5AC8A8",
        "#FF7A59",
        "#AF7AFF",
        "#8E8E93"
    ]

    init(
        request: LibraryCreationRequest,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping (String, String) -> Void
    ) {
        self.request = request
        self.onCancel = onCancel
        self.onConfirm = onConfirm
        _selectedColorHex = State(initialValue: request.defaultColorHex)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(request.textFieldTitle, text: $name)
                        .textInputAutocapitalization(.sentences)
                }

                Section("Colore") {
                    HStack(spacing: 14) {
                        ForEach(colors, id: \.self) { colorHex in
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
            .navigationTitle(request.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla", action: onCancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Crea") {
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

private struct LibraryHeaderView: View {
    let title: String
    let path: String
    let canNavigateBack: Bool
    let onNavigateBack: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            if canNavigateBack {
                Button {
                    onNavigateBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Indietro")
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.largeTitle.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)

                Text(path)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct LibraryFolderTile: View {
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack(alignment: .bottomLeading) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 82, weight: .regular))
                        .foregroundStyle(color)
                        .symbolRenderingMode(.hierarchical)
                        .frame(height: 94)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(.white.opacity(0.68))
                        .frame(width: 58, height: 18)
                        .offset(x: 30, y: -22)
                }
                .frame(maxWidth: .infinity)

                LibraryTileText(
                    title: title,
                    subtitle: subtitle
                )
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 158, alignment: .top)
        }
        .buttonStyle(LibraryTileButtonStyle())
    }
}

private struct LibraryNoteTile: View {
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            NotePreviewThumbnail(color: color)

            LibraryTileText(
                title: title,
                subtitle: subtitle
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 158, alignment: .top)
    }
}

private struct LibraryTileText: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.callout.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.78)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct NotePreviewThumbnail: View {
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.10), radius: 7, x: 0, y: 4)

            RoundedRectangle(cornerRadius: 5)
                .stroke(Color(uiColor: .separator).opacity(0.26), lineWidth: 1)

            VStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { _ in
                    Rectangle()
                        .fill(color.opacity(0.20))
                        .frame(height: 1)
                }
            }
            .padding(.horizontal, 14)

            VStack(alignment: .leading, spacing: 9) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(Color.primary.opacity(index == 0 ? 0.18 : 0.11))
                        .frame(width: index == 3 ? 42 : 62, height: 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.top, 18)
        }
        .frame(width: 74, height: 104)
    }
}

private struct LibraryTileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        configuration.isPressed
                            ? Color.accentColor.opacity(0.14)
                            : Color(uiColor: .secondarySystemGroupedBackground).opacity(0.001)
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        configuration.isPressed
                            ? Color.accentColor.opacity(0.24)
                            : Color.clear,
                        lineWidth: 1
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.16), value: configuration.isPressed)
    }
}

private extension Color {
    init?(hex: String?) {
        guard let hex else {
            return nil
        }

        let sanitized = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard sanitized.count == 6, let value = Int(sanitized, radix: 16) else {
            return nil
        }

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255

        self.init(red: red, green: green, blue: blue)
    }
}

#Preview {
    ZStack {
        Color(uiColor: .systemGroupedBackground)
        HStack(spacing: 22) {
            LibraryFolderTile(title: "Matematica", subtitle: "Cartella", color: .yellow) {}
                .frame(width: 154)
            LibraryNoteTile(title: "Lezione 1", subtitle: "1 pagina", color: .blue)
                .frame(width: 154)
        }
        .padding()
    }
}
