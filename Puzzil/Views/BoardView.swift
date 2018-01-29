//
//  BoardView.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-28.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import UIKit

class BoardView: UIView {

    override var isOpaque: Bool { get { return false } set { } }
    private static let cornerRadius: CGFloat = 32
    private static let borderWidth: CGFloat = 8

    var delegate: BoardViewDelegate!
    var isDynamic = true {
        didSet {
            updateTileDynamics()
        }
    }
    private var tiles = [TileView: TileInfo]()
    private var rowGuides = [UILayoutGuide]()
    private var columnGuides = [UILayoutGuide]()

    init() {
        super.init(frame: .zero)

        backgroundColor = .themeBoard
        layer.cornerRadius = BoardView.cornerRadius
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateTileDynamics() {
        if isDynamic {
            for (tileView, tileInfo) in tiles {
                let position = tileInfo.position
                tileView.text = delegate.boardView(self, tileTextAt: position)!
                tileView.isUserInteractionEnabled = true
            }
        } else {
            for tileView in tiles.keys {
                tileView.text = ""
                tileView.isUserInteractionEnabled = false
            }
        }
    }

    @objc private func tileWasDragged(_ sender: UISwipeGestureRecognizer) {
        let tile = sender.view as! TileView
        let position = tiles[tile]!.position
        let direction = TileMoveDirection(from: sender.direction)!
        let moveOperation = TileMoveOperation(moving: direction, from: position)

        perform(moveOperation, useFastTransition: false)
    }

    @objc private func tileWasTapped(_ sender: UITapGestureRecognizer) {
        let tile = sender.view as! TileView
        let position = tiles[tile]!.position

        let validOperations = position.possibleOperations.filter { canPerform($0).result }
        let simpleOperations = validOperations.filter { canPerform($0).requiredOperations.count == 1 }

        if validOperations.count == 1 {
            perform(validOperations.first!, useFastTransition: true)
        } else if simpleOperations.count == 1 {
            perform(simpleOperations.first!, useFastTransition: true)
        } else {
            bounce(tile)
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

            let animations = { self.layoutIfNeeded() }

            let animationDuration = useFastTransition ? 0.1 : 0.25

            if #available(iOS 10.0, *) {
                let animator: UIViewPropertyAnimator = {
                    if useFastTransition {
                        return UIViewPropertyAnimator(duration: animationDuration, curve: .easeOut, animations: animations)
                    } else {
                        return UIViewPropertyAnimator(duration: animationDuration, dampingRatio: dampingRatio, animations: animations)
                    }
                }()
                animator.startAnimation()
            } else {
                if useFastTransition {
                    UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut, animations: animations, completion: nil)
                } else {
                    UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: dampingRatio, initialSpringVelocity: 1, options: UIViewAnimationOptions(rawValue: 0), animations: animations, completion: nil)
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
        updateTileDynamics()
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

    private func bounce(_ tile: TileView) {
        let initialAnimationDuration = 0.1
        let finalAnimationDuration = 0.5
        let initialDampingRatio: CGFloat = 1
        let finalDampingRatio: CGFloat = 0.5
        let initialAnimations = {
            tile.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
        let finalAnimations = {
            tile.transform = .identity
        }

        let completion: (Any) -> Void = {
            if #available(iOS 10.0, *) {
                return { _ in
                    UIViewPropertyAnimator(duration: finalAnimationDuration, dampingRatio: finalDampingRatio, animations: finalAnimations).startAnimation()
                }
            } else {
                return { _ in
                    UIView.animate(withDuration: finalAnimationDuration, delay: 0, usingSpringWithDamping: finalDampingRatio, initialSpringVelocity: 1, options: .init(rawValue: 0), animations: finalAnimations, completion: nil)
                }
            }
        }()

        if #available(iOS 10.0, *) {
            let animator: UIViewPropertyAnimator
            animator = UIViewPropertyAnimator(duration: initialAnimationDuration, dampingRatio: initialDampingRatio, animations: initialAnimations)
            animator.addCompletion(completion)
            animator.startAnimation()
        } else {
            UIView.animate(withDuration: initialAnimationDuration, delay: 0, usingSpringWithDamping: initialDampingRatio, initialSpringVelocity: 1, options: .init(rawValue: 0), animations: initialAnimations, completion: completion)
        }
    }

    private func perform(_ moveOperation: TileMoveOperation, on tile: TileView) {
        remove(tile)
        place(tile, at: moveOperation.targetPosition)
    }
}

fileprivate struct TileInfo {
    let position: TilePosition
    let constraints: [NSLayoutConstraint]
}
