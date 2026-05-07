import SwiftUI

struct LibraryHeaderView: View {
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
