//
//  PUZViewController.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-22.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import SpriteKit
import CoreMotion

class PUZViewController: UIViewController {
    private let gradient: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.colors = [
            UIColor.themeBackgroundPink.cgColor,
            UIColor.themeBackgroundOrange.cgColor
        ]

        return gradient
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        let boardView = PUZBoardView(rows: 4, columns: 3)
        boardView.translatesAutoresizingMaskIntoConstraints = false

        let button1 = PUZGradientView(from: .themeForegroundPink, to: .themeForegroundOrange)
        button1.layer.cornerRadius = 32
        let button2 = PUZGradientView(from: .themeForegroundPink, to: .themeForegroundOrange)
        button2.layer.cornerRadius = 32
        let button3 = PUZGradientView(from: .themeForegroundPink, to: .themeForegroundOrange)
        button3.layer.cornerRadius = 32

        view.layer.addSublayer(gradient)

        let buttonsWrapper = UIStackView(arrangedSubviews: [
            button1,
            button2,
            button3,
        ])
        buttonsWrapper.translatesAutoresizingMaskIntoConstraints = false
        buttonsWrapper.distribution = .fillEqually
        buttonsWrapper.spacing = 16

        view.addSubview(boardView)
        view.addSubview(buttonsWrapper)

        NSLayoutConstraint.activate([
            boardView.leftAnchor.constraintEqualToSystemSpacingAfter(view.safeAreaLayoutGuide.leftAnchor, multiplier: 2),
            view.safeAreaLayoutGuide.rightAnchor.constraintEqualToSystemSpacingAfter(boardView.rightAnchor, multiplier: 2),
            boardView.topAnchor.constraintEqualToSystemSpacingBelow(view.safeAreaLayoutGuide.topAnchor, multiplier: 2),

            buttonsWrapper.leftAnchor.constraintEqualToSystemSpacingAfter(view.safeAreaLayoutGuide.leftAnchor, multiplier: 2),
            view.safeAreaLayoutGuide.rightAnchor.constraintEqualToSystemSpacingAfter(buttonsWrapper.rightAnchor, multiplier: 2),
            buttonsWrapper.topAnchor.constraintEqualToSystemSpacingBelow(boardView.bottomAnchor, multiplier: 1),
            view.safeAreaLayoutGuide.bottomAnchor.constraintEqualToSystemSpacingBelow(buttonsWrapper.bottomAnchor, multiplier: 2),

            buttonsWrapper.heightAnchor.constraint(equalToConstant: 64),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        gradient.frame = view.layer.bounds
    }
}
