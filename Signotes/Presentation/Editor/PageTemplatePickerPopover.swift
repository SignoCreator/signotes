import SwiftUI

struct PageTemplatePickerPopover: View {
    @Binding var selectedTemplate: PageTemplate
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Carta")
                .font(.headline.weight(.semibold))

            HStack(spacing: 10) {
                ForEach(PageTemplate.allCases) { template in
                    templateButton(template)
                }
            }
        }
        .padding(16)
        .frame(width: 380)
    }

    private func templateButton(_ template: PageTemplate) -> some View {
        Button {
            selectedTemplate = template
            isPresented = false
        } label: {
            VStack(spacing: 7) {
                Image(systemName: template.systemImageName)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 34, height: 30)

                Text(template.displayName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(selectedTemplate == template ? Color.accentColor : Color.primary)
            .frame(width: 78, height: 72)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selectedTemplate == template ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.06))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        selectedTemplate == template ? Color.accentColor : Color.primary.opacity(0.08),
                        lineWidth: selectedTemplate == template ? 2 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(template.displayName)
    }
}
