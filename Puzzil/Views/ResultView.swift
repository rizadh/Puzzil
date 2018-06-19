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

    var statusTagConstraint: NSLayoutConstraint!
    var noStatusTagConstraint: NSLayoutConstraint!

    init() {
        super.init(frame: .zero)

        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        messageText.translatesAutoresizingMaskIntoConstraints = false
        messageText.font = UIFont.systemFont(ofSize: UIFont.labelFontSize * 1.25, weight: .medium)
        messageText.textColor = ColorTheme.selected.secondaryTextOnBackground

        timeText.translatesAutoresizingMaskIntoConstraints = false
        timeText.font = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize * 3)
        timeText.textColor = ColorTheme.selected.primaryTextOnBackground

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

        let padding: CGFloat = 32
        let tagPadding: CGFloat = 8

        statusTagConstraint = bottomAnchor.constraint(equalTo: statusTag.bottomAnchor)
        noStatusTagConstraint = bottomAnchor.constraint(equalTo: timeText.bottomAnchor)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(greaterThanOrEqualTo: heightAnchor),

            messageText.leftAnchor.constraint(greaterThanOrEqualTo: leftAnchor),
            messageText.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor),
            messageText.centerXAnchor.constraint(equalTo: centerXAnchor),
            messageText.topAnchor.constraint(equalTo: topAnchor),

            timeText.leftAnchor.constraint(greaterThanOrEqualTo: leftAnchor),
            timeText.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor),
            timeText.centerXAnchor.constraint(equalTo: centerXAnchor),
            timeText.topAnchor.constraint(equalTo: messageText.bottomAnchor, constant: padding),

            statusTag.leftAnchor.constraint(greaterThanOrEqualTo: leftAnchor),
            statusTag.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor),
            statusTag.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusTag.topAnchor.constraint(equalTo: timeText.bottomAnchor, constant: padding),

            statusText.centerXAnchor.constraint(equalTo: statusTag.centerXAnchor),
            statusText.centerYAnchor.constraint(equalTo: statusTag.centerYAnchor),
            statusText.leftAnchor.constraint(equalTo: statusTag.leftAnchor, constant: tagPadding),
            statusText.rightAnchor.constraint(equalTo: statusTag.rightAnchor, constant: -tagPadding),
            statusText.topAnchor.constraint(equalTo: statusTag.topAnchor, constant: tagPadding),
            statusText.bottomAnchor.constraint(equalTo: statusTag.bottomAnchor, constant: -tagPadding),
        ])
    }

    private func updateLabels() {
        guard let result = result else { return }

        switch result {
        case let .created(time):
            messageText.text = MessageProvider.nextFirstSolveMessage()
            timeText.text = String(format: "%.1f s", time)
            statusTag.isHidden = true
            noStatusTagConstraint.isActive = true
            statusTagConstraint.isActive = false
        case let .preserved(oldTime, newTime):
            messageText.text = MessageProvider.nextSolveMessage()
            timeText.text = String(format: "%.1f s", newTime)
            statusText.text = String(format: "Current Best: %.1f s", oldTime)
            statusTag.isHidden = false
            noStatusTagConstraint.isActive = false
            statusTagConstraint.isActive = true
        case let .replaced(oldTime, newTime):
            messageText.text = MessageProvider.nextBestSolveMessage()
            timeText.text = String(format: "%.1f s", newTime)
            statusText.text = String(format: "Previous Best: %.1f s", oldTime)
            statusTag.isHidden = false
            noStatusTagConstraint.isActive = false
            statusTagConstraint.isActive = true
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
