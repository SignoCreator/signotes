import SwiftUI

struct NoteEditorView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject var viewModel: NoteEditorViewModel
    @State private var zoomScale: CGFloat = 1
    @State private var resetZoomToken = 0

    private let pageSize = CGSize(width: 794, height: 1123)

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            if let page = viewModel.page {
                ZoomablePageScrollView(
                    pageSize: pageSize,
                    zoomScale: $zoomScale,
                    resetZoomToken: resetZoomToken,
                    contentUpdateID: PageCanvasContentID(
                        pageID: page.id,
                        template: page.template,
                        tool: viewModel.selectedTool
                    )
                ) {
                    // UIScrollView owns zoom/pan so PencilKit can keep native low-latency input.
                    PageCanvasView(
                        page: page,
                        drawing: $viewModel.drawing,
                        tool: viewModel.tool,
                        toolKind: viewModel.selectedTool,
                        onDrawingChange: viewModel.save,
                        onToolChange: viewModel.selectTool
                    )
                    .frame(width: pageSize.width, height: pageSize.height)
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

            ToolbarItem(placement: .primaryAction) {
                if viewModel.page != nil {
                    Button {
                        resetZoomToken += 1
                    } label: {
                        Label("Adatta larghezza", systemImage: "arrow.up.left.and.down.right.magnifyingglass")
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.page != nil {
                EditorToolPaletteView(selectedTool: $viewModel.selectedTool)
                    .padding(.bottom, 8)
            }
        }
        .task {
            await viewModel.load()
        }
        .onDisappear {
            Task {
                await viewModel.flushPendingDrawing()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase != .active else {
                return
            }

            Task {
                await viewModel.flushPendingDrawing()
            }
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

private struct PageCanvasContentID: Hashable {
    let pageID: UUID
    let template: PageTemplate
    let tool: EditorDrawingTool
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
