//
//  BoardView.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-28.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import UIKit

class BoardView: GradientView {
    static let cornerRadius: CGFloat = 32
    static let borderWidth: CGFloat = 8

    var tilePositions = [TileView: TilePosition]()
    var tileConstraints = [TileView: [NSLayoutConstraint]]()
    var rowGuides = [UILayoutGuide]()
    var columnGuides = [UILayoutGuide]()
    var delegate: BoardViewDelegate!

    init() {
        super.init(from: .themeForegroundPink, to: .themeForegroundOrange)

        isOpaque = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func clippingPath(for gradientBounds: CGRect) -> CGPath {
        let outer = UIBezierPath(roundedRect: gradientBounds, cornerRadius: BoardView.cornerRadius)
        let innerBounds = gradientBounds.insetBy(dx: BoardView.borderWidth, dy: BoardView.borderWidth)
        let innerRadius = BoardView.cornerRadius - BoardView.borderWidth
        let inner = UIBezierPath(roundedRect: innerBounds, cornerRadius: innerRadius)

        let shape = UIBezierPath()
        shape.append(inner)
        shape.append(outer)

        return shape.cgPath
    }

    private func setupGestureRecognizer() {
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(tileWasDragged(_:))))
    }

    @objc private func tileWasDragged(_ sender: UISwipeGestureRecognizer) {
        let tile = sender.view as! TileView
        let position = tilePositions[tile]!
        let direction = TileMoveDirection(from: sender.direction)!
        let moveOperation = TileMoveOperation(position: position, direction: direction)

        perform(moveOperation)
    }

    @objc private func tileWasTapped(_ sender: UITapGestureRecognizer) {
        let tile = sender.view as! TileView
        let position = tilePositions[tile]!

        let validOperations = position.possibleOperations.filter { canPerform($0).result }

        if validOperations.count == 1 {
            perform(validOperations.first!)
        }
    }

    private func perform(_ moveOperation: TileMoveOperation) {
        let (operationIsPossible, requiredOperations) = canPerform(moveOperation)

        if operationIsPossible {
            var gradientTimers = [CADisplayLink]()

            for operation in requiredOperations {
                let tileToMove = tilePositions.keys.first { tilePositions[$0] == operation.position }!

                perform(operation, on: tileToMove)
                delegate.boardView(self, didPerform: operation)

                let timer = CADisplayLink(target: tileToMove, selector: #selector(tileToMove.updateGradient))
                timer.add(to: .main, forMode: .defaultRunLoopMode)
                gradientTimers.append(timer)
            }

            if #available(iOS 10.0, *) {
                let animator = UIViewPropertyAnimator(duration: 0.25, dampingRatio: 1) {
                    self.layoutIfNeeded()
                }

                animator.addCompletion { _ in
                    gradientTimers.forEach { $0.remove(from: .main, forMode: .defaultRunLoopMode) }
                }

                animator.startAnimation()
            } else {
                UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: UIViewAnimationOptions(rawValue: 0), animations: {
                    self.layoutIfNeeded()
                }, completion: nil)
            }
        }
    }

    private func canPerform(_ moveOperation: TileMoveOperation) -> (result: Bool, requiredOperations: [TileMoveOperation]) {
        guard let operationIsPossible = delegate.boardView(self, canPerform: moveOperation) else {
            return (false, [moveOperation])
        }

        if operationIsPossible {
            return (true, [moveOperation])
        }

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
        tilePositions.keys.forEach { $0.removeFromSuperview() }
        tilePositions.removeAll()

        NSLayoutConstraint.deactivate(tileConstraints.values.flatMap { $0 })
        tileConstraints.removeAll()

        rowGuides.forEach(removeLayoutGuide(_:))
        rowGuides.removeAll()

        columnGuides.forEach(removeLayoutGuide(_:))
        columnGuides.removeAll()
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

            place(tile, at: position)
        }
    }

    private func addTileSwipeRecognizers(to tile: TileView) {
        let leftSwipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(tileWasDragged(_:)))
        leftSwipeRecognizer.direction = .left
        tile.addGestureRecognizer(leftSwipeRecognizer)

        let rightSwipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(tileWasDragged(_:)))
        rightSwipeRecognizer.direction = .right
        tile.addGestureRecognizer(rightSwipeRecognizer)

        let upSwipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(tileWasDragged(_:)))
        upSwipeRecognizer.direction = .up
        tile.addGestureRecognizer(upSwipeRecognizer)

        let downSwipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(tileWasDragged(_:)))
        downSwipeRecognizer.direction = .down
        tile.addGestureRecognizer(downSwipeRecognizer)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tileWasTapped(_:)))
        tile.addGestureRecognizer(tapRecognizer)
    }

    private func remove(_ tile: TileView) {
        let constraints = tileConstraints[tile]!

        NSLayoutConstraint.deactivate(constraints)

        tilePositions.removeValue(forKey: tile)
        tileConstraints.removeValue(forKey: tile)
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

        tilePositions[tile] = position
        tileConstraints[tile] = constraints
    }

    private func perform(_ moveOperation: TileMoveOperation, on tile: TileView) {
        remove(tile)
        place(tile, at: moveOperation.targetPosition)
    }
}
