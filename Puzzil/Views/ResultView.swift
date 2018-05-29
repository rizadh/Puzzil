//
//  ResultView.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-05-28.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

class ResultView: UIView {
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

    var result: BestTimeUpdateResult? {
        didSet { updateLabels() }
    }

    let messageText = UILabel()
    let timeText = UILabel()
    let statusTag = UIView()
    let statusText = UILabel()

    convenience init() {
        self.init(frame: .zero)

        backgroundColor = .white
        layer.cornerRadius = 16

        setupSubviews()
    }

    private func setupSubviews() {
        messageText.translatesAutoresizingMaskIntoConstraints = false
        messageText.font = UIFont.systemFont(ofSize: UIFont.labelFontSize * 1.25, weight: .medium)
        messageText.textColor = .themeSecondaryText

        timeText.translatesAutoresizingMaskIntoConstraints = false
        timeText.font = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize * 3)
        timeText.textColor = .themeTile

        statusTag.translatesAutoresizingMaskIntoConstraints = false
        statusTag.layer.cornerRadius = 16
        statusTag.backgroundColor = UIColor(white: 0.95, alpha: 1)

        statusText.translatesAutoresizingMaskIntoConstraints = false
        statusText.font = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)
        statusText.textColor = UIColor(white: 0.5, alpha: 1)

        statusTag.addSubview(statusText)

        addSubview(messageText)
        addSubview(timeText)
        addSubview(statusTag)

        let margin: CGFloat = 32
        let padding: CGFloat = 16
        let tagPadding: CGFloat = 16

        NSLayoutConstraint.activate([
            messageText.leftAnchor.constraint(greaterThanOrEqualTo: leftAnchor, constant: padding),
            messageText.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor, constant: padding),
            messageText.centerXAnchor.constraint(equalTo: centerXAnchor),
            messageText.topAnchor.constraint(equalTo: topAnchor, constant: margin),

            timeText.leftAnchor.constraint(greaterThanOrEqualTo: leftAnchor, constant: margin),
            timeText.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor, constant: margin),
            timeText.centerXAnchor.constraint(equalTo: centerXAnchor),
            timeText.topAnchor.constraint(equalTo: messageText.bottomAnchor, constant: 0),
            timeText.centerYAnchor.constraint(equalTo: centerYAnchor),

            statusTag.leftAnchor.constraint(greaterThanOrEqualTo: leftAnchor, constant: margin),
            statusTag.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor, constant: margin),
            statusTag.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusTag.topAnchor.constraint(equalTo: timeText.bottomAnchor, constant: padding),

            statusText.centerXAnchor.constraint(equalTo: statusTag.centerXAnchor),
            statusText.centerYAnchor.constraint(equalTo: statusTag.centerYAnchor),
            statusText.leftAnchor.constraint(equalTo: statusTag.leftAnchor, constant: tagPadding),
            statusText.rightAnchor.constraint(equalTo: statusTag.rightAnchor, constant: -tagPadding),
            statusText.topAnchor.constraint(equalTo: statusTag.topAnchor, constant: tagPadding),
            statusText.bottomAnchor.constraint(equalTo: statusTag.bottomAnchor, constant: -tagPadding),

            bottomAnchor.constraint(greaterThanOrEqualTo: statusTag.bottomAnchor, constant: margin),
        ])
    }

    private func updateLabels() {
        guard let result = result else { return }

        switch result {
        case let .created(time):
            messageText.text = ResultView.nextFirstSolveMessage()
            timeText.text = String(format: "%.1f s", time)
            statusText.text = String(format: "Best Time", time)
        case let .preserved(oldTime, newTime):
            messageText.text = ResultView.nextSolveMessage()
            timeText.text = String(format: "%.1f s", newTime)
            statusText.text = String(format: "Best Time: %.1f s", oldTime)
        case let .replaced(oldTime, newTime):
            messageText.text = ResultView.nextBestSolveMessage()
            timeText.text = String(format: "%.1f s", newTime)
            statusText.text = String(format: "Previous Best Time: %.1f s", oldTime)
            statusTag.isHidden = false
        }
    }
}
