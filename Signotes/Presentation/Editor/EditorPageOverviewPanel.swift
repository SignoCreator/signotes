import SwiftUI

struct EditorPageOverviewPanel: View {
    let pages: [NotePage]
    let currentPageID: UUID?
    let previewGeneration: Int
    let pageSize: CGSize
    let previewDrawing: (NotePage) -> EditorPagePreview
    let onClose: () -> Void
    let onSelectPage: (UUID) -> Void
    let onInsertBefore: (UUID) async -> Void
    let onInsertAfter: (UUID) async -> Void
    let onDuplicate: (UUID) async -> Void
    let onDelete: (UUID) async -> Void
    let onMove: (UUID, Int) async -> Void
    let onAppend: () async -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var deleteCandidate: NotePage?

    private let columns = [
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24)
    ]

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                LazyVGrid(columns: columns, alignment: .center, spacing: 34) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { offset, page in
                        EditorPageOverviewTile(
                            page: page,
                            pageNumber: offset + 1,
                            preview: previewDrawing(page),
                            previewGeneration: previewGeneration,
                            pageSize: pageSize,
                            isSelected: page.id == currentPageID,
                            canDelete: pages.count > 1,
                            onSelect: {
                                onSelectPage(page.id)
                            },
                            onInsertBefore: {
                                await onInsertBefore(page.id)
                            },
                            onInsertAfter: {
                                await onInsertAfter(page.id)
                            },
                            onDuplicate: {
                                await onDuplicate(page.id)
                            },
                            onRequestDelete: {
                                deleteCandidate = page
                            },
                            onDropPageID: { draggedPageID in
                                guard let insertionIndex = insertionIndex(for: draggedPageID, targetOffset: offset) else {
                                    return false
                                }

                                Task {
                                    await onMove(draggedPageID, insertionIndex)
                                }
                                return true
                            }
                        )
                    }

                    AddPageOverviewCard {
                        Task {
                            await onAppend()
                        }
                    } onDropPageID: { draggedPageID in
                        guard pages.contains(where: { $0.id == draggedPageID }) else {
                            return false
                        }

                        Task {
                            await onMove(draggedPageID, max(pages.count - 1, 0))
                        }
                        return true
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
        }
        .background(panelBackground)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.primary.opacity(colorScheme == .dark ? 0.22 : 0.12))
                .frame(width: 1)
        }
        .confirmationDialog(
            "Delete page?",
            isPresented: Binding(
                get: { deleteCandidate != nil },
                set: { isPresented in
                    if !isPresented {
                        deleteCandidate = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                guard let page = deleteCandidate else {
                    return
                }

                Task {
                    await onDelete(page.id)
                    deleteCandidate = nil
                }
            }

            Button("Cancel", role: .cancel) {
                deleteCandidate = nil
            }
        } message: {
            Text("This page and its content will be removed from the note.")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Pages")
                    .font(.title3.weight(.semibold))
                Text("\(pages.count) \(pages.count == 1 ? "page" : "pages")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 34, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close page list")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08))
                .frame(height: 1)
        }
    }

    private var panelBackground: some ShapeStyle {
        colorScheme == .dark
            ? Color(uiColor: .secondarySystemBackground)
            : Color(uiColor: .systemBackground)
    }

    private func insertionIndex(for draggedPageID: UUID, targetOffset: Int) -> Int? {
        guard let sourceOffset = pages.firstIndex(where: { $0.id == draggedPageID }),
              sourceOffset != targetOffset
        else {
            return nil
        }

        return sourceOffset < targetOffset ? targetOffset - 1 : targetOffset
    }
}

private struct EditorPageOverviewTile: View {
    let page: NotePage
    let pageNumber: Int
    let preview: EditorPagePreview
    let previewGeneration: Int
    let pageSize: CGSize
    let isSelected: Bool
    let canDelete: Bool
    let onSelect: () -> Void
    let onInsertBefore: () async -> Void
    let onInsertAfter: () async -> Void
    let onDuplicate: () async -> Void
    let onRequestDelete: () -> Void
    let onDropPageID: (UUID) -> Bool

