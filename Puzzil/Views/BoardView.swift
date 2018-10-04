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

    private static let maxTileSize: CGFloat = 120
    private static let cornerRadius: CGFloat = 32
    private static let boardMargins: CGFloat = 16
    private static let boardPadding: CGFloat = 8

    // MARK: - Board Properties

    private(set) var board: Board!
    var progress: Double {
        return board.progress + dragCoordinators.map { $0.value.boardProgressChange }.reduce(0, +)
    }

    weak var delegate: BoardViewDelegate!
    private var tilePositions = [TileView: TilePosition]()
    private var dragCoordinators = [UIPanGestureRecognizer: DragCoordinator]()
    private var tileSizeGuide: UILayoutGuide!
    private var tileWidth: CGFloat { return tileSizeGuide!.layoutFrame.width }
    private var tileHeight: CGFloat { return tileSizeGuide!.layoutFrame.height }
    private var horizontalDragDistance: CGFloat { return tileWidth + BoardView.boardPadding }
    private var verticalDragDistance: CGFloat { return tileHeight + BoardView.boardPadding }

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

        let tileSizingConstraints = [
            guide.widthAnchor.constraint(equalTo: guide.heightAnchor),
            guide.widthAnchor.constraint(lessThanOrEqualToConstant: BoardView.maxTileSize),
        ]
        tileSizingConstraints.forEach { $0.priority = .defaultHigh }
        NSLayoutConstraint.activate(tileSizingConstraints)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalTo: guide.widthAnchor, multiplier: columns, constant: horizontalSpacing),
            heightAnchor.constraint(equalTo: guide.heightAnchor, multiplier: rows, constant: verticalSpacing),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        tilePositions.forEach { place($0, at: $1) }
    }

    // MARK: - Private Helpers

    private func tile(at position: TilePosition) -> TileView? {
        return tilePositions.first { $0.value == position }.flatMap { $0.key }
    }

    // MARK: - Event Handlers

    @objc private func tileWasDragged(_ sender: UIPanGestureRecognizer) {
        if let dragCoordinator = dragCoordinators[sender] {
            dragCoordinator.update(with: sender)

            switch sender.state {
            case .cancelled, .ended, .failed:
                dragCoordinators[sender] = nil
                if dragCoordinator.tileWasMoved { delegate.boardDidChange(self) }
                delegate.progressDidChange(self, incremental: false)
            default:
                delegate.progressDidChange(self, incremental: true)
            }
        } else {
            dragCoordinators[sender] = DragCoordinator(boardView: self, sender: sender)
        }
    }

    @objc private func tileWasTapped(_ sender: UITapGestureRecognizer) {
        guard UserDefaults().bool(forKey: .customKey(.tapToMove)) else { return }

        let position = tilePositions[sender.view as! TileView]!

        typealias OperationSet = (direction: TileMoveDirection, operations: [TileMoveOperation])
        let operationSets: [OperationSet] = TileMoveDirection.allCases.compactMap({ direction in
            let moveOperation = TileMoveOperation(position: position, direction: direction)
            if case let .possible(requiredOperations) = board.canPerform(moveOperation) {
                return (direction, [moveOperation] + requiredOperations)
            } else {
                return nil
            }
        })
        let minimumOperationCount = operationSets.map({ $0.operations.count }).reduce(Int.max, min)
        let simplestOperationSets = operationSets.filter { $0.operations.count == minimumOperationCount }

        guard simplestOperationSets.count == 1,
            let simpleOperationSet = simplestOperationSets.first,
            let keyMoveOperation = simpleOperationSet.operations.first
        else { return }

        let operations = simpleOperationSet.operations
        let tileViews = operations.map { tile(at: $0.startPosition)! }

        for (tileView, operation) in zip(tileViews, operations) {
            tilePositions[tileView] = operation.targetPosition
        }
        board.perform(keyMoveOperation)
        delegate.boardDidChange(self)
        delegate.progressDidChange(self, incremental: false)
        UIViewPropertyAnimator(duration: .normalAnimationDuration, dampingRatio: 1) {
            for (tileView, operation) in zip(tileViews, operations) {
                self.place(tileView, at: operation.targetPosition)
            }
        }.startAnimation()
    }

    // MARK: - Tile Operations

    func reloadBoard() {
        board = delegate.newBoard(for: self)

        clearBoard()
        generateTiles()

        setNeedsUpdateConstraints()
    }

    func cancelAllOperations() {
        dragCoordinators.forEach { recognizer, _ in
            recognizer.isEnabled.toggle()
            recognizer.isEnabled.toggle()
        }
    }

    private func clearBoard() {
        tilePositions.keys.forEach { $0.removeFromSuperview() }
        tilePositions.removeAll()
    }

    // MARK: Tile Creation

    private func generateTiles() {
        for position in board.indices {
            guard let text = board.tileText(at: position) else { continue }

            let tileView = TileView()
            tileView.text = text

            attachGestureRecognizers(to: tileView)

            addSubview(tileView)
            tilePositions[tileView] = position
        }
    }

    private func attachGestureRecognizers(to tileView: TileView) {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(tileWasDragged(_:)))
        panGestureRecognizer.cancelsTouchesInView = false
        tileView.addGestureRecognizer(panGestureRecognizer)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tileWasTapped(_:)))
        tileView.addGestureRecognizer(tapGestureRecognizer)
    }

    // MARK: Tile Placement

    private func place(_ tileView: TileView, at position: TilePosition) {
        let x = BoardView.boardMargins + CGFloat(position.column) * (tileWidth + BoardView.boardPadding)
        let y = BoardView.boardMargins + CGFloat(position.row) * (tileHeight + BoardView.boardPadding)
        tileView.frame = CGRect(x: x, y: y, width: tileWidth, height: tileHeight)
    }
}

