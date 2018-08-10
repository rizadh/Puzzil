//
//  BoardBrowserLayout.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-08-09.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

let minimumBoardWidth: CGFloat = 120
let maximumBoardWidth: CGFloat = 160
let minimumSpacing: CGFloat = 16

class BoardBrowserLayout: UICollectionViewLayout {
    var numberOfColumns = 0
    var contentsSize: CGSize = .zero
    var attributes = [UICollectionViewLayoutAttributes]()

    var boardWidth: CGFloat = 0
    var boardHeight: CGFloat {
        return boardWidth + 32
    }

    var horizontalSpacing: CGFloat = 0
    var verticalSpacing: CGFloat {
        return horizontalSpacing + 16
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return newBounds.width != contentsSize.width
    }

    override var collectionViewContentSize: CGSize {
        return contentsSize
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return attributes.filter { $0.frame.intersects(rect) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return attributes.first { $0.indexPath == indexPath }!
    }

    override func prepare() {
        super.prepare()

        guard let collectionView = collectionView else { return }

        let effectiveBounds = collectionView.bounds.inset(by: collectionView.safeAreaInsets)

        (numberOfColumns, boardWidth, horizontalSpacing) = calculateLayoutDimensions(availableWidth: effectiveBounds.width)

        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        attributes = (0..<numberOfItems).map {
            let indexPath = IndexPath(item: $0, section: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = calculateRect(for: $0)
            return attributes
        }

        let numberOfRows = Int((CGFloat(numberOfItems) / CGFloat(numberOfColumns)).rounded(.up))
        let bottomRightItem = numberOfRows * numberOfColumns - 1
        let outermostFrame = calculateRect(for: bottomRightItem)
        let x = outermostFrame.maxX + horizontalSpacing
        let y = outermostFrame.maxY + verticalSpacing
        contentsSize = CGSize(width: x, height: y)
    }

    private func calculateRect(for item: Int) -> CGRect {
        let row = item / numberOfColumns
        let column = item % numberOfColumns

        let x = horizontalSpacing + (horizontalSpacing + boardWidth) * CGFloat(column)
        let y = horizontalSpacing + (verticalSpacing + boardHeight) * CGFloat(row)

        return CGRect(x: x, y: y, width: boardWidth, height: boardHeight)
    }

    private func calculateLayoutDimensions(availableWidth: CGFloat) ->
        (numberOfColumns: Int, columnWidth: CGFloat, spacing: CGFloat) {
        let numberOfColumns = ((availableWidth - minimumSpacing) / (minimumBoardWidth + minimumSpacing)).rounded(.down)
        let minimumTotalSpacing = minimumSpacing * (1 + numberOfColumns)
        let totalBoardWidth = min(maximumBoardWidth * numberOfColumns, availableWidth - minimumTotalSpacing)
        let columnWidth = totalBoardWidth / numberOfColumns
        let totalSpacing = availableWidth - totalBoardWidth
        let spacing = totalSpacing / (numberOfColumns + 1)
        return (Int(numberOfColumns), columnWidth, spacing)
    }
}
