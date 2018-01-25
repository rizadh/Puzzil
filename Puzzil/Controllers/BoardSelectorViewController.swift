//
//  BoardSelectorViewController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-13.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

class BoardSelectorViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    private let pageControl = UIPageControl()
    private let boardViewControllers = (UIApplication.shared.delegate as! AppDelegate).boardConfigurations.map { configuration in
        return BoardViewController(for: configuration)
    }

    private var gradientUpdater: CADisplayLink!
    private let gradientView = GradientView(from: .themeBackgroundPink, to: .themeBackgroundOrange)
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    let headerView = GradientView(from: .themeForegroundPink, to: .themeForegroundOrange)
    let titleLabel = UILabel()

    var foregroundViews: [UIView] { return view.subviews.filter { $0 != gradientView } }

    override func viewDidLoad() {
        super.viewDidLoad()

        gradientUpdater = CADisplayLink(target: self, selector: #selector(updateAllGradients))
        gradientUpdater.add(to: .main, forMode: .commonModes)

        gradientView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gradientView)

        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.attributedText = NSAttributedString.init(string: "PUZZIL", attributes: [.kern: 1.5])
        titleLabel.font = {
            let baseFont = UIFont.systemFont(ofSize: 40, weight: .heavy)
            if #available(iOS 11.0, *) {
                return UIFontMetrics(forTextStyle: .headline).scaledFont(for: baseFont)
            } else {
                return baseFont
            }
        }()
        titleLabel.textColor = .white
        headerView.addSubview(titleLabel)

        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        pageViewController.dataSource = self
        pageViewController.delegate = self
        pageViewController.setViewControllers([boardViewControllers.first!], direction: .forward, animated: false, completion: nil)
        addChildViewController(pageViewController)
        pageViewController.didMove(toParentViewController: self)
        view.addSubview(pageViewController.view)

        pageControl.numberOfPages = boardViewControllers.count
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.5)
        pageControl.currentPageIndicatorTintColor = .themeForegroundOrange
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
            gradientView.leftAnchor.constraint(equalTo: view.leftAnchor),
            gradientView.rightAnchor.constraint(equalTo: view.rightAnchor),
            gradientView.topAnchor.constraint(equalTo: view.topAnchor),
            gradientView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 8),
            titleLabel.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),

            headerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            headerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),

            pageViewController.view.leftAnchor.constraint(equalTo: safeArea.leftAnchor),
            pageViewController.view.rightAnchor.constraint(equalTo: safeArea.rightAnchor),
            pageViewController.view.topAnchor.constraint(equalTo: headerView.bottomAnchor),

            pageControl.leftAnchor.constraint(equalTo: safeArea.leftAnchor),
            pageControl.rightAnchor.constraint(equalTo: safeArea.rightAnchor),
            pageControl.topAnchor.constraint(equalTo: pageViewController.view.bottomAnchor),
            pageControl.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
        ])

        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "com.rizadh.Puzzil.beginGame"), object: nil, queue: nil) { [unowned self] notification in
            let configuration = notification.userInfo!["configuration"] as! BoardConfiguration
            self.beginGame(with: configuration)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let alphaAnimationDuration = 0.1
        let translationAnimationDuration = 0.25
        let dampingRatio: CGFloat = 1
        let alphaAnimations = {
            self.foregroundViews.forEach { $0.alpha = 1 }
        }
        let scaleAnimations = {
            self.headerView.transform = .identity
        }

        if #available(iOS 10.0, *) {
            UIViewPropertyAnimator(duration: alphaAnimationDuration, curve: .linear, animations: alphaAnimations).startAnimation()
            UIViewPropertyAnimator(duration: translationAnimationDuration, dampingRatio: dampingRatio, animations: scaleAnimations).startAnimation()
        } else {
            UIView.animate(withDuration: alphaAnimationDuration, delay: 0, options: .curveLinear, animations: alphaAnimations, completion: nil)
            UIView.animate(withDuration: translationAnimationDuration, delay: 0, usingSpringWithDamping: dampingRatio, initialSpringVelocity: 1, options: UIViewAnimationOptions(rawValue: 0), animations: scaleAnimations, completion: nil)
        }
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
            let index = boardViewControllers.index(of: pageViewController.viewControllers!.first as! BoardViewController)!
            pageControl.currentPage = index
        }
    }

    @objc private func updateAllGradients() {
        boardViewControllers.forEach { $0.updateGradient() }
    }

    private func beginGame(with configuration: BoardConfiguration) {
        let board = Board(from: configuration.matrix)
        let gameViewController = GameViewController(board: board, difficulty: 0.5)

        present(gameViewController, animated: false, completion: nil)
    }

    @objc private func navigateToCurrentPage() {
        let currentPage = pageControl.currentPage
        let previousPage = boardViewControllers.index(of: pageViewController.viewControllers!.first as! BoardViewController)!
        let viewController = boardViewControllers[currentPage]
        let completion: (Bool) -> Void = { _ in
            self.pageControl.updateCurrentPageDisplay()
        }

        let direction: UIPageViewControllerNavigationDirection = {
            if previousPage < currentPage { return .forward }
            return .reverse
        }()

        pageViewController.setViewControllers([viewController], direction: direction, animated: true, completion: completion)
    }
}