// MARK: - DragOperation

extension BoardView {
    private class DragCoordinator {
        private var dragOperation: DragOperation?
        private let boardView: BoardView
        private(set) var tileWasMoved = false
        var boardProgressChange: Double {
            return dragOperation?.boardProgressChange ?? 0
        }

        init(boardView: BoardView, sender: UIPanGestureRecognizer) {
            self.boardView = boardView

            update(with: sender)
        }

        func update(with sender: UIPanGestureRecognizer) {
            if let dragOperation = dragOperation ?? DragOperation(boardView: boardView, sender: sender) {
                if self.dragOperation === dragOperation {
                    dragOperation.update(with: sender)
                } else {
                    self.dragOperation = dragOperation
                }

                switch dragOperation.state {
                case .completed:
                    tileWasMoved = true
                    fallthrough
                case .cancelled:
                    self.dragOperation = nil
                    sender.setTranslation(.zero, in: boardView)
                case .active:
                    break
                }
            } else {
                sender.setTranslation(.zero, in: boardView)
            }
        }
    }

    private class DragOperation {
        private static let velocityBias: CGFloat = 0.5

        enum State {
            case active(progress: CGFloat)
            case cancelled
            case completed
        }

        private let boardView: BoardView
        private let direction: TileMoveDirection
        private let keyMoveOperation: TileMoveOperation
        private let targetPositions: [(TileView, TilePosition)]
        private let animator: UIViewPropertyAnimator
        private var averageVelocity: CGFloat = 0

        private(set) var state: State = .active(progress: 0)
        private var dragDistance: CGFloat {
            switch direction {
            case .left, .right:
                return boardView.horizontalDragDistance
            case .up, .down:
                return boardView.verticalDragDistance
            }
        }

        var boardProgressChange: Double {
            var board = boardView.board!
            let startProgress = board.progress
            board.complete(keyMoveOperation)
            let endProgress = board.progress

            return (endProgress - startProgress) * Double(animator.fractionComplete)
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

            boardView.board.begin(keyMoveOperation)

            let animator = UIViewPropertyAnimator(duration: .normalAnimationDuration, curve: .linear) {
                for moveOperation in moveOperations {
                    let tileView = boardView.tile(at: moveOperation.startPosition)!
                    boardView.place(tileView, at: moveOperation.targetPosition)
                }
            }

            self.animator = animator
            self.direction = direction
            self.keyMoveOperation = keyMoveOperation
            self.targetPositions = Array(zip(tileViews, targetPositions))

            update(with: sender)
        }

        func update(with sender: UIPanGestureRecognizer) {
            switch state {
            case .completed, .cancelled:
                fatalError("Cannot update inactive drag operation")
            default:
                break
            }

            let translation = sender.translation(in: boardView)
            let velocity = sender.velocity(in: boardView)
            let clippedVelocity = velocity.magnitude(towards: direction)
            let clippedTranslation = translation.magnitude(towards: direction, lowerBound: 0, upperBound: dragDistance)
            let progress = clippedTranslation / dragDistance
            animator.fractionComplete = progress
            state = .active(progress: progress)

            updateAverageVelocity(with: clippedVelocity)

            if progress == 0 {
                cancelOperation()
                animator.stopAnimation(false)
                animator.finishAnimation(at: .start)
            } else if progress == 1 {
                completeOperation()
                animator.stopAnimation(false)
                animator.finishAnimation(at: .end)
            } else {
                switch sender.state {
                case .ended, .cancelled, .failed:
                    let projectedTranslation = translation
                        .projected(by: velocity)
                        .magnitude(towards: direction, lowerBound: 0, upperBound: dragDistance)
                    let projectedProgress = projectedTranslation / dragDistance

                    if projectedProgress < 0.5 {
                        cancelOperation()
                        let initialVelocity = CGVector(dx: -averageVelocity / dragDistance, dy: 0)
                        let timingParameters = UISpringTimingParameters(dampingRatio: 1, initialVelocity: initialVelocity)
                        animator.isReversed = true
                        animator.continueAnimation(withTimingParameters: timingParameters, durationFactor: 1)
                    } else {
                        completeOperation()
                        let initialVelocity = CGVector(dx: averageVelocity / dragDistance, dy: 0)
                        let timingParameters = UISpringTimingParameters(dampingRatio: 1, initialVelocity: initialVelocity)
                        animator.continueAnimation(withTimingParameters: timingParameters, durationFactor: 1)
                    }
                default:
                    break
                }
            }
        }

        private func completeOperation() {
            state = .completed
            boardView.board.complete(keyMoveOperation)
            for (tileView, position) in targetPositions {
                boardView.tilePositions[tileView] = position
            }
        }

        private func cancelOperation() {
            state = .cancelled
            boardView.board.cancel(keyMoveOperation)
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
            let translationIsVertical = abs(translation.y) > abs(translation.x)

            if possibleDirections.contains(horizontalDirection) && translationIsHorizontal {
                return horizontalDirection
            } else if possibleDirections.contains(verticalDirection) && translationIsVertical {
                return verticalDirection
            } else if possibleDirections.contains(horizontalDirection) {
                return horizontalDirection
            } else if possibleDirections.contains(verticalDirection) {
                return verticalDirection
            }

            return nil
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
