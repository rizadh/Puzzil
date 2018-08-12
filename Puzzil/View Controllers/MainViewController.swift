//
//  MainViewController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-08-09.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

private let cellIdentifier = "BoardCell"
private let headerHeight: CGFloat = 64
private let regularFooterHeight: CGFloat = 64
private let expandedFooterHeight: CGFloat = 80

class MainViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    var collectionView: UICollectionView!
    var collectionViewLayout: BoardBrowserLayout!

    var headerView: UIView!

    var footerView: UIView!
    var footerLabel: UILabel!
    var footerStackView: UIStackView!
    var bestTimeStat: StatView!
    var startButton: UIButton!

    var bestTimesController: BestTimesController!

    private var footerIsExpanded = false

    override func viewDidLoad() {
        additionalSafeAreaInsets = UIEdgeInsets(top: headerHeight, left: 0, bottom: regularFooterHeight, right: 0)

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
            headerLabel.centerYAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -headerHeight / 2),

            headerBorder.heightAnchor.constraint(equalToConstant: 1),
            headerBorder.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            headerBorder.leftAnchor.constraint(equalTo: headerView.leftAnchor),
            headerBorder.rightAnchor.constraint(equalTo: headerView.rightAnchor),
        ])

        collectionViewLayout = BoardBrowserLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = ColorTheme.selected.background
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(BoardCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.contentInsetAdjustmentBehavior = .always
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(collectionViewWasTapped))
        tapGestureRecognizer.cancelsTouchesInView = false
        collectionView.addGestureRecognizer(tapGestureRecognizer)

        footerView = UIView()
        footerView.translatesAutoresizingMaskIntoConstraints = false

        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .prominent))
        effectView.translatesAutoresizingMaskIntoConstraints = false

        footerLabel = UILabel()
        footerLabel.translatesAutoresizingMaskIntoConstraints = false
        footerLabel.text = "Select a board above to begin"
        footerLabel.textColor = UIColor.black.withAlphaComponent(0.5)

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
        footerStackView.alpha = 0
        footerStackView.exerciseAmbiguityInLayout()

        footerView.addSubview(effectView)
        footerView.addSubview(footerLabel)
        footerView.addSubview(footerBorder)
        footerView.addSubview(footerStackView)

        NSLayoutConstraint.activate([
            effectView.topAnchor.constraint(equalTo: footerView.topAnchor),
            effectView.bottomAnchor.constraint(equalTo: footerView.bottomAnchor),
            effectView.leftAnchor.constraint(equalTo: footerView.leftAnchor),
            effectView.rightAnchor.constraint(equalTo: footerView.rightAnchor),

            footerLabel.centerXAnchor.constraint(equalTo: footerView.centerXAnchor),
            footerLabel.centerYAnchor.constraint(equalTo: footerView.topAnchor, constant: regularFooterHeight / 2),

            footerBorder.heightAnchor.constraint(equalToConstant: 1),
            footerBorder.topAnchor.constraint(equalTo: footerView.topAnchor),
            footerBorder.leftAnchor.constraint(equalTo: footerView.leftAnchor),
            footerBorder.rightAnchor.constraint(equalTo: footerView.rightAnchor),

            footerStackView.centerYAnchor.constraint(equalTo: footerView.topAnchor, constant: expandedFooterHeight / 2),
            footerStackView.leftAnchor.constraint(equalTo: footerView.leftAnchor),
            footerStackView.rightAnchor.constraint(equalTo: footerView.rightAnchor),

            startButton.heightAnchor.constraint(equalTo: footerStackView.heightAnchor),
            startButton.widthAnchor.constraint(equalTo: footerStackView.heightAnchor, multiplier: 2),

            leadingSpacerView.widthAnchor.constraint(equalToConstant: 0),
            trailingSpacerView.widthAnchor.constraint(equalToConstant: 0),
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

            footerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            footerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            footerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            footerView.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
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
        if let selectedIndexPath = collectionViewLayout.selectedIndexPath, indexPath == selectedIndexPath {
            footerIsExpanded = false
        } else {
            footerIsExpanded = true
        }

        if footerIsExpanded {
            additionalSafeAreaInsets = UIEdgeInsets(top: headerHeight, left: 0, bottom: expandedFooterHeight, right: 0)
            collectionViewLayout.selectedIndexPath = indexPath
        } else {
            additionalSafeAreaInsets = UIEdgeInsets(top: headerHeight, left: 0, bottom: regularFooterHeight, right: 0)
            collectionViewLayout.selectedIndexPath = nil
        }

        let boardCell = collectionView.cellForItem(at: indexPath) as! BoardCell

        if let bestTime = bestTimesController.getBestTime(for: boardCell.boardStyle) {
            bestTimeStat.valueLabel.text = String(format: "%.1f s", bestTime)
        } else {
            bestTimeStat.valueLabel.text = "N/A"
        }

        UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.8) {
            self.footerLabel.alpha = self.footerIsExpanded ? 0 : 1
            self.footerStackView.alpha = self.footerIsExpanded ? 1 : 0
            self.collectionViewLayout.invalidateLayout()
            self.view.layoutIfNeeded()
        }.startAnimation()
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    @objc private func startGame() {
        guard let item = collectionViewLayout.selectedIndexPath?.item else { return }

        let boardStyle = BoardStyle.allCases[item]
        let gameViewController = GameViewController(boardStyle: boardStyle)
        gameViewController.bestTimesController = bestTimesController

        present(gameViewController, animated: true) {
            gameViewController.beginGame()
        }
    }

    @objc private func collectionViewWasTapped() {
        print("collectionViewWasTapped")
    }
}
