import SwiftUI

struct LibraryView: View {
    @StateObject var viewModel: LibraryViewModel

    let notesRepository: NotesRepository
    let drawingRepository: DrawingRepository

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 190), spacing: 18, alignment: .top)
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
                                    LibraryItemTile(
                                        title: folder.name,
                                        subtitle: "Cartella",
                                        systemImage: "folder.fill",
                                        color: .yellow
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
                                        LibraryItemTileLabel(
                                            title: note.title,
                                            subtitle: "\(note.pageIDs.count) pagina",
                                            systemImage: "doc.text.fill",
                                            color: .blue
                                        )
                                    }
                                    .buttonStyle(.plain)
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
                        Task {
                            if viewModel.currentFolderID == nil {
                                await viewModel.createRootFolder()
                            } else {
                                await viewModel.createChildFolder()
                            }
                        }
                    } label: {
                        Label("Nuova cartella", systemImage: "folder.badge.plus")
                    }

                    Button {
                        Task {
                            await viewModel.createNote()
                        }
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

private struct LibraryItemTile: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            LibraryItemTileLabel(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage,
                color: color
            )
        }
        .buttonStyle(.plain)
    }
}

private struct LibraryItemTileLabel: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.14))

                Image(systemName: systemImage)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(color)
            }
            .frame(height: 104)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 174, alignment: .topLeading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(uiColor: .separator).opacity(0.24), lineWidth: 1)
        }
    }
}
