//
//  RoundedButton.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-03.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

class RoundedButton: GradientView {
    typealias ButtonHandler = (RoundedButton) -> Void

    var text = "" {
        didSet {
            labelView.text = text
        }
    }
    let handler: ButtonHandler
    let labelView = UILabel()

    init(handler: @escaping ButtonHandler) {
        self.handler = handler

        super.init(from: .themeForegroundPink, to: .themeForegroundOrange)

        setupGestureRecognizer()
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupGestureRecognizer() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(buttonWasTapped(_:))))
    }

    @objc private func buttonWasTapped(_ sender: UITapGestureRecognizer) {
        handler(self)
    }

    private func setupSubviews() {
        layer.cornerRadius = 16

        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.textAlignment = .center
        labelView.textColor = .white

        addSubview(labelView)

        NSLayoutConstraint.activate([
            labelView.centerXAnchor.constraint(equalTo: centerXAnchor),
            labelView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        labelView.font = UIFont.systemFont(ofSize: frame.height / 2, weight: .bold)
    }
}
