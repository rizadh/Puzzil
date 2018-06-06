//
//  StatView.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-10.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

class StatView: UIView {
    let titleLabel = UILabel()
    let valueLabel = UILabel()

    init() {
        super.init(frame: .zero)

        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let width = max(titleLabel.intrinsicContentSize.width, valueLabel.intrinsicContentSize.width)
        let height = titleLabel.intrinsicContentSize.height + valueLabel.intrinsicContentSize.height

        return CGSize(width: width, height: height)
    }

    func setupSubviews() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)
        titleLabel.textColor = ColorTheme.selected.primaryTextOnBackground

        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: UIFont.labelFontSize, weight: .medium)
        valueLabel.textColor = ColorTheme.selected.secondaryTextOnBackground

        addSubview(titleLabel)
        addSubview(valueLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            valueLabel.topAnchor.constraint(equalTo: titleLabel.lastBaselineAnchor, constant: 8),
            valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            valueLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }
}
