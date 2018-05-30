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

    private var _currentDrags = [UIPanGestureRecognizer: Any]()
    @available(iOS 10, *)
    private var dragOperations: [UIPanGestureRecognizer: TileDragOperation] {
        get {
            return _currentDrags as! [UIPanGestureRecognizer: TileDragOperation]
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

    @objc private func tileWasSwiped(_ sender: UISwipeGestureRecognizer) {
        let tileView = sender.view as! TileView
        let position = tiles[tileView]!.position
        let direction: TileMoveDirection = {
            switch sender.direction {
            case .left:
                return .left
            case .right:
                return .right
            case .up:
                return .up
            case .down:
                return .down
            default:
                fatalError("Invalid swipe direction.")
            }
        }()

        let moveOperation = TileMoveOperation(position: position, direction: direction)

        animate(moveOperation)
    }

    @available(iOS 10, *)
    @objc private func tileWasDragged(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began, .changed:
            if dragOperations[sender] == nil {
                beginAnimation(sender: sender)
            } else {
                updateAnimation(sender: sender)
            }
        default:
            completeAnimation(sender: sender)
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
                attachGestureRecognizers(to: tileView)
            }

            addSubview(tileView)
            place(tileView, at: position)
        }
    }

    private func attachGestureRecognizers(to tileView: TileView) {
        let pressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(tileWasPressed(_:)))
        pressGestureRecognizer.minimumPressDuration = 0
        pressGestureRecognizer.delegate = self
        tileView.addGestureRecognizer(pressGestureRecognizer)

        if #available(iOS 10, *) {
            tileView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(tileWasDragged(_:))))
        } else {
            let rightSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(tileWasSwiped(_:)))
            rightSwipeGestureRecognizer.direction = .right
            let leftSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(tileWasSwiped(_:)))
            leftSwipeGestureRecognizer.direction = .left
            let upSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(tileWasSwiped(_:)))
            upSwipeGestureRecognizer.direction = .up
            let downSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(tileWasSwiped(_:)))
            downSwipeGestureRecognizer.direction = .down

            tileView.addGestureRecognizer(rightSwipeGestureRecognizer)
            tileView.addGestureRecognizer(leftSwipeGestureRecognizer)
            tileView.addGestureRecognizer(upSwipeGestureRecognizer)
            tileView.addGestureRecognizer(downSwipeGestureRecognizer)
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
    private func beginAnimation(sender: UIPanGestureRecognizer) {
        let tileView = sender.view as! TileView
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

        guard case let .possible(after: operations) = board.canPerform(moveOperation),
            dragOperations[sender] == nil
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

        dragOperation.updateVelocity(velocity)
        dragOperations[sender] = dragOperation
    }

    private func updateAnimation(sender: UIPanGestureRecognizer) {
        guard let dragOperation = dragOperations[sender] else { return }

        let velocity = sender.velocity(in: self)
        let translation = sender.translation(in: self)
        let fractionComplete = dragOperation.fractionComplete(with: translation)
        dragOperation.animator.fractionComplete = fractionComplete
        dragOperation.updateVelocity(velocity)

        if fractionComplete <= 0 {
            board.cancel(dragOperation.keyMoveOperation)
            dragOperation.animator.stopAnimation(false)
            dragOperation.animator.finishAnimation(at: .start)
            dragOperation.allMoveOperations.map { $0.reversed }.forEach(perform)
            dragOperations[sender] = nil
        } else if fractionComplete >= 1 {
            board.complete(dragOperation.keyMoveOperation)
            delegate.boardDidChange(self)
            switch dragOperation.direction {
            case .left, .right:
                sender.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
            case .up, .down:
                sender.setTranslation(CGPoint(x: translation.x, y: 0), in: self)
            }
            sender.setTranslation(.zero, in: self)
            dragOperation.animator.stopAnimation(false)
            dragOperation.animator.finishAnimation(at: .end)
            dragOperations[sender] = nil
        }
    }

    private func completeAnimation(sender: UIPanGestureRecognizer) {
        guard let dragOperation = dragOperations[sender] else { return }

        let velocity = sender.velocity(in: self)
        let animator = dragOperation.animator
        dragOperation.updateVelocity(velocity)
        let velocityAdjustment = dragOperation.fractionComplete(with: dragOperation.lastVelocity) / 4
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
        dragOperations[sender] = nil
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
