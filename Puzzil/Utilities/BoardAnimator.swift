//
//  BoardAnimator.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-04-30.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

class BoardAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private static let slideDistance: CGFloat = 64
    private static let slideUp = CGAffineTransform(translationX: 0, y: -slideDistance)
    private static let slideDown = CGAffineTransform(translationX: 0, y: slideDistance)

    var presenting = true
    private let duration = 0.25

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        if presenting {
            let boardSelectorViewController = transitionContext.viewController(forKey: .from) as! BoardSelectorViewController
            let gameViewController = transitionContext.viewController(forKey: .to) as! GameViewController
            let fromBoardSelectorView = boardSelectorViewController.visibleBoardViewController.view!
            let fromBoardView = boardSelectorViewController.visibleBoardViewController.boardView

            let toView = gameViewController.view!
            containerView.addSubview(gameViewController.view)
            toView.layoutIfNeeded()

            let fromFrame = fromBoardSelectorView.convert(fromBoardView.frame, to: toView)
            let toFrame = gameViewController.boardView.frame
            let boardTransform = calculateTransform(from: fromFrame, to: toFrame)

            performGameOut(gameViewController, using: boardTransform)

            UIView.animate(
                withDuration: duration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0,
                options: [], animations: {
                    self.performBoardSelectorOut(boardSelectorViewController, using: boardTransform)
                    self.performGameIn(gameViewController)
            }) { _ in
                transitionContext.completeTransition(true)
                gameViewController.beginGame()
            }
        } else {
            let gameViewController = transitionContext.viewController(forKey: .from) as! GameViewController
            let boardSelectorViewController = transitionContext.viewController(forKey: .to) as! BoardSelectorViewController
            containerView.addSubview(boardSelectorViewController.view)

            let boardTransform = boardSelectorViewController.boardView.transform

            UIView.animate(
                withDuration: duration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0,
                options: [], animations: {
                    self.performGameOut(gameViewController, using: boardTransform)
                    self.performBoardSelectorIn(boardSelectorViewController)
            }) { _ in
                transitionContext.completeTransition(true)
            }
        }
    }

    private func performBoardSelectorOut(_ boardSelectorViewController: BoardSelectorViewController, using boardTransform: CGAffineTransform) {
        boardSelectorViewController.boardView.transform = boardTransform
        boardSelectorViewController.headerView.transform = BoardAnimator.slideUp
        boardSelectorViewController.boardNameLabel.transform = BoardAnimator.slideUp
        boardSelectorViewController.pageControl.transform = BoardAnimator.slideUp
        boardSelectorViewController.helpText.transform = BoardAnimator.slideDown
        boardSelectorViewController.view.alpha = 0
    }

    private func performBoardSelectorIn(_ boardSelectorViewController: BoardSelectorViewController) {
        boardSelectorViewController.boardView.transform = .identity
        boardSelectorViewController.headerView.transform = .identity
        boardSelectorViewController.boardNameLabel.transform = .identity
        boardSelectorViewController.pageControl.transform = .identity
        boardSelectorViewController.helpText.transform = .identity
        boardSelectorViewController.view.alpha = 1
    }

    private func performGameOut(_ gameViewController: GameViewController, using boardTransform: CGAffineTransform) {
        gameViewController.boardView.transform = boardTransform.inverted()
        gameViewController.stats.transform = BoardAnimator.slideUp
        gameViewController.buttons.transform = BoardAnimator.slideDown
        gameViewController.progressBar.transform = BoardAnimator.slideDown
        gameViewController.view.alpha = 0
    }

    private func performGameIn(_ gameViewController: GameViewController) {
        gameViewController.boardView.transform = .identity
        gameViewController.stats.transform = .identity
        gameViewController.buttons.transform = .identity
        gameViewController.progressBar.transform = .identity
        gameViewController.view.alpha = 1
    }

    private func calculateTransform(from fromFrame: CGRect, to toFrame: CGRect) ->
        CGAffineTransform {
        let scaleFactor = toFrame.width / fromFrame.width
        let xOffset = toFrame.midX - fromFrame.midX
        let yOffset = toFrame.midY - fromFrame.midY

        return CGAffineTransform(scaleX: scaleFactor, y: scaleFactor).translatedBy(x: xOffset, y: yOffset)
    }
}
