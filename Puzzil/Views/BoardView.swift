//
//  BoardView.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-28.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import UIKit

class BoardView: UIView {

    // MARK: - Dimension Constants

    private static let maxTileSize: CGFloat = 96
    private static let cornerRadius: CGFloat = 32
    private static let borderWidth: CGFloat = 8

    // MARK: - Board Properties

    private(set) var board: Board!
    var isDynamic = true

    weak var delegate: BoardViewDelegate!
    private var tiles = [TileView: TileInfo]()
    private var tileGuides = [[UILayoutGuide]]()

    // MARK: - Drag Operation Coordination

    private var _currentDrags = [TileView: Any]()
    @available(iOS 10, *)
    private var dragOperations: [TileView: TileDragOperation] {
        get {
            return _currentDrags as! [TileView: TileDragOperation]
        }

        set {
            _currentDrags = newValue
        }
    }

    // MARK: - Move Operation Coordination

    private var reservedPositions = Set<TilePosition>()

    // MARK: - Constructors

    init() {
        super.init(frame: .zero)

        isOpaque = false
        backgroundColor = .themeBoard
        layer.cornerRadius = BoardView.cornerRadius
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Helpers

    private func tile(at position: TilePosition) -> TileView {
        return tiles.first { $0.value.position == position }!.key
    }

    // MARK: - Event Handlers

    @objc private func tileWasTapped(_ sender: UITapGestureRecognizer) {
        let tile = sender.view as! TileView
        let position = tiles[tile]!.position
        var validOperations = [TileMoveOperation]()
        var simpleOperations = [TileMoveOperation]()

        for moveOperation in position.possibleOperations {
            switch board.canPerform(moveOperation) {
            case let .possible(after: requiredOperations):
                validOperations.append(moveOperation)
                if requiredOperations.count == 1 {
                    simpleOperations.append(moveOperation)
                }
            case .notPossible:
                break
            }
        }

        if validOperations.count == 1 {
            animate(validOperations.first!)
        } else if simpleOperations.count == 1 {
            animate(simpleOperations.first!)
        }
    }

    @objc private func tileWasDragged(_ sender: UIPanGestureRecognizer) {
        let tileView = sender.view as! TileView

        switch sender.state {
        case .began:
            let velocity = sender.velocity(in: self)
            let direction: TileMoveDirection
            let position = tiles[tileView]!.position
            if abs(velocity.x) > abs(velocity.y) {
                if velocity.x < 0 { direction = .left }
                else { direction = .right }
            } else {
                if velocity.y < 0 { direction = .up }
                else { direction = .down }
            }

            let moveOperation = TileMoveOperation(position: position, direction: direction)

            if #available(iOS 10, *) {
                beginAnimation(for: moveOperation)
            } else {
                animate(moveOperation)
            }
        case .changed:
            if #available(iOS 10, *) {
                updateAnimation(for: tileView, sender: sender)
            }
        default:
            if #available(iOS 10, *) {
                completeAnimation(for: tileView, sender: sender)
            }
        }
    }

    @objc private func tileWasPressed(_ sender: UILongPressGestureRecognizer) {
        let tileView = sender.view as! TileView

        switch sender.state {
        case .began:
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0,
                           options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                               tileView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            })
        case .ended, .cancelled:
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0,
                           options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                               tileView.transform = .identity
            })
        default:
            break
        }
    }

    // MARK: - Tile Animations

    private func animate(_ moveOperation: TileMoveOperation) {
        guard case let .possible(after: operations) = board.canPerform(moveOperation) else { return }

        for operation in operations + [moveOperation] {
            perform(operation)
        }

        board.perform(moveOperation)
        delegate.boardDidChange(self)

        UIView.animate(withDuration: 0.125, delay: 0, options: .curveEaseOut, animations: {
            self.layoutIfNeeded()
        })
    }

    // MARK: - Tile Layout

    func reloadBoard() {
        board = delegate.newBoard(for: self)

        clearBoard()
        generateLayoutGuides()
        layoutTiles()
    }

    private func clearBoard() {
        tiles.keys.forEach { $0.removeFromSuperview() }
        tiles.removeAll()

        tileGuides.forEach { $0.forEach(removeLayoutGuide(_:)) }
        tileGuides.removeAll()
    }

    // MARK: Layout Guide Generation

    private func generateLayoutGuides() {
        // Generate column guides
        var lastColumnAnchor = leftAnchor
        let columnGuides: [UILayoutGuide] = (0..<board.columnCount).map { columnIndex in
            let columnGuide = UILayoutGuide()
            addLayoutGuide(columnGuide)

            columnGuide.leftAnchor.constraint(equalTo: lastColumnAnchor, constant: columnIndex == 0 ? 16 : 8).isActive = true
            lastColumnAnchor = columnGuide.rightAnchor

            return columnGuide
        }

        rightAnchor.constraint(equalTo: lastColumnAnchor, constant: 16).isActive = true

        // Generate row guides
        var lastRowAnchor = topAnchor
        let rowGuides: [UILayoutGuide] = (0..<board.rowCount).map { rowIndex in
            let rowGuide = UILayoutGuide()
            addLayoutGuide(rowGuide)

            rowGuide.topAnchor.constraint(equalTo: lastRowAnchor, constant: rowIndex == 0 ? 16 : 8).isActive = true
            lastRowAnchor = rowGuide.bottomAnchor

            return rowGuide
        }

        bottomAnchor.constraint(equalTo: lastRowAnchor, constant: 16).isActive = true

        // Generate tile guides

        tileGuides = rowGuides.map { rowGuide in
            columnGuides.map { columnGuide in
                let tileGuide = UILayoutGuide()
                addLayoutGuide(tileGuide)
                NSLayoutConstraint.activate([
                    tileGuide.leftAnchor.constraint(equalTo: columnGuide.leftAnchor),
                    tileGuide.rightAnchor.constraint(equalTo: columnGuide.rightAnchor),
                    tileGuide.topAnchor.constraint(equalTo: rowGuide.topAnchor),
                    tileGuide.bottomAnchor.constraint(equalTo: rowGuide.bottomAnchor),

                    tileGuide.widthAnchor.constraint(lessThanOrEqualToConstant: BoardView.maxTileSize),
                    tileGuide.heightAnchor.constraint(lessThanOrEqualToConstant: BoardView.maxTileSize),
                    tileGuide.widthAnchor.constraint(equalTo: tileGuide.heightAnchor),
                ])

                return tileGuide
            }
        }
    }

    // MARK: Tile Creation

    private func layoutTiles() {
        for position in TilePosition.traversePositions(rows: board.rowCount, columns: board.columnCount) {
            guard let text = board.tileText(at: position) else { continue }

            let tileView = TileView()
            tileView.translatesAutoresizingMaskIntoConstraints = false
            tileView.text = text

            if isDynamic {
                let pressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(tileWasPressed(_:)))
                pressGestureRecognizer.minimumPressDuration = 0
                pressGestureRecognizer.delegate = self
                tileView.addGestureRecognizer(pressGestureRecognizer)
                tileView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tileWasTapped(_:))))
                tileView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(tileWasDragged(_:))))
            }

            addSubview(tileView)
            place(tileView, at: position)
        }
    }

    // MARK: Tile Placement

    private func remove(_ tile: TileView) {
        let constraints = tiles[tile]!.constraints

        NSLayoutConstraint.deactivate(constraints)

        tiles.removeValue(forKey: tile)
    }

    private func place(_ tileView: TileView, at position: TilePosition) {
        let tileGuide = tileGuides[position.row][position.column]

        let constraints = [
            tileView.leftAnchor.constraint(equalTo: tileGuide.leftAnchor),
            tileView.rightAnchor.constraint(equalTo: tileGuide.rightAnchor),
            tileView.topAnchor.constraint(equalTo: tileGuide.topAnchor),
            tileView.bottomAnchor.constraint(equalTo: tileGuide.bottomAnchor),
        ]

        NSLayoutConstraint.activate(constraints)

        tiles[tileView] = TileInfo(position: position, constraints: constraints)
    }

    private func perform(_ moveOperation: TileMoveOperation) {
        let tileView = tile(at: moveOperation.startPosition)
        remove(tileView)
        place(tileView, at: moveOperation.targetPosition)
    }
}

