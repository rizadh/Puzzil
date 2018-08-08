//
//  GameBoardAnimator.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-04-30.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

class GameBoardAnimator: NSObject, UIViewControllerAnimatedTransitioning {
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
            let mainViewController = transitionContext.viewController(forKey: .from) as! MainViewController
            let gameViewController = transitionContext.viewController(forKey: .to) as! GameViewController
            let fromMainView = mainViewController.visibleBoardViewController.view!
            let fromBoardView = mainViewController.visibleBoardViewController.boardView

            let toView = gameViewController.view!
            containerView.addSubview(gameViewController.view)
            toView.layoutIfNeeded()

            let fromFrame = fromMainView.convert(fromBoardView.frame, to: toView)
            let toFrame = gameViewController.boardView.frame
            let boardTransform = calculateTransform(from: fromFrame, to: toFrame)

            performGameOut(gameViewController, using: boardTransform)

            UIView.animate(
                withDuration: duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0,
                options: [], animations: {
                    self.performMainOut(mainViewController, using: boardTransform)
                    self.performGameIn(gameViewController)
                }
            ) { _ in
                transitionContext.completeTransition(true)
                gameViewController.beginGame()
            }
        } else {
            let gameViewController = transitionContext.viewController(forKey: .from) as! GameViewController
            let mainViewController = transitionContext.viewController(forKey: .to) as! MainViewController
            containerView.addSubview(mainViewController.view)

            let boardTransform = mainViewController.boardView.transform

            UIView.animate(
                withDuration: duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0,
                options: [], animations: {
                    self.performGameOut(gameViewController, using: boardTransform)
                    self.performMainIn(mainViewController)
                }
            ) { _ in
                transitionContext.completeTransition(true)
            }
        }
    }

    private func performMainOut(_ mainViewController: MainViewController, using boardTransform: CGAffineTransform) {
        mainViewController.boardView.transform = boardTransform
        mainViewController.header.transform = GameBoardAnimator.slideUp
        mainViewController.boardNameLabel.transform = GameBoardAnimator.slideUp
        mainViewController.pageControl.transform = GameBoardAnimator.slideUp
        mainViewController.helpText.transform = GameBoardAnimator.slideDown
        mainViewController.view.alpha = 0
    }

    private func performMainIn(_ mainViewController: MainViewController) {
        mainViewController.boardView.transform = .identity
        mainViewController.header.transform = .identity
        mainViewController.boardNameLabel.transform = .identity
        mainViewController.pageControl.transform = .identity
        mainViewController.helpText.transform = .identity
        mainViewController.view.alpha = 1
    }

    private func performGameOut(_ gameViewController: GameViewController, using boardTransform: CGAffineTransform) {
        gameViewController.boardView.transform = boardTransform.inverted()
        gameViewController.stats.transform = GameBoardAnimator.slideUp
        gameViewController.buttons.transform = GameBoardAnimator.slideDown
        gameViewController.progressBar.transform = GameBoardAnimator.slideDown
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
