//
//  MainViewController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-13.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    override var prefersStatusBarHidden: Bool { return true }

    private let pageControl = UIPageControl()
    private let boardViewControllers = (UIApplication.shared.delegate as! AppDelegate).boardConfigurations.map { configuration in
        return BoardViewController(for: configuration)
    }

    private var gradientUpdater: CADisplayLink!
    private var gradientView: GradientView!
    private var pageViewController: UIPageViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        gradientUpdater = CADisplayLink(target: self, selector: #selector(updateAllGradients))
        gradientUpdater.add(to: .main, forMode: .commonModes)

        gradientView = GradientView(from: .themeBackgroundPink, to: .themeBackgroundOrange)
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gradientView)

        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
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

            pageViewController.view.leftAnchor.constraint(equalTo: safeArea.leftAnchor),
            pageViewController.view.rightAnchor.constraint(equalTo: safeArea.rightAnchor),
            pageViewController.view.topAnchor.constraint(equalTo: safeArea.topAnchor),

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

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let index = boardViewControllers.index(of: viewController as! BoardViewController)!
        let previousIndex = index - 1

        if previousIndex >= 0 {
            return boardViewControllers[previousIndex]
        } else {
            return nil
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index = boardViewControllers.index(of: viewController as! BoardViewController)!
        let nextIndex = index + 1

        if nextIndex < boardViewControllers.count {
            return boardViewControllers[nextIndex]
        } else {
            return nil
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