    @Environment(\.colorScheme) private var colorScheme
    @State private var isDropTarget = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onSelect) {
                PageOverviewThumbnail(
                    preview: preview,
                    previewGeneration: previewGeneration,
                    pageSize: pageSize,
                    borderColor: borderColor,
                    borderWidth: isSelected ? 3 : 1
                )
                .frame(height: 178)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Page \(pageNumber)")

            HStack(spacing: 6) {
                Text("\(pageNumber)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.primary)

                Spacer(minLength: 0)

                Menu {
                    Button("Add page before") {
                        Task {
                            await onInsertBefore()
                        }
                    }
                    Button("Add page after") {
                        Task {
                            await onInsertAfter()
                        }
                    }
                    Button("Duplicate") {
                        Task {
                            await onDuplicate()
                        }
                    }
                    Button("Delete", role: .destructive, action: onRequestDelete)
                        .disabled(!canDelete)
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 28, height: 24)
                        .contentShape(Rectangle())
                }
                .menuOrder(.fixed)
                .accessibilityLabel("Page \(pageNumber) actions")
            }
        }
        .padding(6)
        .overlay(alignment: .leading) {
            if isDropTarget {
                PageDropInsertionIndicator()
                    .offset(x: -10)
            }
        }
        .contentShape(Rectangle())
        .draggable(page.id.uuidString)
        .dropDestination(for: String.self) { items, _ in
            guard let rawPageID = items.first, let pageID = UUID(uuidString: rawPageID) else {
                return false
            }

            return onDropPageID(pageID)
        } isTargeted: { isTargeted in
            isDropTarget = isTargeted
        }
    }

    private var borderColor: Color {
        isSelected ? .accentColor : Color.primary.opacity(colorScheme == .dark ? 0.20 : 0.12)
    }
}

private struct AddPageOverviewCard: View {
    let onAppend: () -> Void
    let onDropPageID: (UUID) -> Bool

    @State private var isDropTarget = false

    var body: some View {
        Button(action: onAppend) {
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 2, dash: [7, 5])
                    )
                    .frame(height: 178)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundStyle(Color.accentColor)
                    }

                Text("Add")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)
            }
        }
        .buttonStyle(.plain)
        .padding(6)
        .overlay(alignment: .leading) {
            if isDropTarget {
                PageDropInsertionIndicator()
                    .offset(x: -10)
            }
        }
        .contentShape(Rectangle())
        .dropDestination(for: String.self) { items, _ in
            guard let rawPageID = items.first, let pageID = UUID(uuidString: rawPageID) else {
                return false
            }

            return onDropPageID(pageID)
        } isTargeted: { isTargeted in
            isDropTarget = isTargeted
        }
        .accessibilityLabel("Add page")
    }
}

private struct PageOverviewThumbnail: View {
    let preview: EditorPagePreview
    let previewGeneration: Int
    let pageSize: CGSize
    let borderColor: Color
    let borderWidth: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let thumbnailSize = fittedSize(inside: geometry.size)

            EditorPagePreviewView(preview: preview, pageSize: pageSize)
                .id("\(preview.id.uuidString)-\(preview.drawingRevision)-\(previewGeneration)")
                .frame(width: thumbnailSize.width, height: thumbnailSize.height)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(borderColor, lineWidth: borderWidth)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func fittedSize(inside availableSize: CGSize) -> CGSize {
        guard pageSize.width > 0, pageSize.height > 0 else {
            return availableSize
        }

        let aspectRatio = pageSize.width / pageSize.height
        var height = availableSize.height
        var width = height * aspectRatio

        if width > availableSize.width {
            width = availableSize.width
            height = width / aspectRatio
        }

        return CGSize(width: width, height: height)
    }
}

private struct PageDropInsertionIndicator: View {
    var body: some View {
        Capsule()
            .fill(Color.accentColor)
            .frame(width: 4, height: 178)
        .shadow(color: Color.accentColor.opacity(0.35), radius: 5, x: 0, y: 1)
        .accessibilityHidden(true)
    }
}
