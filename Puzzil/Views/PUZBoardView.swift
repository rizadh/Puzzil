//
//  PUZBoardView.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-28.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import UIKit

class PUZBoardView: PUZGradientView {
    var rows: Int
    var columns: Int

    init(rows: Int, columns: Int) {
        self.rows = rows
        self.columns = columns

        super.init(from: .themeForegroundPink, to: .themeBackgroundOrange)

        isOpaque = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func boardDimensions(fitting bounds: CGRect) -> CGRect {
        let tileSize = min(
            bounds.height / CGFloat(rows),
            bounds.width / CGFloat(columns)
        )

        let height = tileSize * CGFloat(rows)
        let width = tileSize * CGFloat(columns)

        return CGRect(center: bounds.center, size: CGSize(width: width, height: height))
    }

    override func clippingPath(for gradientBounds: CGRect) -> CGPath {
        let cornerRadius: CGFloat = 32
        let borderWidth: CGFloat = 12
        let bounds = boardDimensions(fitting: gradientBounds)

        let outer = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
        let inner = UIBezierPath(roundedRect: bounds.insetBy(dx: borderWidth, dy: borderWidth), cornerRadius: cornerRadius - borderWidth)

        let shape = UIBezierPath()
        shape.append(inner)
        shape.append(outer)

        return shape.cgPath
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: 100, height: 100)
    }
}
