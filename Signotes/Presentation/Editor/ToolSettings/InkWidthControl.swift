import SwiftUI

struct InkWidthControl: View {
    @Binding var width: Double
    let colorHex: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("Spessore")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text(width.formatted(.number.precision(.fractionLength(1))))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Slider(value: $width, in: DrawingToolPreset.minimumWidth...16.0, step: 0.1)
                .tint(Color(uiColor: UIColor(hex: colorHex) ?? .black))

            ZStack {
                Capsule(style: .continuous)
                    .fill(Color.secondary.opacity(0.18))
                    .frame(width: 112, height: 2)

                Capsule(style: .continuous)
                    .fill(Color(uiColor: UIColor(hex: colorHex) ?? .black))
                    .frame(width: 92, height: min(max(CGFloat(width) * 1.25, 2.0), 13.0))
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 5)
        }
    }
}
