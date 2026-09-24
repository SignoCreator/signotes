import SwiftUI

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject var viewModel: NoteEditorViewModel
    @State private var resetZoomToken = 0
    @State private var pageDragState = EditorPageDragState.inactive
    @State private var pageTurnTask: Task<Void, Never>?
    @State private var pendingAppendPageID = UUID()
    @State private var canvasCommandRequest: EditorCanvasCommandRequest?
    @State private var canvasCommandAvailability = EditorCanvasCommandAvailability()
    @State private var isPageOverviewPresented = false

    private let pageSize = CGSize(width: 794, height: 1123)

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            if let page = viewModel.page {
                EditorPageCarouselView(
                    page: page,
                    drawing: viewModel.drawing,
                    pageSize: pageSize,
                    resetZoomToken: resetZoomToken,
                    commandRequest: canvasCommandRequest,
                    toolPreset: viewModel.toolState.selectedPreset,
                    previousTarget: previousTarget,
                    nextTarget: nextTarget,
                    dragState: pageDragState,
                    onDrawingChange: viewModel.save,
                    onPageTurn: handlePageTurn,
                    onPageTurnDragUpdate: handlePageTurnDragUpdate,
                    onCommandAvailabilityChange: { availability in
                        canvasCommandAvailability = availability
                    }
                )
                .zIndex(1)
            } else {
                ProgressView()
            }

            if isPageOverviewPresented {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        EditorPageOverviewPanel(
                            pages: viewModel.pages,
                            currentPageID: viewModel.page?.id,
                            previewGeneration: viewModel.pageOverviewPreviewGeneration,
                            pageSize: pageSize,
                            previewDrawing: { page in
                                EditorPagePreview(
                                    page: page,
                                    drawing: viewModel.previewDrawing(for: page),
                                    drawingRevision: viewModel.previewRevision(for: page)
                                )
                            },
                            onClose: {
                                withAnimation(.snappy(duration: 0.18, extraBounce: 0)) {
                                    isPageOverviewPresented = false
                                }
                                viewModel.setPageOverviewPresented(false)
                            },
                            onSelectPage: { pageID in
                                selectPageFromOverview(pageID)
                            },
                            onInsertBefore: { pageID in
                                await viewModel.insertPage(before: pageID)
                                resetZoomToken += 1
                            },
                            onInsertAfter: { pageID in
                                await viewModel.insertPage(after: pageID)
                                resetZoomToken += 1
                            },
                            onDuplicate: { pageID in
                                await viewModel.duplicatePage(after: pageID)
                                resetZoomToken += 1
                            },
                            onDelete: { pageID in
                                let deletedCurrentPage = pageID == viewModel.page?.id
                                await viewModel.deletePage(id: pageID)
                                if deletedCurrentPage {
                                    resetZoomToken += 1
                                }
                            },
                            onMove: { pageID, targetIndex in
                                await viewModel.movePage(id: pageID, toIndex: targetIndex)
                            },
                            onAppend: {
                                await viewModel.appendPageAtEnd()
                                resetZoomToken += 1
                            }
                        )
                        .frame(width: min(max(geometry.size.width * 0.42, 340), 460))
                        .transition(.move(edge: .leading).combined(with: .opacity))

                        Spacer(minLength: 0)
                    }
                }
                .zIndex(3)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
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
                    onTogglePageOverview: {
                        withAnimation(.snappy(duration: 0.18, extraBounce: 0)) {
                            isPageOverviewPresented.toggle()
                        }
                        viewModel.setPageOverviewPresented(isPageOverviewPresented)
                        if !isPageOverviewPresented {
                            return
                        }

                        Task {
                            await viewModel.loadPageOverviewPreviews()
                        }
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
            pageTurnTask?.cancel()
            viewModel.setPageOverviewPresented(false)
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

    private var previousTarget: EditorPageCarouselTarget? {
        guard let page = viewModel.previousPage else {
            return nil
        }

        return .existingPage(
            page,
            drawing: viewModel.previewDrawing(for: page),
            drawingRevision: viewModel.previewRevision(for: page)
        )
    }

    private var nextTarget: EditorPageCarouselTarget {
        if let page = viewModel.nextPage {
            return .existingPage(
                page,
                drawing: viewModel.previewDrawing(for: page),
                drawingRevision: viewModel.previewRevision(for: page)
            )
        }

        return .appendNewPage(
            id: pendingAppendPageID,
            template: viewModel.page?.template ?? .grid
        )
    }

    private func handlePageTurnDragUpdate(_ update: PageTurnDragUpdate) {
        guard !isPageOverviewPresented else {
            resetPageDrag(animated: true)
            return
        }

        switch update {
        case let .changed(direction, translationX):
            guard canTurnPage(direction) else {
                resetPageDrag(animated: true)
                return
            }

            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                pageDragState = EditorPageDragState(
                    direction: direction,
                    translationX: translationX,
                    isSettling: false
                )
            }
        case .cancelled:
            resetPageDrag(animated: true)
        }
    }

    private func selectPageFromOverview(_ pageID: UUID) {
        let previousPageID = viewModel.page?.id

        Task {
            await viewModel.goToPage(id: pageID)
            if viewModel.page?.id != previousPageID {
                resetZoomToken += 1
            }
        }
    }

    private func handlePageTurn(_ direction: PageTurnDirection) {
        guard let target = turnTarget(for: direction) else {
            resetPageDrag(animated: true)
            return
        }

        pageTurnTask?.cancel()
        withAnimation(.snappy(duration: 0.22, extraBounce: 0)) {
            pageDragState = EditorPageDragState(
                direction: direction,
                translationX: pageDragState.translationX,
                isSettling: true
            )
        }

        pageTurnTask = Task {
            try? await Task.sleep(for: .milliseconds(180))
            guard !Task.isCancelled else {
                return
            }

            await completePageTurn(target)
        }
    }

    private func canTurnPage(_ direction: PageTurnDirection) -> Bool {
        switch direction {
        case .previous:
            viewModel.canGoToPreviousPage
        case .next:
            true
        }
    }

    private func turnTarget(for direction: PageTurnDirection) -> EditorPageTurnTarget? {
        switch direction {
        case .previous:
            guard let previousTarget else {
                return nil
            }

            return EditorPageTurnTarget(
                direction: direction,
                destination: previousTarget.destination
            )
        case .next:
            return EditorPageTurnTarget(
                direction: direction,
                destination: nextTarget.destination
            )
        }
    }

    @MainActor
    private func completePageTurn(_ target: EditorPageTurnTarget) async {
        let previousPageID = viewModel.page?.id

        switch target.destination {
        case let .existingPage(pageID):
            await viewModel.goToPage(id: pageID)
        case let .appendNewPage(appendSlotID):
            await viewModel.appendPageAfterCurrent()
            if appendSlotID == pendingAppendPageID {
                pendingAppendPageID = UUID()
            }
        }

        if viewModel.page?.id != previousPageID {
            resetZoomToken += 1
        }

        resetPageDrag(animated: false)
    }

    private func resetPageDrag(animated: Bool) {
        if animated {
            withAnimation(.snappy(duration: 0.20, extraBounce: 0)) {
                pageDragState = .inactive
            }
        } else {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                pageDragState = .inactive
            }
        }
    }
}
