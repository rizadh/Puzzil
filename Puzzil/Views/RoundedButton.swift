//
//  RoundedButton.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-03.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit


class RoundedButton: UIView, UIGestureRecognizerDelegate {
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

    init(_ text: String, handler: @escaping ButtonHandler) {
        labelView.text = text
        self.handler = handler

        super.init(frame: .zero)

        backgroundColor = .button

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
        case .began: animateDepression()
        case .ended, .cancelled: animateRelease()
        default: break
        }
    }

    @objc private func buttonWasTapped(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            handler(self)
        }
    }

    private func animateDepression() {
        let alphaAnimationDuration = 0.1
        let scaleAnimationDuration = 0.25
        let dampingRatio: CGFloat = 1
        let scaleAnimations = { self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9) }
        let alphaAnimations = { self.labelView.alpha = 0.5 }

        if #available(iOS 10.0, *) {
            UIViewPropertyAnimator(duration: alphaAnimationDuration, curve: .linear, animations: alphaAnimations).startAnimation()
            UIViewPropertyAnimator(duration: scaleAnimationDuration, dampingRatio: dampingRatio, animations: scaleAnimations).startAnimation()
        } else {
            UIView.animate(withDuration: alphaAnimationDuration, delay: 0, options: .curveLinear, animations: alphaAnimations, completion: nil)
            UIView.animate(withDuration: scaleAnimationDuration, delay: 0, usingSpringWithDamping: dampingRatio, initialSpringVelocity: 1, options: UIViewAnimationOptions(rawValue: 0), animations: scaleAnimations, completion: nil)
        }
    }

    private func animateRelease() {
        let alphaAnimationDuration = 0.1
        let scaleAnimationDuration = 0.25
        let dampingRatio: CGFloat = 0.5
        let scaleAnimations = { self.transform = .identity }
        let alphaAnimations = { self.labelView.alpha = 1 }

        if #available(iOS 10.0, *) {
            UIViewPropertyAnimator(duration: alphaAnimationDuration, curve: .linear, animations: alphaAnimations).startAnimation()
            UIViewPropertyAnimator(duration: scaleAnimationDuration, dampingRatio: dampingRatio, animations: scaleAnimations).startAnimation()
        } else {
            UIView.animate(withDuration: alphaAnimationDuration, delay: 0, options: .curveLinear, animations: alphaAnimations, completion: nil)
            UIView.animate(withDuration: scaleAnimationDuration, delay: 0, usingSpringWithDamping: dampingRatio, initialSpringVelocity: 1, options: UIViewAnimationOptions(rawValue: 0), animations: scaleAnimations, completion: nil)
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
