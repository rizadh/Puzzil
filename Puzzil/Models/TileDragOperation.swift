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
    let originalFrame: CGRect
    let targetFrame: CGRect
    let animator: UIViewPropertyAnimator
    let keyMoveOperation: TileMoveOperation
    let moveOperations: [TileMoveOperation]
    private(set) var lastVelocity = CGPoint(x: 0, y: 0)

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

    func updateVelocity(_ velocity: CGPoint) {
        let bias: CGFloat = 0.8
        let newX = lastVelocity.x * bias + velocity.x * (1 - bias)
        let newY = lastVelocity.y * bias + velocity.y * (1 - bias)
        lastVelocity = CGPoint(x: newX, y: newY)
    }

    func fractionComplete(with translation: CGPoint) -> CGFloat {
        switch direction {
        case .left, .right:
            return translation.x / distance
        case .up, .down:
            return translation.y / distance
        }
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
}
