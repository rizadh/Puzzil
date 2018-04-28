//
//  BoardSelectorViewController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-13.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

class BoardSelectorViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if UIColor.themeHeader.isLight {
            return .default
        } else {
            return .lightContent
        }
    }

    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let boardNameLabel = UILabel()
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    private let boardViewControllers = BoardConfiguration.builtins.map { configuration in
        return BoardViewController(for: configuration)
    }

    private var visibleBoardViewController: BoardViewController! {
        didSet {
            boardNameLabel.text = visibleBoardViewController.configuration.name.capitalized
        }
    }

    private let helpText = UILabel()
    private let pageControl = UIPageControl()

    override func viewDidLoad() {
        super.viewDidLoad()

        visibleBoardViewController = boardViewControllers.first!
        for boardViewController in boardViewControllers {
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(beginGame))
            boardViewController.view.addGestureRecognizer(tapGestureRecognizer)
        }

        view.backgroundColor = .themeBackground

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
        pageViewController.setViewControllers([boardViewControllers.first!], direction: .forward, animated: false, completion: nil)
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

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let index = boardViewControllers.index(of: viewController as! BoardViewController)!
        let previousIndex = index - 1

        if previousIndex >= 0 {
            return boardViewControllers[previousIndex]
        } else {
            return boardViewControllers.last!
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index = boardViewControllers.index(of: viewController as! BoardViewController)!
        let nextIndex = index + 1

        if nextIndex < boardViewControllers.count {
            return boardViewControllers[nextIndex]
        } else {
            return boardViewControllers.first!
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            let boardViewController = pageViewController.viewControllers!.first as! BoardViewController
            let index = boardViewControllers.index(of: boardViewController)!
            pageControl.currentPage = index
            visibleBoardViewController = boardViewController
        }
    }

    @objc private func beginGame() {
        let gameViewController = GameViewController(boardConfiguration: visibleBoardViewController.configuration, difficulty: 0.5)
        present(gameViewController, animated: false, completion: nil)
    }

    @objc private func navigateToCurrentPage() {
        let currentPage = pageControl.currentPage
        let previousPage = boardViewControllers.index(of: pageViewController.viewControllers!.first as! BoardViewController)!
        let viewController = boardViewControllers[currentPage]
        let completion: (Bool) -> Void = { _ in self.pageControl.updateCurrentPageDisplay() }

        let direction: UIPageViewControllerNavigationDirection = {
            if previousPage < currentPage { return .forward }
            return .reverse
        }()

        visibleBoardViewController = viewController
        pageViewController.setViewControllers([viewController], direction: direction, animated: true, completion: completion)
    }
}
