import SwiftUI

struct NoteEditorView: View {
    @StateObject var viewModel: NoteEditorViewModel

    var body: some View {
        NavigationStack {
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
}
