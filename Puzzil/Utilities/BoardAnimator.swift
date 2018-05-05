//
//  BoardAnimator.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-04-30.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

class BoardAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var presenting = true
    var duration: Double {
        return presenting ? 0.5 : 0.25
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        if presenting {
            let fromController = transitionContext.viewController(forKey: .from) as! BoardSelectorViewController
            let toController = transitionContext.viewController(forKey: .to) as! GameViewController

            let fromBoardSelectorView = fromController.visibleBoardViewController.view!
            let fromBoardView = fromController.visibleBoardViewController.boardView
            let toView = toController.view!
            let toBoardView = toController.boardView

            containerView.addSubview(toView)
            toView.layoutIfNeeded()

            let fromFrame = fromBoardSelectorView.convert(fromBoardView.frame, to: toView)
            let toFrame = toBoardView.frame
            let transform = generateTransform(from: fromFrame, to: toFrame)

            animateBoardView(from: fromController, to: toController, with: transform, in: transitionContext)
        } else {
            let fromController = transitionContext.viewController(forKey: .from) as! GameViewController
            let toController = transitionContext.viewController(forKey: .to) as! BoardSelectorViewController

            let fromView = fromController.view!
            let fromBoardView = fromController.boardView
            let toView = toController.view!
            let toBoardSelectorView = toController.visibleBoardViewController.view!
            let toBoardView = toController.visibleBoardViewController.boardView

            containerView.addSubview(toView)
            toView.layoutIfNeeded()

            let fromFrame = fromView.convert(fromBoardView.frame, to: toBoardSelectorView)
            let toFrame = toBoardView.frame
            let transform = generateTransform(from: fromFrame, to: toFrame)

            animateBoardView(from: fromController, to: toController, with: transform, in: transitionContext)
        }
    }

    private func generateTransform(from fromFrame: CGRect, to toFrame: CGRect) ->
        CGAffineTransform {
        let scaleFactor = fromFrame.width / toFrame.width
        let xOffset = fromFrame.midX - toFrame.midX
        let yOffset = fromFrame.midY - toFrame.midY

        return CGAffineTransform(scaleX: scaleFactor, y: scaleFactor).translatedBy(x: xOffset, y: yOffset)
    }

    typealias BoardController = BoardContainer & UIViewController

    private func animateBoardView(from fromContainer: BoardController, to toContainer: BoardController,
                                  with transform: CGAffineTransform,
                                  in transitionContext: UIViewControllerContextTransitioning) {
        toContainer.boardView.transform = transform
        toContainer.view.alpha = 0

        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: presenting ? 0.5 : 1, initialSpringVelocity: 0,
                       options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                           toContainer.boardView.transform = .identity
                           toContainer.view.alpha = 1

                           fromContainer.boardView.transform = transform.inverted()
                           fromContainer.view.alpha = 0
        }) { _ in
            transitionContext.completeTransition(true)

            fromContainer.boardView.transform = .identity
            fromContainer.view.alpha = 1
        }
    }
}
