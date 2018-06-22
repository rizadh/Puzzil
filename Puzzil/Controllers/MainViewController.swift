//
//  MainViewController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-13.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    // MARK: UIViewController Property Overrides

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if ColorTheme.selected.primary.isLight {
            return .default
        } else {
            return .lightContent
        }
    }

    // MARK: - Subviews

    let header = UIView()
    let titleLabel = UILabel()
    let boardNameLabel = UILabel()
    let pageControl = UIPageControl()
    let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal,
                                                  options: nil)
    let helpText = UILabel()
    private lazy var boardViewControllers: [BoardSelectionViewController] = BoardStyle.allCases.map { boardStyle in
        let boardViewController = BoardSelectionViewController(boardStyle: boardStyle)
        boardViewController.bestTimesController = bestTimesController
        return boardViewController
    }

    var visibleBoardViewController: BoardSelectionViewController {
        return boardViewControllers[pageControl.currentPage]
    }

    var boardView: BoardView {
        return visibleBoardViewController.boardView
    }

    // MARK: - UI Updates

    private func updateBoardNameLabel() {
        boardNameLabel.text = visibleBoardViewController.boardStyle.rawValue.capitalized
    }

    // MARK: - Animation Management

    private let animator = GameBoardAnimator()

    // MARK: - Controller Dependencies

    var bestTimesController: BestTimesController!

    // MARK: - UIViewController Method Overrides

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        header.translatesAutoresizingMaskIntoConstraints = false
        header.backgroundColor = ColorTheme.selected.primary
        view.addSubview(header)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = ColorTheme.selected.primaryTextOnPrimary
        titleLabel.attributedText = NSAttributedString(string: "PUZZIL", attributes: [.kern: 1.5])
        titleLabel.font = {
            let baseFont = UIFont.systemFont(ofSize: 32, weight: .heavy)
            if #available(iOS 11.0, *) {
                return UIFontMetrics(forTextStyle: .headline).scaledFont(for: baseFont)
            } else {
                return baseFont
            }
        }()
        header.addSubview(titleLabel)

        boardNameLabel.translatesAutoresizingMaskIntoConstraints = false
        boardNameLabel.font = UIFont.systemFont(ofSize: UIFont.labelFontSize, weight: .medium)
        boardNameLabel.textColor = ColorTheme.selected.primaryTextOnBackground
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
        helpText.textColor = ColorTheme.selected.secondaryTextOnBackground
        helpText.font = UIFont.systemFont(ofSize: UIFont.labelFontSize, weight: .medium)
        view.addSubview(helpText)

        pageControl.numberOfPages = boardViewControllers.count
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.pageIndicatorTintColor = ColorTheme.selected.secondary
        pageControl.currentPageIndicatorTintColor = ColorTheme.selected.primary
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

            header.leftAnchor.constraint(equalTo: view.leftAnchor),
            header.rightAnchor.constraint(equalTo: view.rightAnchor),
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),

            boardNameLabel.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            boardNameLabel.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 16),

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
            view.bottomAnchor.constraint(greaterThanOrEqualTo: helpText.bottomAnchor, constant: 16),
        ] + [
            safeArea.bottomAnchor.constraint(equalTo: helpText.bottomAnchor),
        ].map({
            $0.priority = .defaultHigh
            return $0
        }))
    }
}

// MARK: - Event Handlers

@objc private extension MainViewController {
    func navigateToCurrentPage() {
        let currentPage = pageControl.currentPage
        let boardViewController = pageViewController.viewControllers!.first as! BoardSelectionViewController
        let previousPage = boardViewControllers.index(of: boardViewController)!
        let viewController = boardViewControllers[currentPage]
        let direction: UIPageViewControllerNavigationDirection = previousPage < currentPage ? .forward : .reverse

        pageViewController.setViewControllers([viewController], direction: direction, animated: true) { _ in
            self.pageControl.updateCurrentPageDisplay()
        }

        updateBoardNameLabel()
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension MainViewController: UIViewControllerTransitioningDelegate {
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

// MARK: - UIGestureRecognizerDelegate

extension MainViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - UIPageViewControllerDelegate

extension MainViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let index = boardViewControllers.index(of: viewController as! BoardSelectionViewController)!
        let previousIndex = (index - 1 + boardViewControllers.count) % boardViewControllers.count
        return boardViewControllers[previousIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index = boardViewControllers.index(of: viewController as! BoardSelectionViewController)!
        let nextIndex = (index + 1) % boardViewControllers.count
        return boardViewControllers[nextIndex]
    }
}

// MARK: - UIPageViewControllerDataSource

extension MainViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            let boardViewController = pageViewController.viewControllers!.first as! BoardSelectionViewController
            let index = boardViewControllers.index(of: boardViewController)!
            pageControl.currentPage = index
            updateBoardNameLabel()
        }
    }
}
