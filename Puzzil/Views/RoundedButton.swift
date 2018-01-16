//
//  RoundedButton.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-03.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit


class RoundedButton: GradientView, UIGestureRecognizerDelegate {
    typealias ButtonHandler = (RoundedButton) -> Void

    var text: String? {
        get {
            return labelView.text
        }
        set {
            labelView.text = newValue
        }
    }
    private let handler: ButtonHandler
    private let labelView = UILabel()
    private var _pressAnimator: Any!
    @available(iOS 11.0, *)
    private var pressAnimator: UIViewPropertyAnimator! {
        get {
            return _pressAnimator as? UIViewPropertyAnimator
        }

        set {
            _pressAnimator = newValue
        }
    }

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
        let pressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(buttonWasPressed(_:)))
        pressRecognizer.minimumPressDuration = 0
        pressRecognizer.delegate = self
        addGestureRecognizer(pressRecognizer)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(buttonWasTapped(_:))))
    }

    @objc private func buttonWasPressed(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            if #available(iOS 11.0, *) {
                if let pressAnimator = pressAnimator {
                    pressAnimator.stopAnimation(true)
                }

                let button = sender.view as! RoundedButton
                button.transform = .identity
                pressAnimator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.5, animations: {
                    button.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                })

                pressAnimator.pausesOnCompletion = true
                pressAnimator.startAnimation()
            }
        case .ended, .cancelled:
            if #available(iOS 11.0, *) {
                pressAnimator.isReversed = true
                pressAnimator.pausesOnCompletion = false
                pressAnimator.startAnimation()
            }
        default:
            break
        }
    }

    @objc private func buttonWasTapped(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            handler(self)
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
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
