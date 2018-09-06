//
//  MainViewController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-08-09.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

private let cellIdentifier = "BoardCell"
private let regularHeaderHeight: CGFloat = 64
private let compactHeaderHeight: CGFloat = 56
private let bottomStatViewHeight: CGFloat = 48
private let rightStatViewWidth: CGFloat = 96

private func blurStyle(for colorTheme: ColorTheme) -> UIBlurEffect.Style {
    switch colorTheme {
    case .light:
        return .dark
    case .dark:
        return .light
    }
}

class MainViewController: UIViewController {
    // MARK: - UIViewController Property Overrides

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Subviews

    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
    private let headerView = UIView()
    private let bestTimeView = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle(for: .selected)))

    private let collectionViewLayout = BoardSelectorLayout()
    private let headerLabel = UILabel()
    private let bestTimeTitle = UILabel()
    private let bestTimeValue = UILabel()

    // MARK: - Private Properties

    private var didScrollToFirstBoard = false
    private(set) var selectedItem = 0 { didSet { updateStatView() } }

    // MARK: - Adaptive Layout Constraints

    private var portraitLayoutConstraints = [NSLayoutConstraint]()
    private var landscapeLayoutConstraints = [NSLayoutConstraint]()

    // MARK: - UIViewController Method Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = ColorTheme.selected.primary

        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.attributedText = NSAttributedString(string: "PUZZIL", attributes: [.kern: 1.5])
        headerLabel.font = .systemFont(ofSize: 32, weight: .heavy)
        headerLabel.textColor = ColorTheme.selected.primaryTextOnPrimary

        headerView.addSubview(headerLabel)

        NSLayoutConstraint.activate([
            headerLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
        ])

        portraitLayoutConstraints.append(
            headerLabel.centerYAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -regularHeaderHeight / 2)
        )

        landscapeLayoutConstraints.append(
            headerLabel.centerYAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -compactHeaderHeight / 2)
        )

        collectionViewLayout.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = ColorTheme.selected.background
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(BoardCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.contentInsetAdjustmentBehavior = .always
        collectionView.scrollsToTop = false

        bestTimeView.translatesAutoresizingMaskIntoConstraints = false
        bestTimeView.layer.cornerRadius = 16
        bestTimeView.clipsToBounds = true
        bestTimeView.isUserInteractionEnabled = false

        bestTimeTitle.translatesAutoresizingMaskIntoConstraints = false
        bestTimeTitle.text = "Best Time"
        bestTimeTitle.font = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)
        bestTimeTitle.alpha = 0.75

        bestTimeValue.translatesAutoresizingMaskIntoConstraints = false
        bestTimeValue.text = "N/A"
        bestTimeValue.font = UIFont.monospacedDigitSystemFont(ofSize: UIFont.labelFontSize, weight: .medium)
        bestTimeValue.alpha = 0.5

        let vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: bestTimeView.effect as! UIBlurEffect))
        vibrancyView.translatesAutoresizingMaskIntoConstraints = false
        vibrancyView.contentView.addSubview(bestTimeTitle)
        vibrancyView.contentView.addSubview(bestTimeValue)

        bestTimeView.contentView.addSubview(vibrancyView)

        NSLayoutConstraint.activate([
            vibrancyView.topAnchor.constraint(equalTo: bestTimeView.topAnchor),
            vibrancyView.bottomAnchor.constraint(equalTo: bestTimeView.bottomAnchor),
            vibrancyView.leftAnchor.constraint(equalTo: bestTimeView.leftAnchor),
            vibrancyView.rightAnchor.constraint(equalTo: bestTimeView.rightAnchor),
        ])

        portraitLayoutConstraints.append(contentsOf: [
            bestTimeTitle.rightAnchor.anchorWithOffset(to: bestTimeValue.leftAnchor).constraint(equalToConstant: 8),

            bestTimeTitle.leftAnchor.constraint(equalTo: bestTimeView.leftAnchor, constant: 16),
            bestTimeTitle.centerYAnchor.constraint(equalTo: bestTimeView.centerYAnchor),

            bestTimeValue.rightAnchor.constraint(equalTo: bestTimeView.rightAnchor, constant: -16),
            bestTimeValue.centerYAnchor.constraint(equalTo: bestTimeView.centerYAnchor),
        ])

        landscapeLayoutConstraints.append(contentsOf: [
            bestTimeTitle.lastBaselineAnchor.anchorWithOffset(to: bestTimeValue.topAnchor).constraint(equalToConstant: 8),

            bestTimeTitle.topAnchor.constraint(equalTo: bestTimeView.topAnchor, constant: 16),
            bestTimeTitle.centerXAnchor.constraint(equalTo: bestTimeView.centerXAnchor),

            bestTimeValue.lastBaselineAnchor.constraint(equalTo: bestTimeView.bottomAnchor, constant: -16),
            bestTimeValue.centerXAnchor.constraint(equalTo: bestTimeView.centerXAnchor),
        ])

        view.addSubview(collectionView)
        view.addSubview(headerView)
        view.addSubview(bestTimeView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            headerView.rightAnchor.constraint(equalTo: view.rightAnchor),

            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])

        portraitLayoutConstraints.append(contentsOf: [
            bestTimeView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bestTimeView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            bestTimeView.heightAnchor.constraint(equalToConstant: bottomStatViewHeight),
        ])

        landscapeLayoutConstraints.append(contentsOf: [
            bestTimeView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            bestTimeView.widthAnchor.constraint(equalToConstant: rightStatViewWidth),
            bestTimeView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),

        ])

        BestTimesController.shared.subscribeToChanges { [weak self] in
            DispatchQueue.main.async {
                self?.updateStatView()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateStatView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)

        if !didScrollToFirstBoard {
            didScrollToFirstBoard = true
            collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: [.centeredVertically, .centeredHorizontally], animated: false)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass ||
            traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass {
            adjustLayoutToSizeClass()
        }
    }

    // MARK: - Public Methods

    func automaticallyStartGame(for boardStyle: BoardStyle) {
        guard presentedViewController == nil else {
            restartCurrentGame()
            return
        }

        let index = BoardStyle.allCases.firstIndex(of: boardStyle)!
        collectionView.scrollToItem(at: [0, index], at: [.centeredHorizontally, .centeredVertically], animated: false)
        startGame(for: boardStyle, animated: false)
    }

    // MARK: - Private Methods

    @objc private func startGameForSelectedItem() {
        let boardStyle = BoardStyle.allCases[selectedItem]
        startGame(for: boardStyle, animated: true)
    }

    private func startGame(for boardStyle: BoardStyle, animated: Bool) {
        let gameViewController = GameViewController(boardStyle: boardStyle)

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.lastBoardStyle = boardStyle

        present(gameViewController, animated: animated)
    }

    private func restartCurrentGame() {
        let gameViewController = presentedViewController as! GameViewController

        gameViewController.restartButtonWasTapped()
    }

    private func updateStatView() {
        let boardStyle = BoardStyle.allCases[selectedItem]

        if let bestTime = BestTimesController.shared.getBestTime(for: boardStyle) {
            bestTimeValue.text = String(format: "%.1f s", bestTime)
        } else {
            bestTimeValue.text = "N/A"
        }
    }

    private func adjustLayoutToSizeClass() {
        switch (traitCollection.horizontalSizeClass, traitCollection.verticalSizeClass) {
        case (.regular, _), (.compact, .compact):
            additionalSafeAreaInsets = UIEdgeInsets(
                top: compactHeaderHeight,
                left: 0,
                bottom: 0,
                right: rightStatViewWidth + 16
            )

            NSLayoutConstraint.deactivate(portraitLayoutConstraints)
            NSLayoutConstraint.activate(landscapeLayoutConstraints)
        default:
            additionalSafeAreaInsets = UIEdgeInsets(
                top: regularHeaderHeight,
                left: 0,
                bottom: bottomStatViewHeight + 16,
                right: 0
            )

            NSLayoutConstraint.deactivate(landscapeLayoutConstraints)
            NSLayoutConstraint.activate(portraitLayoutConstraints)
        }
    }
}

// MARK: - UICollectionViewDataSource Conformance

extension MainViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return BoardStyle.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! BoardCell

        cell.boardStyle = BoardStyle.allCases[indexPath.item]

        return cell
    }
}

// MARK: - UICollectionViewDelegate Conformance

extension MainViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == selectedItem {
            startGameForSelectedItem()
        } else {
            collectionView.scrollToItem(at: indexPath, at: [.centeredHorizontally, .centeredVertically], animated: true)
        }
    }
}

// MARK: - BoardSelectorLayoutDelegate Conformance

extension MainViewController: BoardSelectorLayoutDelegate {
    func boardSelector(didSelectItemAt indexPath: IndexPath) {
        selectedItem = indexPath.item
    }
}
