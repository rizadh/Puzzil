//
//  BoardView.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-28.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import UIKit

class BoardView: UIView {
    override var isOpaque: Bool { get { return false } set {} }

    private static let maxTileSize: CGFloat = 96
    private static let cornerRadius: CGFloat = 32
    private static let borderWidth: CGFloat = 8

    weak var delegate: BoardViewDelegate!
    private var tiles = [TileView: TileInfo]()
    private var rowGuides = [UILayoutGuide]()
    private var columnGuides = [UILayoutGuide]()

    private var currentDrags = [TileView: TileDragOperation]()

    init() {
        super.init(frame: .zero)

        backgroundColor = .themeBoard
        layer.cornerRadius = BoardView.cornerRadius
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func tileWasTapped(_ sender: UITapGestureRecognizer) {
        let tile = sender.view as! TileView
        let position = tiles[tile]!.position

        let validOperations = position.possibleOperations.filter { canPerform($0).result }
        let simpleOperations = validOperations.filter { canPerform($0).requiredOperations.count == 1 }

        if validOperations.count == 1 {
            animate(validOperations.first!)
        } else if simpleOperations.count == 1 {
            animate(simpleOperations.first!)
        }
    }

    @objc private func tileWasDragged(_ sender: UIPanGestureRecognizer) {
        let tileView = sender.view as! TileView
        let translation = sender.translation(in: self)
        let velocity = sender.velocity(in: self)

        switch sender.state {
        case .began:
            if currentDrags[tileView] != nil { break }

            let direction: TileMoveDirection
            let position = tiles[tileView]!.position
            if abs(velocity.x) > abs(velocity.y) {
                if velocity.x < 0 {
                    direction = .left
                } else {
                    direction = .right
                }
            } else {
                if velocity.y < 0 {
                    direction = .up
                } else {
                    direction = .down
                }
            }

            let moveOperation = TileMoveOperation(moving: direction, from: position)

            let (operationIsPossible, requiredOperations) = canPerform(moveOperation)
            guard operationIsPossible else { break }

            requiredOperations.forEach(perform)

            let animator = UIViewPropertyAnimator(duration: 0.25, dampingRatio: 1) {
                self.layoutIfNeeded()
            }

            delegate.boardView(self, didStart: requiredOperations.first!)

            animator.addCompletion { _ in
                self.currentDrags[tileView] = nil
                sender.isEnabled = true
            }

            let originalFrame = tileView.frame
            animator.pauseAnimation()
            let targetFrame = tileView.frame
            let dragOperation = TileDragOperation(direction: direction, originalFrame: originalFrame, targetFrame: targetFrame, animator: animator, requiredMoveOperations: requiredOperations)

            currentDrags[tileView] = dragOperation
        case .changed:
            guard let dragOperation = currentDrags[tileView] else { break }

            let fractionComplete = dragOperation.fractionComplete(with: translation)
            dragOperation.animator.fractionComplete = fractionComplete
        default:
            guard let dragOperation = currentDrags[tileView] else { break }

            let animator = dragOperation.animator
            let velocityAdjustment = dragOperation.fractionComplete(with: velocity)

            if animator.fractionComplete + velocityAdjustment < 0.5 {
                animator.isReversed = true
                dragOperation.requiredMoveOperations.map { $0.reversed }.forEach(perform)
                delegate.boardView(self, didCancel: dragOperation.requiredMoveOperations.first!)
            } else {
                delegate.boardView(self, didComplete: dragOperation.requiredMoveOperations.first!)
                dragOperation.requiredMoveOperations.dropFirst().forEach { self.delegate.boardView(self, didPerform: $0) }
            }

            let timingParameters = UISpringTimingParameters(dampingRatio: 1, initialVelocity: CGVector(dx: velocityAdjustment, dy: 0))
            animator.continueAnimation(withTimingParameters: timingParameters, durationFactor: 1)

            sender.isEnabled = false
        }
    }

    private func tile(at position: TilePosition) -> TileView {
        return tiles.first { $0.value.position == position }!.key
    }

    private func animate(_ moveOperation: TileMoveOperation) {
        let (operationIsPossible, requiredOperations) = canPerform(moveOperation)

        if operationIsPossible {
            requiredOperations.forEach {
                perform($0)
                delegate.boardView(self, didPerform: $0)
            }

            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut, animations: {
                self.layoutIfNeeded()
            }, completion: nil)
        }
    }

    private func canPerform(_ moveOperation: TileMoveOperation) -> (result: Bool, requiredOperations: [TileMoveOperation]) {
        guard let operationIsPossible = delegate.boardView(self, canPerform: moveOperation) else {
            return (false, [moveOperation])
        }

        if operationIsPossible { return (true, [moveOperation]) }

        let nextOperationIsPossible = canPerform(moveOperation.nextOperation)

        if nextOperationIsPossible.result {
            return (true, nextOperationIsPossible.requiredOperations + [moveOperation])
        }

        return (false, [moveOperation])
    }

