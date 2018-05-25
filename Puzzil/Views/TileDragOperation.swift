//
//  TileDragOperation.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-05-10.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

@available(iOS 10, *)
struct TileDragOperation {
    let direction: TileMoveDirection
    let originalFrame: CGRect
    let targetFrame: CGRect
    let animator: UIViewPropertyAnimator
    let keyMoveOperation: TileMoveOperation
    let moveOperations: [TileMoveOperation]

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

    func fractionComplete(with translation: CGPoint) -> CGFloat {
        switch direction {
        case .left, .right:
            return translation.x / distance
        case .up, .down:
            return translation.y / distance
        }
    }
}
