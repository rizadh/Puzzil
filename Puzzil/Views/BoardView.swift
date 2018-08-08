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
    private var dragOperations = [UIPanGestureRecognizer: DragOperation]()
    private var tileGuides = [[UILayoutGuide]]()
    private var tileSize: CGFloat = 0
    private var tileSizeGuide: UILayoutGuide?
    private var dragDistance: CGFloat {
        return tileSize + BoardView.boardPadding
    }

    // MARK: - Constructors

    init() {
        super.init(frame: .zero)

        isOpaque = false
        backgroundColor = ColorTheme.selected.secondary
        layer.cornerRadius = BoardView.cornerRadius
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        super.updateConstraints()

        let columns = CGFloat(board.columnCount)
        let rows = CGFloat(board.rowCount)
        let totalMargins = 2 * BoardView.boardMargins
        let horizontalPadding = BoardView.boardPadding * (columns - 1)
        let verticalPadding = BoardView.boardPadding * (rows - 1)
        let horizontalSpacing = horizontalPadding + totalMargins
        let verticalSpacing = verticalPadding + totalMargins

        let guide = UILayoutGuide()
        tileSizeGuide.flatMap(removeLayoutGuide)
        tileSizeGuide = guide
        addLayoutGuide(guide)

        guide.widthAnchor.constraint(equalTo: guide.heightAnchor).isActive = true
        widthAnchor
            .constraint(equalTo: guide.widthAnchor, multiplier: columns, constant: horizontalSpacing)
            .isActive = true
        heightAnchor
            .constraint(equalTo: guide.heightAnchor, multiplier: rows, constant: verticalSpacing)
            .isActive = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let totalMargins = 2 * BoardView.boardMargins
        let horizontalPadding = BoardView.boardPadding * CGFloat(board.columnCount - 1)
        let tileWidth = (bounds.width - horizontalPadding - totalMargins) / CGFloat(board.columnCount)
        tileSize = tileWidth

        tilePositions.forEach { place($0, at: $1) }
    }

    // MARK: - Private Helpers

    private func tile(at position: TilePosition) -> TileView? {
        return tilePositions.first { $0.value == position }.flatMap { $0.key }
    }

    // MARK: - Event Handlers

    @objc private func tileWasDragged(_ sender: UIPanGestureRecognizer) {
        if let dragOperation = dragOperations[sender] {
            dragOperation.update(with: sender)

            switch sender.state {
            case .cancelled, .ended, .failed:
                dragOperations[sender] = nil
            default:
                break
            }
        } else {
            dragOperations[sender] = DragOperation(boardView: self, sender: sender)
        }
    }

    // MARK: - Tile Layout

    func reloadBoard() {
        board = delegate.newBoard(for: self)

        clearBoard()
        generateTiles()

        setNeedsUpdateConstraints()
    }

    private func clearBoard() {
        tilePositions.keys.forEach { $0.removeFromSuperview() }
        tilePositions.removeAll()

        tileGuides.forEach { $0.forEach(removeLayoutGuide(_:)) }
        tileGuides.removeAll()
    }

    // MARK: Tile Creation

    private func generateTiles() {
        for position in board.indices {
            guard let text = board.tileText(at: position) else { continue }

            let tileView = TileView()
            tileView.text = text

            if isDynamic {
                attachGestureRecognizers(to: tileView)
            }

            addSubview(tileView)
            tilePositions[tileView] = position
        }
    }

    private func attachGestureRecognizers(to tileView: TileView) {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(tileWasDragged(_:)))
        panGestureRecognizer.cancelsTouchesInView = false
        tileView.addGestureRecognizer(panGestureRecognizer)
    }

    // MARK: Tile Placement

    private func place(_ tileView: TileView, at position: TilePosition) {
        let x = BoardView.boardMargins + CGFloat(position.column) * (tileSize + BoardView.boardPadding)
        let y = BoardView.boardMargins + CGFloat(position.row) * (tileSize + BoardView.boardPadding)
        tileView.frame = CGRect(x: x, y: y, width: tileSize, height: tileSize)
    }
}

// MARK: - DragOperation

extension BoardView {
    private class DragOperation {
        private static let velocityBias: CGFloat = 0.9

        private let boardView: BoardView
        private let direction: TileMoveDirection
        private let keyMoveOperation: TileMoveOperation
        private let targetPositions: [(TileView, TilePosition)]
        private let animator: UIViewPropertyAnimator
        private var averageVelocity: CGFloat = 0

        private var dragDistance: CGFloat {
            return boardView.dragDistance
        }

