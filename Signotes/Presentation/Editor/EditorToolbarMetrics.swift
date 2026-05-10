import SwiftUI

enum EditorToolbarMetrics {
    static let height: CGFloat = 66
    static let outerPadding: CGFloat = 14
    static let sectionSpacing: CGFloat = 10
    static let commandSpacing: CGFloat = 2
    static let toolSpacing: CGFloat = 4
    static let nudeButtonWidth: CGFloat = 42
    static let nudeButtonHeight: CGFloat = 58
    static let nudeIconFrame: CGFloat = 42
    static let nudeBottomPadding: CGFloat = 2
    static let dividerHeight: CGFloat = 28
    static let dividerBottomPadding: CGFloat = 15
}

struct ToolbarSectionDivider: View {
    var body: some View {
        Divider()
            .frame(height: EditorToolbarMetrics.dividerHeight)
            .padding(.bottom, EditorToolbarMetrics.dividerBottomPadding)
    }
}
