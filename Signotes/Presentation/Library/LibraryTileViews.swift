import SwiftUI

struct LibraryFolderTile: View {
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                LibraryTileArtworkFrame {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 82, weight: .regular))
                        .foregroundStyle(color)
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 104, height: 104)
                }

                LibraryTileText(title: title, subtitle: subtitle)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 158, alignment: .top)
        }
        .buttonStyle(LibraryTileButtonStyle())
    }
}

struct LibraryNoteTile: View {
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            LibraryTileArtworkFrame {
                NotePreviewThumbnail(color: color)
            }
            LibraryTileText(title: title, subtitle: subtitle)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 158, alignment: .top)
    }
}

private struct LibraryTileArtworkFrame<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(width: 104, height: 104, alignment: .center)
            .frame(maxWidth: .infinity)
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