    func reloadTiles() {
        clearTiles()
        generateColumnLayoutGuides()
        generateRowLayoutGuides()
        layoutTiles()
    }

    private func clearTiles() {
        tiles.keys.forEach { $0.removeFromSuperview() }
        tiles.removeAll()

        rowGuides.forEach(removeLayoutGuide(_:))
        rowGuides.removeAll()

        columnGuides.forEach(removeLayoutGuide(_:))
        columnGuides.removeAll()
    }

    private func generateColumnLayoutGuides() {
        var lastAnchor = leftAnchor

        for columnIndex in 0..<delegate.numberOfColumns(in: self) {
            let columnGuide = UILayoutGuide()
            columnGuides.append(columnGuide)
            addLayoutGuide(columnGuide)

            columnGuide.leftAnchor.constraint(equalTo: lastAnchor, constant: columnIndex == 0 ? 16 : 8).isActive = true
            lastAnchor = columnGuide.rightAnchor
        }

        rightAnchor.constraint(equalTo: lastAnchor, constant: 16).isActive = true
    }

    private func generateRowLayoutGuides() {
        var lastAnchor = topAnchor

        for rowIndex in 0..<delegate.numberOfRows(in: self) {
            let rowGuide = UILayoutGuide()
            rowGuides.append(rowGuide)
            addLayoutGuide(rowGuide)

            rowGuide.topAnchor.constraint(equalTo: lastAnchor, constant: rowIndex == 0 ? 16 : 8).isActive = true
            lastAnchor = rowGuide.bottomAnchor
        }

        bottomAnchor.constraint(equalTo: lastAnchor, constant: 16).isActive = true
    }

    private func layoutTiles() {
        let columns = delegate.numberOfColumns(in: self)
        let rows = delegate.numberOfRows(in: self)

        for position in TilePosition.traversePositions(rows: rows, columns: columns) {
            guard let text = delegate.boardView(self, tileTextAt: position) else { continue }

            let tile = TileView()
            tile.translatesAutoresizingMaskIntoConstraints = false
            tile.text = text

            addTileSwipeRecognizers(to: tile)
            addSubview(tile)

            NSLayoutConstraint.activate([
                tile.widthAnchor.constraint(lessThanOrEqualToConstant: BoardView.maxTileSize),
                tile.heightAnchor.constraint(lessThanOrEqualToConstant: BoardView.maxTileSize),
                tile.widthAnchor.constraint(equalTo: tile.heightAnchor),
            ])

            place(tile, at: position)
        }
    }

    private func addTileSwipeRecognizers(to tile: TileView) {
        tile.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tileWasTapped(_:))))
        tile.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(tileWasDragged(_:))))
    }

    private func remove(_ tile: TileView) {
        let constraints = tiles[tile]!.constraints

        NSLayoutConstraint.deactivate(constraints)

        tiles.removeValue(forKey: tile)
    }

    private func place(_ tile: TileView, at position: TilePosition) {
        let rowGuide = rowGuides[position.row]
        let columnGuide = columnGuides[position.column]

        let constraints = [
            tile.leftAnchor.constraint(equalTo: columnGuide.leftAnchor),
            tile.rightAnchor.constraint(equalTo: columnGuide.rightAnchor),
            tile.topAnchor.constraint(equalTo: rowGuide.topAnchor),
            tile.bottomAnchor.constraint(equalTo: rowGuide.bottomAnchor),
        ]

        NSLayoutConstraint.activate(constraints)

        tiles[tile] = TileInfo(position: position, constraints: constraints)
    }

    private func perform(_ moveOperation: TileMoveOperation) {
        let tileView = tile(at: moveOperation.position)
        remove(tileView)
        place(tileView, at: moveOperation.targetPosition)
    }
}

fileprivate struct TileInfo {
    let position: TilePosition
    let constraints: [NSLayoutConstraint]
}

struct TileDragOperation {
    let direction: TileMoveDirection
    let originalFrame: CGRect
    let targetFrame: CGRect
    let animator: UIViewPropertyAnimator
    let requiredMoveOperations: [TileMoveOperation]

    var distance: CGFloat {
        switch direction {
        case .left, .right:
            return targetFrame.midX - originalFrame.midX
        case .up, .down:
            return targetFrame.midY - originalFrame.midY
        }
    }

    func fractionComplete(with translation: CGPoint) -> CGFloat {
        switch direction {
        case .left, .right:
            return translation.x / distance
        case .up, .down:
            return translation.y / distance
        }
    }
}
