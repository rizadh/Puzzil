//
//  ResultView.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-05-28.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

class ResultView: UIView {
    var result: BestTimeUpdateResult? {
        didSet { updateLabels() }
    }

    let messageText = UILabel()
    let timeText = UILabel()
    let statusTag = UIView()
    let statusText = UILabel()

    var statusTagConstraints = [NSLayoutConstraint]()
    var noStatusTagConstraints = [NSLayoutConstraint]()

    init() {
        super.init(frame: .zero)

        backgroundColor = ColorTheme.selected.secondary
        layer.cornerRadius = 16

        messageText.translatesAutoresizingMaskIntoConstraints = false
        messageText.font = UIFont.systemFont(ofSize: UIFont.labelFontSize * 1.25, weight: .medium)
        messageText.textColor = ColorTheme.selected.secondaryTextOnSecondary

        timeText.translatesAutoresizingMaskIntoConstraints = false
        timeText.font = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize * 3)
        timeText.textColor = ColorTheme.selected.primaryTextOnSecondary

        statusTag.translatesAutoresizingMaskIntoConstraints = false
        statusTag.layer.cornerRadius = 8
        statusTag.backgroundColor = ColorTheme.selected.primary

        statusText.translatesAutoresizingMaskIntoConstraints = false
        statusText.font = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)
        statusText.textColor = ColorTheme.selected.primaryTextOnPrimary

        statusTag.addSubview(statusText)

        addSubview(messageText)
        addSubview(timeText)
        addSubview(statusTag)

        let margin: CGFloat = 16
        let tagPadding: CGFloat = 8

        let timeTextLayoutGuide = UILayoutGuide()
        addLayoutGuide(timeTextLayoutGuide)

        statusTagConstraints = [
            bottomAnchor.constraint(equalTo: statusTag.bottomAnchor, constant: margin),
            timeTextLayoutGuide.bottomAnchor.constraint(equalTo: statusTag.topAnchor),
        ]
        noStatusTagConstraints = [
            bottomAnchor.constraint(greaterThanOrEqualTo: timeText.bottomAnchor, constant: margin),
            timeTextLayoutGuide.bottomAnchor.constraint(equalTo: bottomAnchor),
        ]

        NSLayoutConstraint.activate([
            widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 200),

            messageText.leftAnchor.constraint(greaterThanOrEqualTo: leftAnchor, constant: margin),
            messageText.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor, constant: -margin),
            messageText.centerXAnchor.constraint(equalTo: centerXAnchor),
            messageText.topAnchor.constraint(equalTo: topAnchor, constant: margin),

            timeTextLayoutGuide.topAnchor.constraint(equalTo: messageText.bottomAnchor),

            timeText.leftAnchor.constraint(greaterThanOrEqualTo: leftAnchor, constant: margin),
            timeText.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor, constant: -margin),
            timeText.centerXAnchor.constraint(equalTo: centerXAnchor),
            timeText.centerYAnchor.constraint(equalTo: timeTextLayoutGuide.centerYAnchor),

            statusTag.leftAnchor.constraint(greaterThanOrEqualTo: leftAnchor, constant: margin),
            statusTag.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor, constant: -margin),
            statusTag.centerXAnchor.constraint(equalTo: centerXAnchor),

            statusText.centerXAnchor.constraint(equalTo: statusTag.centerXAnchor),
            statusText.centerYAnchor.constraint(equalTo: statusTag.centerYAnchor),
            statusText.leftAnchor.constraint(equalTo: statusTag.leftAnchor, constant: tagPadding),
            statusText.rightAnchor.constraint(equalTo: statusTag.rightAnchor, constant: -tagPadding),
            statusText.topAnchor.constraint(equalTo: statusTag.topAnchor, constant: tagPadding),
            statusText.bottomAnchor.constraint(equalTo: statusTag.bottomAnchor, constant: -tagPadding),
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateLabels() {
        guard let result = result else { return }

        switch result {
        case let .created(time):
            messageText.text = MessageProvider.nextFirstSolveMessage()
            timeText.text = String(format: "%.1f s", time)
            statusTag.isHidden = true
            NSLayoutConstraint.deactivate(statusTagConstraints)
            NSLayoutConstraint.activate(noStatusTagConstraints)
        case let .preserved(oldTime, newTime):
            messageText.text = MessageProvider.nextSolveMessage()
            timeText.text = String(format: "%.1f s", newTime)
            statusText.text = String(format: "Best: %.1f s", oldTime)
            statusTag.isHidden = false
            NSLayoutConstraint.deactivate(noStatusTagConstraints)
            NSLayoutConstraint.activate(statusTagConstraints)
        case let .replaced(oldTime, newTime):
            messageText.text = MessageProvider.nextBestSolveMessage()
            timeText.text = String(format: "%.1f s", newTime)
            statusText.text = String(format: "Previous Best: %.1f s", oldTime)
            statusTag.isHidden = false
            NSLayoutConstraint.deactivate(noStatusTagConstraints)
            NSLayoutConstraint.activate(statusTagConstraints)
        }
    }
}

private struct MessageProvider {
    static var firstSolveMessageIndex = 0
    static let firstSolveMessages = [
        "First solve!",
        "Another board down.",
        "Tricky, wasn't it?",
    ]

    static var solveMessageIndex = 0
    static let solveMessages = [
        "Give it another shot!",
        "Not bad.",
        "Let's try that again?",
    ]

    static var bestSolveMessageIndex = 0
    static let bestSolveMessages = [
        "You're on a role!",
        "I'm impressed.",
        "Time for a break?",
    ]

    static func nextFirstSolveMessage() -> String {
        let message = firstSolveMessages[firstSolveMessageIndex]
        firstSolveMessageIndex = (firstSolveMessageIndex + 1) % firstSolveMessages.count
        return message
    }

    static func nextSolveMessage() -> String {
        let message = solveMessages[solveMessageIndex]
        solveMessageIndex = (solveMessageIndex + 1) % solveMessages.count
        return message
    }

    static func nextBestSolveMessage() -> String {
        let message = bestSolveMessages[bestSolveMessageIndex]
        bestSolveMessageIndex = (bestSolveMessageIndex + 1) % bestSolveMessages.count
        return message
    }
}
