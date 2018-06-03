//
//  TileDragOperation.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-05-10.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

@available(iOS 10, *)
class TileDragOperation {
    let direction: TileMoveDirection
    private let originalFrame: CGRect
    private let targetFrame: CGRect
    private let animator: UIViewPropertyAnimator
    let keyMoveOperation: TileMoveOperation
    let moveOperations: [TileMoveOperation]

    var fractionComplete: CGFloat {
        return animator.fractionComplete
    }

    var distance: CGFloat {
        switch direction {
        case .left, .right:
            return targetFrame.midX - originalFrame.midX
        case .up, .down:
            return targetFrame.midY - originalFrame.midY
        }
    }

    var allMoveOperations: [TileMoveOperation] {
        return (moveOperations + [keyMoveOperation])
    }

    init(direction: TileMoveDirection, originalFrame: CGRect, targetFrame: CGRect, animator: UIViewPropertyAnimator,
         keyMoveOperation: TileMoveOperation, moveOperations: [TileMoveOperation]) {
        self.direction = direction
        self.originalFrame = originalFrame
        self.targetFrame = targetFrame
        self.animator = animator
        self.keyMoveOperation = keyMoveOperation
        self.moveOperations = moveOperations
    }

    func setTranslation(_ translation: CGPoint) {
        animator.fractionComplete = calculateFractionComplete(with: translation)
    }

    func finish(at position: UIViewAnimatingPosition, animated: Bool) {
        if animated {
            if case .start = position {
                animator.isReversed = true
            }
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 1)
        } else {
            animator.stopAnimation(false)
            animator.finishAnimation(at: position)
        }
    }

    func calculateFractionComplete(with translation: CGPoint) -> CGFloat {
        switch direction {
        case .left, .right:
            return translation.x / distance
        case .up, .down:
            return translation.y / distance
        }
    }
}
