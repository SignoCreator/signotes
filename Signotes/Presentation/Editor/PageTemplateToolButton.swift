import SwiftUI

struct PageTemplateToolButton: View {
    @Binding var selectedTemplate: PageTemplate
    @Binding var isPresented: Bool

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: selectedTemplate.systemImageName)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: EditorToolbarMetrics.nudeIconFrame, height: EditorToolbarMetrics.nudeIconFrame)
                .padding(.bottom, EditorToolbarMetrics.nudeBottomPadding)
                .frame(
                    width: EditorToolbarMetrics.nudeButtonWidth,
                    height: EditorToolbarMetrics.nudeButtonHeight,
                    alignment: .bottom
                )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .popover(isPresented: $isPresented, arrowEdge: .top) {
            PageTemplatePickerPopover(
                selectedTemplate: $selectedTemplate,
                isPresented: $isPresented
            )
            .presentationCompactAdaptation(.popover)
        }
        .accessibilityLabel("Sfondo pagina")
        .accessibilityValue(selectedTemplate.displayName)
    }
}
