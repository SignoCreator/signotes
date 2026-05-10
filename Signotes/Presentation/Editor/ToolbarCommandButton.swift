import SwiftUI

struct ToolbarCommandButton: View {
    let systemName: String
    let label: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isEnabled ? Color.primary : Color.secondary.opacity(0.38))
                .frame(width: EditorToolbarMetrics.nudeIconFrame, height: EditorToolbarMetrics.nudeIconFrame)
                .padding(.bottom, EditorToolbarMetrics.nudeBottomPadding)
                .frame(
                    width: EditorToolbarMetrics.nudeButtonWidth,
                    height: EditorToolbarMetrics.nudeButtonHeight,
                    alignment: .bottom
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .contentShape(Rectangle())
        .accessibilityLabel(label)
    }
}
