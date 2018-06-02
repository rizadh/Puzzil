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
    private static let boardMargins: CGFloat = 16
    private static let boardPadding: CGFloat = 8

    // MARK: - Board Properties

    private(set) var board: Board!
    var isDynamic = true

    weak var delegate: BoardViewDelegate!
    private var tilePositions = [TileView: TilePosition]()
    private var tileGuides = [[UILayoutGuide]]()
    private var tileSize: CGFloat = 0

    // MARK: - Drag Operation Coordination

    private var tileVelocities = [TileView: CGPoint]()
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
        return tilePositions.first { $0.value == position }!.key
    }

    // MARK: - Event Handlers

    @objc private func tileWasSwiped(_ sender: UISwipeGestureRecognizer) {
        let tileView = sender.view as! TileView
        let position = tilePositions[tileView]!
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
        tilePositions.keys.forEach { $0.removeFromSuperview() }
        tilePositions.removeAll()

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

            columnGuide.leftAnchor.constraint(
                equalTo: lastColumnAnchor,
                constant: columnIndex == 0 ? BoardView.boardMargins : BoardView.boardPadding
            ).isActive = true
            lastColumnAnchor = columnGuide.rightAnchor

            return columnGuide
        }

        rightAnchor.constraint(equalTo: lastColumnAnchor, constant: 16).isActive = true

        // Generate row guides
        var lastRowAnchor = topAnchor
        let rowGuides: [UILayoutGuide] = (0..<board.rowCount).map { rowIndex in
            let rowGuide = UILayoutGuide()
            addLayoutGuide(rowGuide)

            rowGuide.topAnchor.constraint(
                equalTo: lastRowAnchor,
                constant: rowIndex == 0 ? BoardView.boardMargins : BoardView.boardPadding
            ).isActive = true
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
        layoutIfNeeded()

        let paddingCount = CGFloat(board.columnCount - 1)
        let totalPadding = paddingCount * BoardView.boardPadding
        let totalMargins = 2 * BoardView.boardMargins
        tileSize = (frame.width - totalMargins - totalPadding) / CGFloat(board.columnCount)

        for position in TilePosition.traversePositions(rows: board.rowCount, columns: board.columnCount) {
            guard let text = board.tileText(at: position) else { continue }

            let tileView = TileView()
            tileView.text = text

            if isDynamic {
                attachGestureRecognizers(to: tileView)
            }

            addSubview(tileView)
            place(tileView, at: position)
            tilePositions[tileView] = position
        }
    }

    private func attachGestureRecognizers(to tileView: TileView) {
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

    private func place(_ tileView: TileView, at position: TilePosition) {
        let x = BoardView.boardMargins + CGFloat(position.column) * (tileSize + BoardView.boardPadding)
        let y = BoardView.boardMargins + CGFloat(position.row) * (tileSize + BoardView.boardPadding)
        let transform = tileView.transform
        tileView.transform = .identity
        tileView.frame = CGRect(x: x, y: y, width: tileSize, height: tileSize)
        tileView.transform = transform
    }

    private func perform(_ moveOperation: TileMoveOperation) {
        let tileView = tile(at: moveOperation.startPosition)

        place(tileView, at: moveOperation.targetPosition)
        tilePositions[tileView] = moveOperation.targetPosition
    }
}

// MARK: - Interactive Drag Support

@available(iOS 10, *)
extension BoardView {
    private func beginAnimation(sender: UIPanGestureRecognizer) {
        let tileView = sender.view as! TileView
        let velocity = sender.velocity(in: self)
        let direction: TileMoveDirection
        let position = tilePositions[tileView]!
        if abs(velocity.x) > abs(velocity.y) {
            if velocity.x < 0 { direction = .left }
            else { direction = .right }
        } else {
            if velocity.y < 0 { direction = .up }
            else { direction = .down }
        }

        let moveOperation = TileMoveOperation(position: position, direction: direction)

        guard case let .possible(after: operations) = board.canPerform(moveOperation),
            dragOperations[sender] == nil else {
            sender.setTranslation(.zero, in: self)
            return
        }

        board.begin(moveOperation)

        let animator = UIViewPropertyAnimator(duration: 0.25, dampingRatio: 1) {
            (operations + [moveOperation]).forEach(self.perform)
        }

        let originalFrame = tileView.frame
        animator.pauseAnimation()
        let targetFrame = tileView.frame
        let dragOperation = TileDragOperation(direction: moveOperation.direction, originalFrame: originalFrame,
                                              targetFrame: targetFrame, animator: animator,
                                              keyMoveOperation: moveOperation,
                                              moveOperations: operations)

        updateVelocity(for: tileView, with: velocity)
        dragOperations[sender] = dragOperation
    }

