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

class MainViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, BoardSelectorLayoutDelegate {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    var collectionView: UICollectionView!
    var collectionViewLayout: BoardSelectorLayout!
    var headerView: UIView!
    var footerView: UIView!
    var footerStackView: UIStackView!
    var bestTimeStat: StatView!
    var startButton: UIButton!

    var selectedItem = 0
    var bestTimesController: BestTimesController!

    var portraitLayoutConstraints = [NSLayoutConstraint]()
    var landscapeLayoutConstraints = [NSLayoutConstraint]()

    override func viewDidLoad() {
        super.viewDidLoad()

        headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = ColorTheme.selected.primary

        let headerLabel = UILabel()
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.attributedText = NSAttributedString(string: "PUZZIL", attributes: [.kern: 1.5])
        headerLabel.font = .systemFont(ofSize: 32, weight: .heavy)
        headerLabel.textColor = .white

        let headerBorder = UIView()
        headerBorder.translatesAutoresizingMaskIntoConstraints = false
        headerBorder.backgroundColor = UIColor.black.withAlphaComponent(0.1)

        headerView.addSubview(headerLabel)
        headerView.addSubview(headerBorder)

        NSLayoutConstraint.activate([
            headerLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),

            headerBorder.heightAnchor.constraint(equalToConstant: 1),
            headerBorder.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            headerBorder.leftAnchor.constraint(equalTo: headerView.leftAnchor),
            headerBorder.rightAnchor.constraint(equalTo: headerView.rightAnchor),
        ])

        portraitLayoutConstraints.append(
            headerLabel.centerYAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -regularHeaderHeight / 2)
        )

        landscapeLayoutConstraints.append(
            headerLabel.centerYAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -compactHeaderHeight / 2)
        )

        collectionViewLayout = BoardSelectorLayout()
        collectionViewLayout.delegate = self
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = ColorTheme.selected.background
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(BoardCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.contentInsetAdjustmentBehavior = .always

        footerView = UIView()
        footerView.translatesAutoresizingMaskIntoConstraints = false

        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .prominent))
        effectView.translatesAutoresizingMaskIntoConstraints = false

        let footerBorder = UIView()
        footerBorder.translatesAutoresizingMaskIntoConstraints = false
        footerBorder.backgroundColor = UIColor.black.withAlphaComponent(0.1)

        bestTimeStat = StatView()
        bestTimeStat.titleLabel.text = "Best Time"
        bestTimeStat.valueLabel.text = "N/A"

        startButton = ThemedButton()
        startButton.setTitle("Start", for: .normal)
        startButton.setTitleColor(.white, for: .normal)
        startButton.addTarget(self, action: #selector(startGame), for: .primaryActionTriggered)

        let leadingSpacerView = UIView(frame: .zero)
        let trailingSpacerView = UIView(frame: .zero)

        footerStackView = UIStackView(arrangedSubviews: [leadingSpacerView, bestTimeStat, startButton, trailingSpacerView])
        footerStackView.translatesAutoresizingMaskIntoConstraints = false
        footerStackView.distribution = .equalCentering
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
            footerBorder.heightAnchor.constraint(equalToConstant: 1),

            footerStackView.heightAnchor.constraint(equalToConstant: horizontalFooterHeight),
            footerStackView.rightAnchor.constraint(equalTo: footerView.rightAnchor),
        ])

        landscapeLayoutConstraints.append(contentsOf: [
            footerBorder.bottomAnchor.constraint(equalTo: footerView.bottomAnchor),
            footerBorder.widthAnchor.constraint(equalToConstant: 1),

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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateStatView()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return BoardStyle.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! BoardCell

        cell.boardStyle = BoardStyle.allCases[indexPath.item]

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == selectedItem {
            startGame()
        } else {
            let contentOffset = collectionViewLayout.calculateContentOffset(for: indexPath)
            collectionView.setContentOffset(contentOffset, animated: true)
        }
    }

    @objc private func startGame() {
        let boardStyle = BoardStyle.allCases[selectedItem]
        let gameViewController = GameViewController(boardStyle: boardStyle)
        gameViewController.bestTimesController = bestTimesController

        present(gameViewController, animated: true) {
            gameViewController.beginGame()
        }
    }

    func boardSelector(didSelectItemAt indexPath: IndexPath) {
        selectedItem = indexPath.item
        updateStatView()
    }

    private func updateStatView() {
        let boardStyle = BoardStyle.allCases[selectedItem]

        if let bestTime = bestTimesController.getBestTime(for: boardStyle) {
            bestTimeStat.valueLabel.text = String(format: "%.1f s", bestTime)
        } else {
            bestTimeStat.valueLabel.text = "—"
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if (traitCollection.horizontalSizeClass, traitCollection.verticalSizeClass) != (previousTraitCollection?.horizontalSizeClass, previousTraitCollection?.verticalSizeClass) {
            adjustLayoutToSizeClass()
        }
    }

    private func adjustLayoutToSizeClass() {
        switch (traitCollection.horizontalSizeClass, traitCollection.verticalSizeClass) {
        case (.regular, _), (.compact, .compact):
            footerStackView.axis = .vertical

            additionalSafeAreaInsets = UIEdgeInsets(top: compactHeaderHeight, left: 0, bottom: 0, right: verticalFooterWidth)

            NSLayoutConstraint.deactivate(portraitLayoutConstraints)
            NSLayoutConstraint.activate(landscapeLayoutConstraints)
        default:
            footerStackView.axis = .horizontal

            additionalSafeAreaInsets = UIEdgeInsets(top: regularHeaderHeight, left: 0, bottom: horizontalFooterHeight, right: 0)

            NSLayoutConstraint.deactivate(landscapeLayoutConstraints)
            NSLayoutConstraint.activate(portraitLayoutConstraints)
        }
    }
}
