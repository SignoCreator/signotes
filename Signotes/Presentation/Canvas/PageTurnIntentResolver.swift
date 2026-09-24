import CoreGraphics
import UIKit

struct PageTurnAvailability: Equatable, Sendable {
    var canTurnPrevious = false
    var canTurnNext = true
}

struct PageTurnGestureContext: Equatable, Sendable {
    let availability: PageTurnAvailability
    let isAtBaseZoomScale: Bool
    let contentOffsetX: CGFloat
    let contentSize: CGSize
    let boundsSize: CGSize
    let contentInset: UIEdgeInsets
    let zoomScale: CGFloat
}

struct PageTurnIntentResolver {
    var minimumHorizontalTranslation: CGFloat = 72
    var horizontalDominanceRatio: CGFloat = 1.35
    var edgeTolerance: CGFloat = 36
    var minimumScrollableWidth: CGFloat = 32
    var minimumInteractiveTranslation: CGFloat = 8

    func interactiveDirection(
        translation: CGPoint,
        context: PageTurnGestureContext
    ) -> PageTurnDirection? {
        if context.isAtBaseZoomScale {
            return interactiveDirection(
                translation: translation,
                availability: context.availability
            )
        }

        return interactiveDirection(
            translation: translation,
            contentOffsetX: context.contentOffsetX,
            contentSize: context.contentSize,
            boundsSize: context.boundsSize,
            contentInset: context.contentInset,
            zoomScale: context.zoomScale
        ).flatMap { availableDirection($0, availability: context.availability) }
    }

    func committedDirection(
        translation: CGPoint,
        activeDirection: PageTurnDirection?,
        context: PageTurnGestureContext
    ) -> PageTurnDirection? {
        if let activeDirection {
            guard shouldCommitInteractiveTurn(direction: activeDirection, translation: translation) else {
                return nil
            }

            return activeDirection
        }

        return direction(translation: translation, context: context)
    }

    private func direction(
        translation: CGPoint,
        context: PageTurnGestureContext
    ) -> PageTurnDirection? {
        if context.isAtBaseZoomScale {
            return direction(
                translation: translation,
                availability: context.availability
            )
        }

        return direction(
            translation: translation,
            contentOffsetX: context.contentOffsetX,
            contentSize: context.contentSize,
            boundsSize: context.boundsSize,
            contentInset: context.contentInset,
            zoomScale: context.zoomScale
        ).flatMap { availableDirection($0, availability: context.availability) }
    }

    func direction(
        translation: CGPoint,
        availability: PageTurnAvailability
    ) -> PageTurnDirection? {
        guard abs(translation.x) > minimumHorizontalTranslation,
              abs(translation.x) > abs(translation.y) * horizontalDominanceRatio else {
            return nil
        }

        return availableDirectionForTranslation(translation.x, availability: availability)
    }

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

        return edgeDirection(
            translationX: translation.x,
            contentOffsetX: contentOffsetX,
            contentSize: contentSize,
            boundsSize: boundsSize,
            contentInset: contentInset,
            zoomScale: zoomScale
        )
    }

    func interactiveDirection(
        translation: CGPoint,
        availability: PageTurnAvailability
    ) -> PageTurnDirection? {
        guard abs(translation.x) > minimumInteractiveTranslation,
              abs(translation.x) > abs(translation.y) * horizontalDominanceRatio else {
            return nil
        }

        return availableDirectionForTranslation(translation.x, availability: availability)
    }

    func interactiveDirection(
        translation: CGPoint,
        contentOffsetX: CGFloat,
        contentSize: CGSize,
        boundsSize: CGSize,
        contentInset: UIEdgeInsets,
        zoomScale: CGFloat
    ) -> PageTurnDirection? {
        guard abs(translation.x) > minimumInteractiveTranslation,
              abs(translation.x) > abs(translation.y) * horizontalDominanceRatio else {
            return nil
        }

        return edgeDirection(
            translationX: translation.x,
            contentOffsetX: contentOffsetX,
            contentSize: contentSize,
            boundsSize: boundsSize,
            contentInset: contentInset,
            zoomScale: zoomScale
        )
    }

    func shouldCommitInteractiveTurn(direction: PageTurnDirection, translation: CGPoint) -> Bool {
        guard abs(translation.x) > minimumHorizontalTranslation,
              abs(translation.x) > abs(translation.y) * horizontalDominanceRatio else {
            return false
        }

        switch direction {
        case .previous:
            return translation.x > 0
        case .next:
            return translation.x < 0
        }
    }

    private func availableDirectionForTranslation(
        _ translationX: CGFloat,
        availability: PageTurnAvailability
    ) -> PageTurnDirection? {
        if translationX > 0 {
            return availability.canTurnPrevious ? .previous : nil
        }

        return availability.canTurnNext ? .next : nil
    }

    private func availableDirection(
        _ direction: PageTurnDirection,
        availability: PageTurnAvailability
    ) -> PageTurnDirection? {
        switch direction {
        case .previous:
            availability.canTurnPrevious ? direction : nil
        case .next:
            availability.canTurnNext ? direction : nil
        }
    }

    private func edgeDirection(
        translationX: CGFloat,
        contentOffsetX: CGFloat,
        contentSize: CGSize,
        boundsSize: CGSize,
        contentInset: UIEdgeInsets,
        zoomScale: CGFloat
    ) -> PageTurnDirection? {
        let minOffsetX = -contentInset.left
        let maxOffsetX = max(
            minOffsetX,
            contentSize.width * zoomScale + contentInset.right - boundsSize.width
        )
        let canScrollHorizontally = maxOffsetX - minOffsetX > minimumScrollableWidth

        if translationX > 0 {
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
