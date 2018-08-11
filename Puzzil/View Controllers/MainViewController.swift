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
private let footerHeight: CGFloat = 64

class MainViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    var collectionView: UICollectionView!
    var headerView: UIView!
    var footerView: UIView!

    override func viewDidLoad() {
        additionalSafeAreaInsets = UIEdgeInsets(top: headerHeight, left: 0, bottom: footerHeight, right: 0)

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
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: BoardBrowserLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = ColorTheme.selected.background
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(BoardCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.contentInsetAdjustmentBehavior = .always

        footerView = UIView()
        footerView.translatesAutoresizingMaskIntoConstraints = false

        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .prominent))
        effectView.translatesAutoresizingMaskIntoConstraints = false

        let startButton = UIButton()
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.backgroundColor = ColorTheme.selected.primary
        startButton.layer.cornerRadius = 16
        startButton.setTitle("Start", for: .normal)
        startButton.setTitleColor(.white, for: .normal)
        startButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)

        let footerBorder = UIView()
        footerBorder.translatesAutoresizingMaskIntoConstraints = false
        footerBorder.backgroundColor = UIColor.black.withAlphaComponent(0.1)

        footerView.addSubview(effectView)
        footerView.addSubview(startButton)
        footerView.addSubview(footerBorder)

        NSLayoutConstraint.activate([
            effectView.topAnchor.constraint(equalTo: footerView.topAnchor),
            effectView.bottomAnchor.constraint(equalTo: footerView.bottomAnchor),
            effectView.leftAnchor.constraint(equalTo: footerView.leftAnchor),
            effectView.rightAnchor.constraint(equalTo: footerView.rightAnchor),

            startButton.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 8),
            startButton.heightAnchor.constraint(equalToConstant: 48),
            startButton.leftAnchor.constraint(equalTo: footerView.leftAnchor, constant: 8),
            startButton.rightAnchor.constraint(equalTo: footerView.rightAnchor, constant: -8),

            footerBorder.heightAnchor.constraint(equalToConstant: 1),
            footerBorder.topAnchor.constraint(equalTo: footerView.topAnchor),
            footerBorder.leftAnchor.constraint(equalTo: footerView.leftAnchor),
            footerBorder.rightAnchor.constraint(equalTo: footerView.rightAnchor),
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
}