    private func updateAnimation(sender: UIPanGestureRecognizer) {
        guard let dragOperation = dragOperations[sender] else { return }

        let tileView = sender.view as! TileView
        let velocity = sender.velocity(in: self)
        let translation = sender.translation(in: self)
        let fractionComplete = dragOperation.fractionComplete(with: translation)
        dragOperation.animator.fractionComplete = fractionComplete
        updateVelocity(for: tileView, with: velocity)

        if fractionComplete <= 0 {
            cancelDrag(dragOperation)
            dragOperation.animator.stopAnimation(false)
            dragOperation.animator.finishAnimation(at: .start)
            dragOperations[sender] = nil
            beginAnimation(sender: sender)
        } else if fractionComplete >= 1 {
            board.complete(dragOperation.keyMoveOperation)
            delegate.boardDidChange(self)
            let dragDistance = tileSize + BoardView.boardPadding
            let newTranslationX: CGFloat
            let newTranslationY: CGFloat
            switch dragOperation.direction {
            case .left:
                newTranslationX = translation.x + dragDistance
                newTranslationY = 0
            case .right:
                newTranslationX = translation.x - dragDistance
                newTranslationY = 0
            case .up:
                newTranslationX = 0
                newTranslationY = translation.y + dragDistance
            case .down:
                newTranslationX = 0
                newTranslationY = translation.y - dragDistance
            }
            sender.setTranslation(CGPoint(x: newTranslationX, y: newTranslationY), in: self)
            dragOperation.animator.stopAnimation(false)
            dragOperation.animator.finishAnimation(at: .end)
            dragOperations[sender] = nil
            beginAnimation(sender: sender)
        }
    }

    private func completeAnimation(sender: UIPanGestureRecognizer) {
        guard let dragOperation = dragOperations[sender] else { return }

        let tileView = sender.view as! TileView
        let velocity = sender.velocity(in: self)
        let animator = dragOperation.animator
        updateVelocity(for: tileView, with: velocity)
        let velocityAdjustment = dragOperation.fractionComplete(with: tileVelocities[tileView]!) / 4
        let moveShouldBeCancelled = animator.fractionComplete + velocityAdjustment < 0.5

        if moveShouldBeCancelled {
            animator.isReversed = true
            cancelDrag(dragOperation)
        } else {
            board.complete(dragOperation.keyMoveOperation)
            delegate.boardDidChange(self)
        }

        let timingParameters = UISpringTimingParameters(dampingRatio: 1,
                                                        initialVelocity: CGVector(dx: velocityAdjustment, dy: 0))
        animator.continueAnimation(withTimingParameters: timingParameters, durationFactor: 1)
        tileVelocities[tileView] = nil
        dragOperations[sender] = nil
    }

    private func updateVelocity(for tileView: TileView, with velocity: CGPoint) {
        let currentVelocity = tileVelocities[tileView] ?? CGPoint(x: 0, y: 0)
        let bias: CGFloat = 0.8
        let newVelocityX = currentVelocity.x * bias + velocity.x * (1 - bias)
        let newVelocityY = currentVelocity.y * bias + velocity.y * (1 - bias)
        tileVelocities[tileView] = CGPoint(x: newVelocityX, y: newVelocityY)
    }

    private func cancelDrag(_ dragOperation: TileDragOperation) {
        dragOperation.allMoveOperations.reversed().forEach { moveOperation in
            let tileView = tile(at: moveOperation.targetPosition)
            tilePositions[tileView] = moveOperation.startPosition
        }
        board.cancel(dragOperation.keyMoveOperation)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension BoardView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer is UILongPressGestureRecognizer
    }
}
