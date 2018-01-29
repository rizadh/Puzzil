//
//  StatView.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-10.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

class StatView: UIView {
    var title = "" { didSet { titleView.text = title } }
    var value = "" { didSet { valueView.text = value } }
    let titleView = UILabel()
    let valueView = UILabel()

    init() {
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let width = max(titleView.intrinsicContentSize.width, valueView.intrinsicContentSize.width)
        let height = titleView.intrinsicContentSize.height + valueView.intrinsicContentSize.height

        return CGSize(width: width, height: height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.font = UIFont.preferredFont(forTextStyle: .headline)
        titleView.textColor = .themePrimaryText

        valueView.translatesAutoresizingMaskIntoConstraints = false
        valueView.textColor = .themeSecondaryText

        addSubview(titleView)
        addSubview(valueView)

        NSLayoutConstraint.activate([
            titleView.topAnchor.constraint(equalTo: topAnchor),
            valueView.topAnchor.constraint(equalTo: titleView.bottomAnchor),
            valueView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            valueView.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }
}
