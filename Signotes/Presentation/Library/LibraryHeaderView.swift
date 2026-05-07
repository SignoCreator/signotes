import SwiftUI

struct LibraryHeaderView: View {
    let title: String
    let path: String

    var body: some View {
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
