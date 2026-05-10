import CoreGraphics
import UIKit

struct PageTurnIntentResolver {
    var minimumHorizontalTranslation: CGFloat = 72
    var horizontalDominanceRatio: CGFloat = 1.35
    var edgeTolerance: CGFloat = 36
    var minimumScrollableWidth: CGFloat = 32

    func direction(
        translation: CGPoint,
        contentOffsetX: CGFloat,
        contentSize: CGSize,
        boundsSize: CGSize,
        contentInset: UIEdgeInsets,
        zoomScale: CGFloat
    ) -> PageTurnDirection? {
        guard abs(translation.x) > minimumHorizontalTranslation,
              abs(translation.x) > abs(translation.y) * horizontalDominanceRatio else {
            return nil
        }

        let minOffsetX = -contentInset.left
        let maxOffsetX = max(
            minOffsetX,
            contentSize.width * zoomScale + contentInset.right - boundsSize.width
        )
        let canScrollHorizontally = maxOffsetX - minOffsetX > minimumScrollableWidth

        if translation.x > 0 {
            guard !canScrollHorizontally || contentOffsetX <= minOffsetX + edgeTolerance else {
                return nil
            }
            return .previous
        }

        guard !canScrollHorizontally || contentOffsetX >= maxOffsetX - edgeTolerance else {
            return nil
        }
        return .next
    }
}
