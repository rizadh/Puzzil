//
//  PUZBoardView.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-28.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import UIKit

class PUZBoardView: PUZGradientView {
    var tileViews = [PUZTileView]()
    var rowGuides = [UILayoutGuide]()
    var columnGuides = [UILayoutGuide]()
    var delegate: PUZBoardViewDelegate! {
        didSet { setupSubviews() }
    }

    init() {
        super.init(from: .themeForegroundPink, to: .themeForegroundOrange)

        isOpaque = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func clippingPath(for gradientBounds: CGRect) -> CGPath {
        let cornerRadius: CGFloat = 32
        let borderWidth: CGFloat = 8

        let outer = UIBezierPath(roundedRect: gradientBounds, cornerRadius: cornerRadius)
        let innerBounds = gradientBounds.insetBy(dx: borderWidth, dy: borderWidth)
        let innerRadius = cornerRadius - borderWidth
        let inner = UIBezierPath(roundedRect: innerBounds, cornerRadius: innerRadius)

        let shape = UIBezierPath()
        shape.append(inner)
        shape.append(outer)

        return shape.cgPath
    }

    private func setupSubviews() {
        clearTiles()
        generateColumnLayoutGuides()
        generateRowLayoutGuides()
        layoutTiles()
    }

    private func clearTiles() {
        tileViews.forEach { $0.removeFromSuperview() }
        tileViews.removeAll()

        rowGuides.forEach(removeLayoutGuide(_:))
        rowGuides.removeAll()

        columnGuides.forEach(removeLayoutGuide(_:))
        rowGuides.removeAll()
    }

    private func generateColumnLayoutGuides() {
        let columns = delegate.numberOfColumns(in: self)

        var lastAnchor = leftAnchor
        var constraints = [NSLayoutConstraint]()

        for columnIndex in 0..<columns {
            let columnGuide = UILayoutGuide()
            constraints.append(columnGuide.leftAnchor.constraint(equalTo: lastAnchor, constant: columnIndex == 0 ? 16 : 8))
            columnGuides.append(columnGuide)
            columnGuide.widthAnchor.constraint(equalToConstant: 10)
            addLayoutGuide(columnGuide)
            lastAnchor = columnGuide.rightAnchor
        }

        constraints.append(rightAnchor.constraint(equalTo: lastAnchor, constant: 16))

        NSLayoutConstraint.activate(constraints)
    }

    private func generateRowLayoutGuides() {
        let rows = delegate.numberOfRows(in: self)

        var lastAnchor = topAnchor
        var constraints = [NSLayoutConstraint]()

        for rowIndex in 0..<rows {
            let rowGuide = UILayoutGuide()
            constraints.append(rowGuide.topAnchor.constraint(equalTo: lastAnchor, constant: rowIndex == 0 ? 16 : 8))
            rowGuides.append(rowGuide)
            rowGuide.heightAnchor.constraint(equalToConstant: 10)
            addLayoutGuide(rowGuide)
            lastAnchor = rowGuide.bottomAnchor
        }

        constraints.append(bottomAnchor.constraint(equalTo: lastAnchor, constant: 16))

        NSLayoutConstraint.activate(constraints)
    }

    private func layoutTiles() {
        let columns = delegate.numberOfColumns(in: self)
        let rows = delegate.numberOfRows(in: self)

        for rowIndex in 0..<rows {
            for columnIndex in 0..<columns {
                let position = PUZTilePosition(row: rowIndex, column: columnIndex)

                guard let text = delegate.boardView(self, textForTileAt: position) else {
                    continue
                }

                let tile = PUZTileView()
                tile.translatesAutoresizingMaskIntoConstraints = false
                tile.text = text
                addSubview(tile)

                let columnGuide = columnGuides[columnIndex]
                let rowGuide = rowGuides[rowIndex]

                NSLayoutConstraint.activate([
                    tile.leftAnchor.constraint(equalTo: columnGuide.leftAnchor),
                    tile.rightAnchor.constraint(equalTo: columnGuide.rightAnchor),
                    tile.topAnchor.constraint(equalTo: rowGuide.topAnchor),
                    tile.bottomAnchor.constraint(equalTo: rowGuide.bottomAnchor),
                    tile.widthAnchor.constraint(equalTo: tile.heightAnchor),
                ])
            }
        }
    }
}
