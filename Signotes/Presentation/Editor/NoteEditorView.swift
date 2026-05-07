import SwiftUI

struct NoteEditorView: View {
    @StateObject var viewModel: NoteEditorViewModel

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            if let page = viewModel.page {
                ScrollView([.vertical, .horizontal]) {
                    PageCanvasView(
                        page: page,
                        drawing: $viewModel.drawing,
                        tool: viewModel.tool,
                        onDrawingChange: viewModel.save
                    )
                    .frame(width: 794, height: 1123)
                    .padding(32)
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if viewModel.page != nil {
                    Menu {
                        Picker("Template", selection: templateSelection) {
                            ForEach(PageTemplate.allCases) { template in
                                Label(template.displayName, systemImage: template.systemImageName)
                                    .tag(template)
                            }
                        }
                    } label: {
                        Label("Template", systemImage: "square.grid.3x3")
                    }
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

    private var templateSelection: Binding<PageTemplate> {
        Binding(
            get: { viewModel.page?.template ?? .blank },
            set: { template in
                Task {
                    await viewModel.updateTemplate(template)
                }
            }
        )
    }
}

private extension PageTemplate {
    var displayName: String {
        switch self {
        case .blank:
            "Bianco"
        case .ruled:
            "Righe"
        case .grid:
            "Quadretti"
        case .dotted:
            "Puntinato"
        }
    }

    var systemImageName: String {
        switch self {
        case .blank:
            "doc"
        case .ruled:
            "list.bullet"
        case .grid:
            "square.grid.3x3"
        case .dotted:
            "circle.grid.3x3"
        }
    }
}
