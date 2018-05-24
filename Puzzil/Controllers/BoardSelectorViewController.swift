//
//  BoardSelectorViewController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-13.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

class BoardSelectorViewController: UIViewController {

    // MARK: UIViewController Property Overrides

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if UIColor.themeHeader.isLight {
            return .default
        } else {
            return .lightContent
        }
    }

    // MARK: - Subviews

    let headerView = UIView()
    let titleLabel = UILabel()
    let boardNameLabel = UILabel()
    let pageControl = UIPageControl()
    let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal,
                                                  options: nil)
    let helpText = UILabel()
    private let boardViewControllers = BoardStyle.all.map { boardStyle in
        return BoardViewController(boardStyle: boardStyle)
    }

    var visibleBoardViewController: BoardViewController {
        return boardViewControllers[pageControl.currentPage]
    }

    // MARK: - UI Updates

    private func updateBoardNameLabel() {
        boardNameLabel.text = visibleBoardViewController.boardStyle.rawValue.capitalized
    }

    // MARK: - Animation Management

    private let animator = BoardAnimator()
    private var latestPressRecognizer: UIGestureRecognizer?

    // MARK: - UIViewController Method Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        for boardViewController in boardViewControllers {
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(boardWasTapped))
            boardViewController.boardView.addGestureRecognizer(tapGestureRecognizer)

            let pressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(boardWasPressed))
            pressGestureRecognizer.minimumPressDuration = 0
            boardViewController.boardView.addGestureRecognizer(pressGestureRecognizer)

            pressGestureRecognizer.delegate = self
        }

        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = .themeHeader
        view.addSubview(headerView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .themeHeaderText
        titleLabel.attributedText = NSAttributedString(string: "PUZZIL", attributes: [.kern: 1.5])
        titleLabel.font = {
            let baseFont = UIFont.systemFont(ofSize: 32, weight: .heavy)
            if #available(iOS 11.0, *) {
                return UIFontMetrics(forTextStyle: .headline).scaledFont(for: baseFont)
            } else {
                return baseFont
            }
        }()
        headerView.addSubview(titleLabel)

        boardNameLabel.translatesAutoresizingMaskIntoConstraints = false
        boardNameLabel.font = UIFont.systemFont(ofSize: UIFont.labelFontSize, weight: .medium)
        boardNameLabel.textColor = .themePrimaryText
        view.addSubview(boardNameLabel)

        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        pageViewController.dataSource = self
        pageViewController.delegate = self
        pageViewController.setViewControllers([boardViewControllers.first!], direction: .forward, animated: false)
        addChildViewController(pageViewController)
        pageViewController.didMove(toParentViewController: self)
        view.addSubview(pageViewController.view)

        helpText.text = "Select a board to begin"
        helpText.translatesAutoresizingMaskIntoConstraints = false
        helpText.numberOfLines = 2
        helpText.textAlignment = .center
        helpText.textColor = .themeSecondaryText
        helpText.font = UIFont.systemFont(ofSize: UIFont.labelFontSize, weight: .medium)
        view.addSubview(helpText)

        pageControl.numberOfPages = boardViewControllers.count
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.pageIndicatorTintColor = .themePageControlInactive
        pageControl.currentPageIndicatorTintColor = .themePageControlActive
        pageControl.addTarget(self, action: #selector(navigateToCurrentPage), for: .valueChanged)
        pageControl.defersCurrentPageDisplay = true
        view.addSubview(pageControl)

        updateBoardNameLabel()

        let safeArea: UILayoutGuide = {
            if #available(iOS 11.0, *) {
                return view.safeAreaLayoutGuide
            } else {
                let safeAreaLayoutGuide = UILayoutGuide()

                view.addLayoutGuide(safeAreaLayoutGuide)

                NSLayoutConstraint.activate([
                    safeAreaLayoutGuide.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
                    safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor),
                    safeAreaLayoutGuide.leftAnchor.constraint(equalTo: view.leftAnchor),
                    safeAreaLayoutGuide.rightAnchor.constraint(equalTo: view.rightAnchor),
                ])

                return safeAreaLayoutGuide
            }
        }()

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 8),
            titleLabel.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),

            headerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            headerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),

            boardNameLabel.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            boardNameLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),

            pageControl.leftAnchor.constraint(equalTo: safeArea.leftAnchor),
            pageControl.rightAnchor.constraint(equalTo: safeArea.rightAnchor),
            pageControl.topAnchor.constraint(equalTo: boardNameLabel.lastBaselineAnchor),

            pageViewController.view.leftAnchor.constraint(equalTo: safeArea.leftAnchor),
            pageViewController.view.rightAnchor.constraint(equalTo: safeArea.rightAnchor),
            pageViewController.view.topAnchor.constraint(equalTo: pageControl.bottomAnchor, constant: 16),

            helpText.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            helpText.leftAnchor.constraint(greaterThanOrEqualTo: safeArea.leftAnchor, constant: 16),
            safeArea.rightAnchor.constraint(greaterThanOrEqualTo: helpText.rightAnchor, constant: 16),
            helpText.topAnchor.constraint(equalTo: pageViewController.view.bottomAnchor, constant: 16),
            safeArea.bottomAnchor.constraint(equalTo: helpText.bottomAnchor, constant: 16),
        ])
    }
}