        init?(boardView: BoardView, sender: UIPanGestureRecognizer) {
            self.boardView = boardView
            let tileView = sender.view as! TileView
            let position = boardView.tilePositions[tileView]!

            let translation = sender.translation(in: boardView)
            let possibleDirections = TileMoveDirection.allCases.filter { direction in
                let moveOperation = TileMoveOperation(position: position, direction: direction)
                if case .possible = boardView.board.canPerform(moveOperation) {
                    return true
                } else {
                    return false
                }
            }

            guard let direction = DragOperation.dragDirection(from: translation, given: Set(possibleDirections)) else {
                sender.setTranslation(.zero, in: boardView)
                return nil
            }

            let keyMoveOperation = TileMoveOperation(position: position, direction: direction)
            guard case let .possible(after: resultingMoveOperations) = boardView.board.canPerform(keyMoveOperation)
            else { fatalError() }
            let moveOperations = [keyMoveOperation] + resultingMoveOperations
            let tileViews = moveOperations.map { boardView.tile(at: $0.startPosition)! }
            let targetPositions = moveOperations.map { $0.targetPosition }

            self.direction = direction
            self.keyMoveOperation = keyMoveOperation
            self.targetPositions = Array(zip(tileViews, targetPositions))

            boardView.board.begin(keyMoveOperation)

            animator = UIViewPropertyAnimator(duration: 0.25, curve: .linear) {
                for moveOperation in moveOperations {
                    let tileView = boardView.tile(at: moveOperation.startPosition)!
                    boardView.place(tileView, at: moveOperation.targetPosition)
                }
            }
            animator.isUserInteractionEnabled = false

            update(with: sender)
        }

        func update(with sender: UIPanGestureRecognizer) {
            let translation = sender.translation(in: boardView)
            let velocity = sender.velocity(in: boardView)
            let clippedVelocity = DragOperation.clipTranslation(velocity, to: .infinity, towards: direction)
            let clippedTranslation = DragOperation.clipTranslation(translation, to: dragDistance, towards: direction)
            let progress = clippedTranslation / dragDistance
            animator.fractionComplete = progress

            switch sender.state {
            case .ended, .cancelled, .failed:
                let velocity = sender.velocity(in: boardView)
                let clippedVelocity = DragOperation.clipTranslation(velocity, to: .infinity, towards: direction)
                let projectedTranslation = DragOperation.projectTranslation(translation: clippedTranslation, velocity: clippedVelocity)
                let projectedProgress = projectedTranslation / dragDistance

                if projectedProgress == 0 {
                    cancelDragOperation()
                    animator.stopAnimation(false)
                    animator.finishAnimation(at: .start)
                } else if projectedProgress < 0.5 {
                    cancelDragOperation()
                    animator.isReversed = true
                    let initialVelocity = CGVector(dx: -averageVelocity / dragDistance, dy: 0)
                    let timingParameters = UISpringTimingParameters(dampingRatio: 1, initialVelocity: initialVelocity)
                    animator.continueAnimation(withTimingParameters: timingParameters, durationFactor: 1)
                } else if projectedProgress < 1 {
                    completeDragOperation()
                    let initialVelocity = CGVector(dx: averageVelocity / dragDistance, dy: 0)
                    let timingParameters = UISpringTimingParameters(dampingRatio: 1, initialVelocity: initialVelocity)
                    animator.continueAnimation(withTimingParameters: timingParameters, durationFactor: 1)
                } else {
                    completeDragOperation()
                    animator.stopAnimation(false)
                    animator.finishAnimation(at: .end)
                }
            default:
                break
            }
        }

        private func cancelDragOperation() {
            boardView.board.cancel(keyMoveOperation)
        }

        private func completeDragOperation() {
            boardView.board.complete(keyMoveOperation)
            for (tileView, position) in targetPositions {
                boardView.tilePositions[tileView] = position
            }
            boardView.delegate.boardDidChange(boardView)
        }

        private func updateAverageVelocity(with currentVelocity: CGFloat) {
            let biasedAverageVelocity = averageVelocity * DragOperation.velocityBias
            let biasedCurrentVelocity = currentVelocity * (1 - DragOperation.velocityBias)

            averageVelocity = biasedAverageVelocity + biasedCurrentVelocity
        }

        private static func dragDirection(from translation: CGPoint,
                                          given possibleDirections: Set<TileMoveDirection>) -> TileMoveDirection? {
            let horizontalDirection: TileMoveDirection = translation.x < 0 ? .left : .right
            let verticalDirection: TileMoveDirection = translation.y < 0 ? .up : .down
            let translationIsHorizontal = abs(translation.x) > abs(translation.y)

            if possibleDirections.contains(horizontalDirection) && translationIsHorizontal {
                return horizontalDirection
            } else if possibleDirections.contains(verticalDirection) {
                return verticalDirection
            }

            return nil
        }

        private static func clipTranslation(_ translation: CGPoint, to distance: CGFloat,
                                            towards direction: TileMoveDirection) -> CGFloat {
            switch direction {
            case .left:
                return min(distance, max(-translation.x, 0))
            case .right:
                return min(distance, max(translation.x, 0))
            case .up:
                return min(distance, max(-translation.y, 0))
            case .down:
                return min(distance, max(translation.y, 0))
            }
        }

        private static func projectTranslation(translation: CGFloat, velocity: CGFloat) -> CGFloat {
            let deceleration: CGFloat = 10000

            switch velocity.sign {
            case .minus:
                return translation - pow(velocity, 2) / deceleration
            case .plus:
                return translation + pow(velocity, 2) / deceleration
            }
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension BoardView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer is UILongPressGestureRecognizer
    }
}
