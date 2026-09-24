import PencilKit
import SwiftUI

struct EditorPagePreview {
    let id: UUID
    let template: PageTemplate
    let drawing: PKDrawing
    let drawingRevision: Int

    init(page: NotePage, drawing: PKDrawing, drawingRevision: Int = 0) {
        id = page.id
        template = page.template
        self.drawing = drawing
        self.drawingRevision = drawingRevision
    }

    init(id: UUID, template: PageTemplate, drawing: PKDrawing = PKDrawing(), drawingRevision: Int = 0) {
        self.id = id
        self.template = template
        self.drawing = drawing
        self.drawingRevision = drawingRevision
    }
}

struct EditorPagePreviewView: View {
    let preview: EditorPagePreview
    let pageSize: CGSize
    var imageCache = EditorPagePreviewImageCache.shared
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        GeometryReader { geometry in
            let scale = CanvasViewportConfiguration(
                pageSize: pageSize,
                viewportSize: geometry.size
            ).minimumZoomScale
            let scaledSize = CGSize(width: pageSize.width * scale, height: pageSize.height * scale)

            PagePreviewRepresentable(
                preview: preview,
                pageSize: pageSize,
                screenScale: displayScale,
                imageCache: imageCache
            )
            .frame(width: pageSize.width, height: pageSize.height)
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: scaledSize.width, height: scaledSize.height, alignment: .topLeading)
            .shadow(color: .black.opacity(0.16), radius: 18, x: 0, y: 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .allowsHitTesting(false)
    }
}

struct EditorPagePreviewImageKey: Hashable {
    let pageID: UUID
    let templateRawValue: String
    let drawingRevision: Int
    let pageWidth: CGFloat
    let pageHeight: CGFloat
    let screenScale: CGFloat

    init(
        pageID: UUID,
        template: PageTemplate,
        drawingRevision: Int,
        pageSize: CGSize,
        screenScale: CGFloat
    ) {
        self.pageID = pageID
        templateRawValue = template.rawValue
        self.drawingRevision = drawingRevision
        pageWidth = pageSize.width
        pageHeight = pageSize.height
        self.screenScale = screenScale
    }
}

@MainActor
final class EditorPagePreviewImageCache {
    static let shared = EditorPagePreviewImageCache()

    private let countLimit: Int
    private var images: [EditorPagePreviewImageKey: UIImage] = [:]
    private var insertionOrder: [EditorPagePreviewImageKey] = []

    init(countLimit: Int = 12) {
        self.countLimit = max(countLimit, 1)
    }

    func image(
        for key: EditorPagePreviewImageKey,
        render: () -> UIImage
    ) -> UIImage {
        if let image = images[key] {
            return image
        }

        let image = render()
        images[key] = image
        insertionOrder.append(key)
        trimIfNeeded()
        return image
    }

    func removeAll() {
        images.removeAll()
        insertionOrder.removeAll()
    }

    private func trimIfNeeded() {
        while images.count > countLimit, let oldestKey = insertionOrder.first {
            insertionOrder.removeFirst()
            images[oldestKey] = nil
        }
    }
}

private struct PagePreviewRepresentable: UIViewRepresentable {
    let preview: EditorPagePreview
    let pageSize: CGSize
    let screenScale: CGFloat
    let imageCache: EditorPagePreviewImageCache

    func makeUIView(context: Context) -> PagePreviewUIView {
        PagePreviewUIView()
    }

    func updateUIView(_ view: PagePreviewUIView, context: Context) {
        view.configure(
            preview: preview,
            pageSize: pageSize,
            screenScale: screenScale,
            imageCache: imageCache
        )
    }
}

private final class PagePreviewUIView: UIView {
    private let paperView = PaperTemplateUIView()
    private let drawingImageView = UIImageView()
    private var renderedTemplate: PageTemplate?
    private var renderedPageSize: CGSize = .zero
    private var renderedImageKey: EditorPagePreviewImageKey?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(
        preview: EditorPagePreview,
        pageSize: CGSize,
        screenScale: CGFloat,
        imageCache: EditorPagePreviewImageCache
    ) {
        frame.size = pageSize
        paperView.frame = CGRect(origin: .zero, size: pageSize)
        drawingImageView.frame = paperView.frame

        if renderedTemplate != preview.template || renderedPageSize != pageSize {
            renderedTemplate = preview.template
            renderedPageSize = pageSize
            paperView.template = preview.template
        }

        let imageKey = EditorPagePreviewImageKey(
            pageID: preview.id,
            template: preview.template,
            drawingRevision: preview.drawingRevision,
            pageSize: pageSize,
            screenScale: screenScale
        )
        if renderedImageKey != imageKey || drawingImageView.image == nil {
            renderedImageKey = imageKey
            drawingImageView.image = imageCache.image(for: imageKey) {
                preview.drawing.image(
                    from: CGRect(origin: .zero, size: pageSize),
                    scale: screenScale
                )
            }
        }
    }

    private func setup() {
        backgroundColor = .clear

        paperView.backgroundColor = .white
        paperView.layer.cornerRadius = 2
        paperView.clipsToBounds = true
        addSubview(paperView)

        drawingImageView.backgroundColor = .clear
        drawingImageView.contentMode = .scaleToFill
        addSubview(drawingImageView)
    }
}