// MARK: - Interactive Drag Support

@available(iOS 10, *)
extension BoardView {
    private func beginAnimation(for moveOperation: TileMoveOperation) {
        let tileView = tile(at: moveOperation.startPosition)
        guard case let .possible(after: operations) = board.canPerform(moveOperation),
            dragOperations[tileView] == nil
        else { return }

        (operations + [moveOperation]).forEach(perform)
        board.begin(moveOperation)

        let animator = UIViewPropertyAnimator(duration: 0.25, dampingRatio: 1) {
            self.layoutIfNeeded()
        }

        let originalFrame = tileView.frame
        animator.pauseAnimation()
        let targetFrame = tileView.frame
        let dragOperation = TileDragOperation(direction: moveOperation.direction, originalFrame: originalFrame,
                                              targetFrame: targetFrame, animator: animator,
                                              keyMoveOperation: moveOperation,
                                              moveOperations: operations)

        dragOperations[tileView] = dragOperation
    }

    private func updateAnimation(for tileView: TileView, sender: UIPanGestureRecognizer) {
        guard let dragOperation = dragOperations[tileView] else { return }

        let translation = sender.translation(in: self)
        let fractionComplete = dragOperation.fractionComplete(with: translation)
        if fractionComplete < 1 {
            dragOperation.animator.fractionComplete = fractionComplete
        } else {
            board.complete(dragOperation.keyMoveOperation)
            delegate.boardDidChange(self)
            sender.setTranslation(.zero, in: self)
            dragOperation.animator.stopAnimation(false)
            dragOperation.animator.finishAnimation(at: .end)
            dragOperations[tileView] = nil
            beginAnimation(for: dragOperation.keyMoveOperation.nextOperation)
        }
    }

    private func completeAnimation(for tileView: TileView, sender: UIPanGestureRecognizer) {
        guard let dragOperation = dragOperations[tileView] else { return }

        let velocity = sender.velocity(in: self)
        let animator = dragOperation.animator
        let velocityAdjustment = dragOperation.fractionComplete(with: velocity)
        let moveShouldBeCancelled = animator.fractionComplete + velocityAdjustment < 0.5

        if moveShouldBeCancelled {
            animator.isReversed = true
            dragOperation.allMoveOperations.map { $0.reversed }.forEach(perform)
            board.cancel(dragOperation.keyMoveOperation)
        } else {
            board.complete(dragOperation.keyMoveOperation)
            delegate.boardDidChange(self)
        }

        let timingParameters = UISpringTimingParameters(dampingRatio: 1,
                                                        initialVelocity: CGVector(dx: velocityAdjustment, dy: 0))
        animator.continueAnimation(withTimingParameters: timingParameters, durationFactor: 1)
        dragOperations[tileView] = nil
    }
}

// MARK: - UIGestureRecognizerDelegate

extension BoardView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer is UILongPressGestureRecognizer
    }
}

fileprivate struct TileInfo {
    let position: TilePosition
    let constraints: [NSLayoutConstraint]
}
