//
//  BoardSelectorLayout.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-08-12.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

private let boardWidth: CGFloat = 180
private let textHeight: CGFloat = 32
private var boardHeight: CGFloat {
    return boardWidth + textHeight
}

private let spacing: CGFloat = 64
private var horizontalPadding: CGFloat {
    return spacing - boardWidth / 4
}

private var verticalPadding: CGFloat {
    return spacing - boardHeight / 4
}

class BoardSelectorLayout: UICollectionViewLayout {
    typealias BoardPosition = (row: Int, column: Int)

    var delegate: BoardSelectorLayoutDelegate?
    var positions: [BoardPosition]!
    var attributes: [UICollectionViewLayoutAttributes]!
    var contentsSize: CGSize!
    var selectedIndexPath: IndexPath!

    override var collectionViewContentSize: CGSize {
        return contentsSize
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return attributes.filter({ $0.frame.intersects(rect) })
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return attributes[indexPath.item]
    }

    override func prepare() {
        guard let collectionView = collectionView else { return }

        let numberOfItems = collectionView.numberOfItems(inSection: 0)

        let columns = Int(CGFloat(numberOfItems).squareRoot().rounded(.up))
        let rows: Int
        if columns * (columns - 1) >= numberOfItems {
            rows = columns - 1
        } else {
            rows = columns
        }

        let startRow = (rows - 1) / 2
        let startColumn = (columns - 1) / 2

        positions = [(0, 0)]

        (1..<numberOfItems).forEach { _ in
            positions.append(BoardSelectorLayout.getNextPosition(previousPosition: positions.last!))
        }

        positions = positions.map {
            ($0.row + startRow, $0.column + startColumn)
        }

        let effectiveBounds = collectionView.bounds.inset(by: collectionView.safeAreaInsets)
        let horizontalMargin = (effectiveBounds.width - boardWidth) / 2
        let verticalMargin = (effectiveBounds.height - boardHeight) / 2

        attributes = positions.enumerated().map { item, position in
            let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: item, section: 0))

            attributes.frame = BoardSelectorLayout.calculateFrame(for: position, horizontalMargin: horizontalMargin, verticalMargin: verticalMargin)

            let horizontalFalloff = abs(effectiveBounds.midX - attributes.frame.midX) / (boardWidth + horizontalPadding)
            let verticalFalloff = abs(effectiveBounds.midY - attributes.frame.midY) / (boardHeight + verticalPadding)
            let totalFalloff = (pow(horizontalFalloff, 2) + pow(verticalFalloff, 2)).squareRoot()
            let easedFalloff = BoardSelectorLayout.easingFunction(totalFalloff / 2)

            attributes.alpha = 1 - min(1, totalFalloff) * 0.5
            let scaleFactor = 1 - min(1, easedFalloff) * 0.5
            attributes.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)

            return attributes
        }

        contentsSize = BoardSelectorLayout.calculateContentSize(rows: rows, columns: columns, horizontalMargin: horizontalMargin, verticalMargin: verticalMargin)

        let selectedPosition = closestPosition(to: collectionView.contentOffset)
        if let selectedIndex = positions.firstIndex(where: { $0 == selectedPosition }) {
            selectedIndexPath = attributes[selectedIndex].indexPath
            delegate?.boardSelector(didSelectItemAt: selectedIndexPath)
        }
    }

    private static func getNextPosition(previousPosition: BoardPosition) -> BoardPosition {
        if previousPosition == (0, 0) {
            return (0, 1)
        }

        if previousPosition.row == previousPosition.column {
            if previousPosition.row < 0 {
                return (previousPosition.row, previousPosition.column + 1)
            } else {
                return (previousPosition.row, previousPosition.column - 1)
            }
        } else if previousPosition.row < previousPosition.column {
            if previousPosition.column > -previousPosition.row {
                return (previousPosition.row + 1, previousPosition.column)
            } else {
                return (previousPosition.row, previousPosition.column + 1)
            }
        } else {
            if previousPosition.column > -previousPosition.row {
                return (previousPosition.row, previousPosition.column - 1)
            } else {
                return (previousPosition.row - 1, previousPosition.column)
            }
        }
    }

    private static func calculateFrame(for position: BoardPosition, horizontalMargin: CGFloat, verticalMargin: CGFloat) -> CGRect {
        return CGRect(
            x: horizontalMargin + (boardWidth + horizontalPadding) * CGFloat(position.column),
            y: verticalMargin + (boardHeight + verticalPadding) * CGFloat(position.row),
            width: boardWidth,
            height: boardHeight
        )
    }

    private static func calculateContentSize(rows: Int, columns: Int, horizontalMargin: CGFloat, verticalMargin: CGFloat) -> CGSize {
        let lastFrame = calculateFrame(for: (rows - 1, columns - 1), horizontalMargin: horizontalMargin, verticalMargin: verticalMargin)

        return CGSize(
            width: lastFrame.maxX + horizontalMargin,
            height: lastFrame.maxY + verticalMargin
        )
    }

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        let proposedPosition = closestPosition(to: proposedContentOffset)
        let adjacentPosition: BoardPosition

        if abs(velocity.x) > abs(velocity.y) {
            // Scrolling left
            if velocity.x < 0 { adjacentPosition = (proposedPosition.row, proposedPosition.column + 1) }
            // Scrolling right
            else { adjacentPosition = (proposedPosition.row, proposedPosition.column - 1) }
        } else {
            // Scrolling up
            if velocity.y < 0 { adjacentPosition = (proposedPosition.row + 1, proposedPosition.column) }
            // Scrolling down
            else { adjacentPosition = (proposedPosition.row - 1, proposedPosition.column) }
        }

        if positions.contains(where: { $0 == proposedPosition }) {
            return calculateContentOffset(for: proposedPosition)
        } else if positions.contains(where: { $0 == adjacentPosition }) {
            return calculateContentOffset(for: adjacentPosition)
        } else {
            return calculateContentOffset(for: IndexPath(item: 0, section: 0))
        }
    }

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        // TODO: Select previously selected item
        return targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: .zero)
    }

    private func calculateContentOffset(for indexPath: IndexPath) -> CGPoint {
        let position = positions[indexPath.item]

        return calculateContentOffset(for: position)
    }

    private func calculateContentOffset(for position: BoardPosition) -> CGPoint {
        let boardOffset = CGPoint(
            x: (boardWidth + horizontalPadding) * CGFloat(position.column),
            y: (boardHeight + verticalPadding) * CGFloat(position.row)
        )

        let adjustedBoardOffset = CGPoint(
            x: boardOffset.x - collectionView!.safeAreaInsets.left,
            y: boardOffset.y - collectionView!.safeAreaInsets.top
        )

        return adjustedBoardOffset
    }

    private func closestPosition(to contentOffset: CGPoint) -> BoardPosition {
        let adjustedContentOffset = CGPoint(
            x: contentOffset.x + collectionView!.safeAreaInsets.left,
            y: contentOffset.y + collectionView!.safeAreaInsets.top
        )

        let column = Int(adjustedContentOffset.x / (boardWidth + horizontalPadding) + 0.5)
        let row = Int(adjustedContentOffset.y / (boardHeight + verticalPadding) + 0.5)

        return (row, column)
    }

    private static func easingFunction(_ x: CGFloat) -> CGFloat {
        if x < 0 { return 0 }
        if x > 1 { return 1 }

        return (1 + sin((x - 0.5) * .pi)) / 2
    }
}