// MARK: - Event Handlers

@objc private extension BoardSelectorViewController {
    func boardWasPressed(_ sender: UILongPressGestureRecognizer) {
        latestPressRecognizer = sender
        let boardView = visibleBoardViewController.boardView

        switch sender.state {
        case .began:
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0,
                           options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                               boardView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            })
        case .ended, .cancelled:
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0,
                           options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                               boardView.transform = .identity
            })
        default:
            break
        }
    }

    func boardWasTapped(_ sender: UITapGestureRecognizer) {
        let gameViewController = GameViewController(boardStyle: visibleBoardViewController.boardStyle, difficulty: 0.5)
        gameViewController.transitioningDelegate = self
        present(gameViewController, animated: true)
    }

    func navigateToCurrentPage() {
        let currentPage = pageControl.currentPage
        let boardViewController = pageViewController.viewControllers!.first as! BoardViewController
        let previousPage = boardViewControllers.index(of: boardViewController)!
        let viewController = boardViewControllers[currentPage]

        let direction: UIPageViewControllerNavigationDirection = {
            if previousPage < currentPage { return .forward }
            return .reverse
        }()

        pageViewController.setViewControllers([viewController], direction: direction, animated: true) { _ in
            self.pageControl.updateCurrentPageDisplay()
        }

        updateBoardNameLabel()
    }
}

// MARK: - BoardContainer

extension BoardSelectorViewController: BoardContainer {
    var boardView: BoardView {
        return visibleBoardViewController.boardView
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension BoardSelectorViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.presenting = true
        return animator
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.presenting = false
        return animator
    }
}

// MARK: - UIPageViewControllerDelegate

extension BoardSelectorViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - UIPageViewControllerDelegate

extension BoardSelectorViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let index = boardViewControllers.index(of: viewController as! BoardViewController)!
        let previousIndex = (index - 1 + boardViewControllers.count) % boardViewControllers.count
        return boardViewControllers[previousIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index = boardViewControllers.index(of: viewController as! BoardViewController)!
        let nextIndex = (index + 1) % boardViewControllers.count
        return boardViewControllers[nextIndex]
    }
}

// MARK: - UIPageViewControllerDataSource

extension BoardSelectorViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            let boardViewController = pageViewController.viewControllers!.first as! BoardViewController
            let index = boardViewControllers.index(of: boardViewController)!
            pageControl.currentPage = index
            updateBoardNameLabel()
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        latestPressRecognizer?.isEnabled = false
        latestPressRecognizer?.isEnabled = true
    }
}
