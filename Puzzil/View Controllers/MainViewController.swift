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
private let horizontalFooterHeight: CGFloat = 80
private let verticalFooterWidth: CGFloat = 128

class MainViewController: UIViewController {
    // MARK: - UIViewController Property Overrides

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Subviews

    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
    let headerView = UIView()
    let footerView = UIView()

    private let collectionViewLayout = BoardSelectorLayout()
    private let headerLabel = UILabel()
    private let footerStackView = UIStackView()
    private let bestTimeStat = StatView()
    private let startButton = ThemedButton()

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

        footerView.translatesAutoresizingMaskIntoConstraints = false

        let blurEffectStyle: UIBlurEffect.Style
        switch ColorTheme.selected {
        case .light:
            blurEffectStyle = .light
        case .dark:
            blurEffectStyle = .dark
        }
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: blurEffectStyle))
        effectView.translatesAutoresizingMaskIntoConstraints = false

        let footerBorder = UIView()
        footerBorder.translatesAutoresizingMaskIntoConstraints = false
        if ColorTheme.selected == .light {
            footerBorder.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        }

        bestTimeStat.titleLabel.text = "Best Time"
        bestTimeStat.valueLabel.text = "N/A"

        startButton.setTitle("Start", for: .normal)
        startButton.addTarget(self, action: #selector(startGame), for: .primaryActionTriggered)

        let leadingSpacerView = UIView(frame: .zero)
        let trailingSpacerView = UIView(frame: .zero)

        [leadingSpacerView, bestTimeStat, startButton, trailingSpacerView].forEach(footerStackView.addArrangedSubview(_:))
        footerStackView.translatesAutoresizingMaskIntoConstraints = false
        footerStackView.distribution = .equalSpacing
        footerStackView.alignment = .center

        footerView.addSubview(effectView)
        footerView.addSubview(footerBorder)
        footerView.addSubview(footerStackView)

        NSLayoutConstraint.activate([
            effectView.topAnchor.constraint(equalTo: footerView.topAnchor),
            effectView.bottomAnchor.constraint(equalTo: footerView.bottomAnchor),
            effectView.leftAnchor.constraint(equalTo: footerView.leftAnchor),
            effectView.rightAnchor.constraint(equalTo: footerView.rightAnchor),

            footerBorder.topAnchor.constraint(equalTo: footerView.topAnchor),
            footerBorder.leftAnchor.constraint(equalTo: footerView.leftAnchor),

            footerStackView.leftAnchor.constraint(equalTo: footerView.leftAnchor),
            footerStackView.topAnchor.constraint(equalTo: footerView.topAnchor),

            startButton.heightAnchor.constraint(equalToConstant: 48),
            startButton.widthAnchor.constraint(equalToConstant: 96),

            leadingSpacerView.widthAnchor.constraint(equalToConstant: 0),
            leadingSpacerView.heightAnchor.constraint(equalToConstant: 0),
            trailingSpacerView.widthAnchor.constraint(equalToConstant: 0),
            trailingSpacerView.heightAnchor.constraint(equalToConstant: 0),
        ])

        portraitLayoutConstraints.append(contentsOf: [
            footerBorder.rightAnchor.constraint(equalTo: footerView.rightAnchor),
            footerBorder.heightAnchor.constraint(equalToConstant: 0.5),

            footerStackView.heightAnchor.constraint(equalToConstant: horizontalFooterHeight),
            footerStackView.rightAnchor.constraint(equalTo: footerView.rightAnchor),
        ])

        landscapeLayoutConstraints.append(contentsOf: [
            footerBorder.bottomAnchor.constraint(equalTo: footerView.bottomAnchor),
            footerBorder.widthAnchor.constraint(equalToConstant: 0.5),

            footerStackView.widthAnchor.constraint(equalToConstant: verticalFooterWidth),
            footerStackView.bottomAnchor.constraint(equalTo: footerView.bottomAnchor),
        ])

        view.addSubview(collectionView)
        view.addSubview(headerView)
        view.addSubview(footerView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            headerView.rightAnchor.constraint(equalTo: view.rightAnchor),

            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor),

            footerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            footerView.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])

        portraitLayoutConstraints.append(contentsOf: [
            footerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            footerView.leftAnchor.constraint(equalTo: view.leftAnchor),
        ])

        landscapeLayoutConstraints.append(contentsOf: [
            footerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            footerView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
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

        if (traitCollection.horizontalSizeClass, traitCollection.verticalSizeClass) !=
            (previousTraitCollection?.horizontalSizeClass, previousTraitCollection?.verticalSizeClass) {
            adjustLayoutToSizeClass()
        }
    }

    // MARK: - Private Methods

    @objc private func startGame() {
        let boardStyle = BoardStyle.allCases[selectedItem]
        let gameViewController = GameViewController(boardStyle: boardStyle)

        present(gameViewController, animated: true)
    }

    private func updateStatView() {
        let boardStyle = BoardStyle.allCases[selectedItem]

        if let bestTime = BestTimesController.shared.getBestTime(for: boardStyle) {
            bestTimeStat.valueLabel.text = String(format: "%.1f s", bestTime)
        } else {
            bestTimeStat.valueLabel.text = "N/A"
        }
    }

    private func adjustLayoutToSizeClass() {
        switch (traitCollection.horizontalSizeClass, traitCollection.verticalSizeClass) {
        case (.regular, _), (.compact, .compact):
            footerStackView.axis = .vertical

            additionalSafeAreaInsets = UIEdgeInsets(
                top: compactHeaderHeight,
                left: 0,
                bottom: 0,
                right: verticalFooterWidth
            )

            NSLayoutConstraint.deactivate(portraitLayoutConstraints)
            NSLayoutConstraint.activate(landscapeLayoutConstraints)
        default:
            footerStackView.axis = .horizontal

            additionalSafeAreaInsets = UIEdgeInsets(
                top: regularHeaderHeight,
                left: 0,
                bottom: horizontalFooterHeight,
                right: 0
            )

            NSLayoutConstraint.deactivate(landscapeLayoutConstraints)
            NSLayoutConstraint.activate(portraitLayoutConstraints)
        }
    }

    private func shakeStartButton() {
        let angle: CGFloat = .pi / 32

        UIViewPropertyAnimator(duration: 0.2, curve: .easeOut) {
            UIView.animateKeyframes(withDuration: 0, delay: 0, options: [], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.125, animations: {
                    self.startButton.transform = CGAffineTransform(rotationAngle: angle)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.125, relativeDuration: 0.25, animations: {
                    self.startButton.transform = CGAffineTransform(rotationAngle: -angle)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.375, relativeDuration: 0.25, animations: {
                    self.startButton.transform = CGAffineTransform(rotationAngle: angle)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.625, relativeDuration: 0.25, animations: {
                    self.startButton.transform = CGAffineTransform(rotationAngle: -angle)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.875, relativeDuration: 0.125, animations: {
                    self.startButton.transform = .identity
                })
            })
        }.startAnimation()
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
            shakeStartButton()
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
