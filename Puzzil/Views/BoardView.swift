//
//  BoardView.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-28.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import UIKit

class BoardView: GradientView {
    private static let cornerRadius: CGFloat = 32
    private static let borderWidth: CGFloat = 8

    var delegate: BoardViewDelegate!
    var isDynamic = true
    private var tiles = [TileView: TileInfo]()
    private var rowGuides = [UILayoutGuide]()
    private var columnGuides = [UILayoutGuide]()

    init() {
        super.init(from: .themeForegroundPink, to: .themeForegroundOrange)

        isOpaque = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func clippingPath(for gradientBounds: CGRect) -> CGPath {
        if min(gradientBounds.width, gradientBounds.height) < 2 * BoardView.cornerRadius {
            return UIBezierPath(rect: gradientBounds).cgPath
        }

        let outer = UIBezierPath(roundedRect: gradientBounds, cornerRadius: BoardView.cornerRadius)
        let innerBounds = gradientBounds.insetBy(dx: BoardView.borderWidth, dy: BoardView.borderWidth)
        let innerRadius = BoardView.cornerRadius - BoardView.borderWidth
        let inner = UIBezierPath(roundedRect: innerBounds, cornerRadius: innerRadius)

        let shape = UIBezierPath()
        shape.append(inner)
        shape.append(outer)

        return shape.cgPath
    }

    @objc private func tileWasDragged(_ sender: UISwipeGestureRecognizer) {
        guard isDynamic else { return }

        let tile = sender.view as! TileView
        let position = tiles[tile]!.position
        let direction = TileMoveDirection(from: sender.direction)!
        let moveOperation = TileMoveOperation(position: position, direction: direction)

        perform(moveOperation, useFastTransition: false)
    }

    @objc private func tileWasTapped(_ sender: UITapGestureRecognizer) {
        guard isDynamic else { return }

        let tile = sender.view as! TileView
        let position = tiles[tile]!.position

        let validOperations = position.possibleOperations.filter { canPerform($0).result }
        let simpleOperations = validOperations.filter { canPerform($0).requiredOperations.count == 1 }

        if validOperations.count == 1 {
            perform(validOperations.first!, useFastTransition: true)
        } else if simpleOperations.count == 1 {
            perform(simpleOperations.first!, useFastTransition: true)
        }
    }

    private func perform(_ moveOperation: TileMoveOperation, useFastTransition: Bool) {
        let (operationIsPossible, requiredOperations) = canPerform(moveOperation)
        let dampingRatio: CGFloat = 0.75

        if operationIsPossible {
            for operation in requiredOperations {
                let tileToMove = tiles.first { $0.value.position == operation.position }!.key

                perform(operation, on: tileToMove)
                delegate.boardView(self, didPerform: operation)
            }

            let timer = CADisplayLink(target: self, selector: #selector(updateGradientUsingPresentationLayer))
            timer.add(to: .main, forMode: .defaultRunLoopMode)

            let animations = { self.layoutIfNeeded() }

            let completion: (Any) -> Void = { _ in
                timer.remove(from: .main, forMode: .defaultRunLoopMode)
            }

            let animationDuration = useFastTransition ? 0.1 : 0.25

            if #available(iOS 10.0, *) {
                let animator: UIViewPropertyAnimator = {
                    if useFastTransition {
                        return UIViewPropertyAnimator(duration: animationDuration, curve: .easeOut, animations: animations)
                    } else {
                        return UIViewPropertyAnimator(duration: animationDuration, dampingRatio: dampingRatio, animations: animations)
                    }
                }()
                animator.addCompletion(completion)
                animator.startAnimation()
            } else {
                if useFastTransition {
                    UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut, animations: animations, completion: completion)
                } else {
                    UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: dampingRatio, initialSpringVelocity: 1, options: UIViewAnimationOptions(rawValue: 0), animations: animations, completion: completion)
                }
            }
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
        tiles.forEach { (tileView, info) in
            tileView.removeFromSuperview()
            NSLayoutConstraint.deactivate(info.constraints)
        }
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

        tile.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tileWasTapped(_:))))
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

    private func perform(_ moveOperation: TileMoveOperation, on tile: TileView) {
        remove(tile)
        place(tile, at: moveOperation.targetPosition)
    }

    @objc private func updateGradientUsingPresentationLayer() {
        updateGradient(usingPresentationLayer: true)
    }

    override func updateGradient(usingPresentationLayer usePresentationLayer: Bool) {
        super.updateGradient(usingPresentationLayer: usePresentationLayer)

        tiles.keys.forEach { $0.updateGradient(usingPresentationLayer: usePresentationLayer) }
    }
}

fileprivate struct TileInfo {
    let position: TilePosition
    let constraints: [NSLayoutConstraint]
}
