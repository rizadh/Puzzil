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
    var progress: Double {
        return board.progress + dragCoordinators.map { $0.value.boardProgressChange }.reduce(0, +)
    }

    weak var delegate: BoardViewDelegate!
    private var tilePositions = [TileView: TilePosition]()
    private var dragCoordinators = [UIPanGestureRecognizer: DragCoordinator]()
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
        if let dragCoordinator = dragCoordinators[sender] {
            dragCoordinator.update(with: sender)

            delegate.progressDidChange(self)

            switch sender.state {
            case .cancelled, .ended, .failed:
                dragCoordinators[sender] = nil
                if dragCoordinator.tileWasMoved { delegate.boardDidChange(self) }
            default:
                break
            }
        } else {
            dragCoordinators[sender] = DragCoordinator(boardView: self, sender: sender)
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
        private var dragDistance: CGFloat { return boardView.dragDistance }
        var boardProgressChange: Double {
            var board = self.boardView.board!
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

            let animator = UIViewPropertyAnimator(duration: 0.25, curve: .linear) {
                for moveOperation in moveOperations {
                    let tileView = boardView.tile(at: moveOperation.startPosition)!
                    boardView.place(tileView, at: moveOperation.targetPosition)
                }
            }
            animator.isUserInteractionEnabled = false

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
            }

            switch sender.state {
            case .ended, .cancelled, .failed:
                let projectedTranslation = DragOperation.projectTranslation(translation: clippedTranslation, velocity: averageVelocity)
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
            }

            return nil
        }

        private static func projectTranslation(translation: CGFloat, velocity: CGFloat) -> CGFloat {
            let deceleration: CGFloat = 1000

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

private extension CGPoint {
    func magnitude(towards direction: TileMoveDirection, lowerBound: CGFloat = -.infinity, upperBound: CGFloat = .infinity) -> CGFloat {
        let rawMagnitude: CGFloat

        switch direction {
        case .left:
            rawMagnitude = -x
        case .right:
            rawMagnitude = x
        case .up:
            rawMagnitude = -y
        case .down:
            rawMagnitude = y
        }

        if rawMagnitude < lowerBound { return lowerBound }
        if rawMagnitude > upperBound { return upperBound }
        return rawMagnitude
    }
}
