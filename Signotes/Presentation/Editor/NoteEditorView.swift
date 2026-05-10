import SwiftUI

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject var viewModel: NoteEditorViewModel
    @State private var resetZoomToken = 0
    @State private var pageTransitionDirection: PageTurnDirection = .next
    @State private var canvasCommandRequest: EditorCanvasCommandRequest?
    @State private var canvasCommandAvailability = EditorCanvasCommandAvailability()

    private let pageSize = CGSize(width: 794, height: 1123)

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            if let page = viewModel.page {
                // `PageCanvasView` owns zoom and canvas rendering in UIKit so PencilKit can redraw sharply while scaled.
                PageCanvasView(
                    page: page,
                    initialDrawing: viewModel.drawing,
                    pageSize: pageSize,
                    resetZoomToken: resetZoomToken,
                    commandRequest: canvasCommandRequest,
                    toolPreset: viewModel.toolState.selectedPreset,
                    onDrawingChange: viewModel.save,
                    onPageTurn: handlePageTurn,
                    onCommandAvailabilityChange: { availability in
                        canvasCommandAvailability = availability
                    }
                )
                .id(page.id)
                .transition(pageTransition)
                .zIndex(1)
            } else {
                ProgressView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .animation(.snappy(duration: 0.28, extraBounce: 0), value: viewModel.page?.id)
        .safeAreaInset(edge: .top) {
            if viewModel.page != nil {
                EditorTopChromeView(
                    title: viewModel.title,
                    pageIndicatorText: viewModel.pageIndicatorText,
                    selectedTemplate: templateSelection,
                    onBack: {
                        dismiss()
                    },
                    onResetZoom: {
                        resetZoomToken += 1
                    },
                    onUndo: {
                        canvasCommandRequest = EditorCanvasCommandRequest(command: .undo)
                    },
                    onRedo: {
                        canvasCommandRequest = EditorCanvasCommandRequest(command: .redo)
                    },
                    commandAvailability: canvasCommandAvailability,
                    toolState: $viewModel.toolState,
                    onCreatePreset: { name, kind, colorHex, width in
                        await viewModel.createToolPreset(name: name, kind: kind, colorHex: colorHex, width: width)
                    },
                    onUpdatePreset: { id, name, kind, colorHex, width in
                        await viewModel.updateToolPreset(id: id, name: name, kind: kind, colorHex: colorHex, width: width)
                    },
                    onDeletePreset: { id in
                        await viewModel.deleteToolPreset(id: id)
                    }
                )
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

    private func handlePageTurn(_ direction: PageTurnDirection) {
        Task {
            let previousPageID = viewModel.page?.id
            pageTransitionDirection = direction

            switch direction {
            case .previous:
                await viewModel.goToPreviousPage()
            case .next:
                await viewModel.goToNextPageOrCreate()
            }

            if viewModel.page?.id != previousPageID {
                resetZoomToken += 1
            }
        }
    }

    private var pageTransition: AnyTransition {
        switch pageTransitionDirection {
        case .previous:
            .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        case .next:
            .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }
    }
}
