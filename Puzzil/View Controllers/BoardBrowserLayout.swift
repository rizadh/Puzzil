//
//  BoardBrowserLayout.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-08-09.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

private let minimumBoardWidth: CGFloat = 120
private let maximumBoardWidth: CGFloat = 160
private let minimumSpacing: CGFloat = 16

class BoardBrowserLayout: UICollectionViewLayout {
    var selectedIndexPath: IndexPath?

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

    var effectiveBounds: CGRect {
        return collectionView!.bounds.inset(by: collectionView!.safeAreaInsets)
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
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

        (numberOfColumns, boardWidth, horizontalSpacing) = calculateLayoutDimensions(availableWidth: effectiveBounds.width)
        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        if selectedIndexPath != nil {
            contentsSize = effectiveBounds.size
            attributes = (0..<numberOfItems).map {
                generateSelectedLayoutAttributes(for: IndexPath(item: $0, section: 0))
            }
        } else {
            contentsSize = calculateContentSize(numberOfItems: numberOfItems)
            attributes = (0..<numberOfItems).map {
                generateLayoutAttributes(for: IndexPath(item: $0, section: 0))
            }
        }
    }

    private func calculateLayoutDimensions(availableWidth: CGFloat) -> (numberOfColumns: Int, columnWidth: CGFloat, spacing: CGFloat) {
        let numberOfColumns = ((availableWidth - minimumSpacing) / (minimumBoardWidth + minimumSpacing)).rounded(.down)
        let minimumTotalSpacing = minimumSpacing * (1 + numberOfColumns)
        let totalBoardWidth = min(maximumBoardWidth * numberOfColumns, availableWidth - minimumTotalSpacing)
        let columnWidth = totalBoardWidth / numberOfColumns
        let totalSpacing = availableWidth - totalBoardWidth
        let spacing = totalSpacing / (numberOfColumns + 1)
        return (Int(numberOfColumns), columnWidth, spacing)
    }

    private func calculateContentSize(numberOfItems: Int) -> CGSize {
        let numberOfRows = Int((CGFloat(numberOfItems) / CGFloat(numberOfColumns)).rounded(.up))
        let bottomRightItem = numberOfRows * numberOfColumns - 1
        let outermostFrame = calculateFrame(for: bottomRightItem)
        let x = outermostFrame.maxX + horizontalSpacing
        let y = outermostFrame.maxY + verticalSpacing
        let contentsSize = CGSize(width: x, height: y)

        return contentsSize
    }

    private func calculateFrame(for item: Int) -> CGRect {
        let row = item / numberOfColumns
        let column = item % numberOfColumns

        let x = horizontalSpacing + (horizontalSpacing + boardWidth) * CGFloat(column)
        let y = horizontalSpacing + (verticalSpacing + boardHeight) * CGFloat(row)

        return CGRect(x: x, y: y, width: boardWidth, height: boardHeight)
    }

    private func generateLayoutAttributes(for indexPath: IndexPath) -> UICollectionViewLayoutAttributes {
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

        let frame = calculateFrame(for: indexPath.item)
        let progress = calculateTransitionProgress(for: frame, in: effectiveBounds)

        attributes.frame = frame
        attributes.alpha = 1 - abs(progress)
        attributes.transform = generateTransform(for: progress)

        return attributes
    }

    private func generateTransform(for progress: CGFloat) -> CGAffineTransform {
        let maxRotationAngle: CGFloat = .pi / 2
        let rotationAngle = maxRotationAngle * progress
        let scaleFactor = cos(rotationAngle)
        let requiredTranslation = (progress < 0 ? -1 : 1) * boardHeight / 2 * (1 - scaleFactor)
        let transform = CGAffineTransform(translationX: 0, y: requiredTranslation).scaledBy(x: 1, y: scaleFactor)

        return transform
    }

    private func calculateTransitionProgress(for frame: CGRect, in bounds: CGRect) -> CGFloat {
        let transitionDistance = boardHeight + verticalSpacing

        let upperOffset = bounds.minY - frame.minY + verticalSpacing
        let clippedUpperOffset = max(0, min(transitionDistance, upperOffset))

        let lowerOffset = bounds.maxY - frame.maxY - verticalSpacing
        let clippedLowerOffset = max(-transitionDistance, min(0, lowerOffset))

        let rawTransitionProgress = (clippedUpperOffset + clippedLowerOffset) / transitionDistance
        let transitionProgress = 2 * asin(rawTransitionProgress) / .pi

        return transitionProgress
    }

    private func generateSelectedLayoutAttributes(for indexPath: IndexPath) -> UICollectionViewLayoutAttributes {
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

        let selectedFrame = calculateSelectedFrame()
        let originalSelectedFrame = calculateFrame(for: selectedIndexPath!.item)
        let translation = CGPoint(x: selectedFrame.center.x - originalSelectedFrame.center.x, y: selectedFrame.center.y - originalSelectedFrame.center.y)

        if indexPath == selectedIndexPath {
            attributes.frame = selectedFrame
            attributes.alpha = 1
            let scaleFactor: CGFloat = 1.1
            attributes.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        } else {
            attributes.frame = calculateFrame(for: indexPath.item)
            attributes.alpha = 0.5
            let scaleFactor: CGFloat = 0.9
            attributes.transform = CGAffineTransform(translationX: translation.x, y: translation.y).scaledBy(x: scaleFactor, y: scaleFactor)
        }

        return attributes
    }

    private func calculateSelectedFrame() -> CGRect {
        let center = CGPoint(x: contentsSize.width / 2, y: contentsSize.height / 2)
        let size = CGSize(width: boardWidth, height: boardHeight)

        return CGRect(center: center, size: size)
    }
}
