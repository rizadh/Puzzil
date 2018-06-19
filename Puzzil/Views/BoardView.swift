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

        applyMotionEffect(distance: 8)
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

            if dragOperation.isComplete {
                dragOperations.removeValue(forKey: sender)
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
        for position in TilePosition.traversePositions(rows: board.rowCount, columns: board.columnCount) {
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
        let transform = tileView.transform
        tileView.transform = .identity
        tileView.frame = CGRect(x: x, y: y, width: tileSize, height: tileSize)
        tileView.transform = transform
    }

    private func moveTile(operation moveOperation: TileMoveOperation) {
        let tileView = tile(at: moveOperation.startPosition)!

        place(tileView, at: moveOperation.targetPosition)
        tilePositions[tileView] = moveOperation.targetPosition
    }
}

// MARK: - DragOperation

extension BoardView {
    private class DragOperation {
        private static var tileShadowRadius: CGFloat = 4
        private static var tileShadowColor: CGColor {
            let (hue, saturation, brightness, _) = ColorTheme.selected.secondary.hsba!

            return UIColor(hue: hue, saturation: saturation, brightness: brightness * 0.8, alpha: 1).cgColor
        }
        private static var tileShadowOpacity: Float {
            return 1
        }

        var isComplete = false
        let boardView: BoardView
        let direction: TileMoveDirection
        let keyMoveOperation: TileMoveOperation
        let moveOperations: [TileMoveOperation]
        let tileViews: [TileView]
        var tilesAreRaised = false

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

            let moveOperation = TileMoveOperation(position: position, direction: direction)
            guard case let .possible(after: resultingMoveOperations) = boardView.board.canPerform(moveOperation)
            else { fatalError() }

            self.direction = direction
            keyMoveOperation = moveOperation
            moveOperations = [moveOperation] + resultingMoveOperations
            tileViews = [tileView] + resultingMoveOperations.map { boardView.tile(at: $0.startPosition)! }

            boardView.board.begin(keyMoveOperation)

            update(with: sender)

            if isComplete { return nil }
            else { raiseTiles() }
        }

        func update(with sender: UIPanGestureRecognizer) {
            if isComplete { fatalError() }

            let translation = sender.translation(in: boardView)
            let clippedTranslation = DragOperation.clipTranslation(translation, to: boardView.dragDistance,
                                                                   towards: direction)
            let transform = CGAffineTransform(translationX: clippedTranslation.x, y: clippedTranslation.y)

            switch sender.state {
            case .ended, .cancelled, .failed:
                let velocity = sender.velocity(in: boardView)
                let projectedTranslation = DragOperation.projectTranslation(translation: translation,
                                                                            velocity: velocity)
                let projectedProgress = DragOperation.dragProgress(with: projectedTranslation,
                                                                   towards: direction,
                                                                   dragDistance: boardView.dragDistance)

                if projectedProgress > 0.5 {
                    boardView.board.complete(keyMoveOperation)

                    var finalMoveOperations = moveOperations
                    var nextKeyMoveOperation = keyMoveOperation.nextOperation

                    var traversedProgress: CGFloat = 1
                    while case let .possible(after: operations) = boardView.board.canPerform(nextKeyMoveOperation),
                        projectedProgress > 0.5 + traversedProgress {
                        boardView.board.perform(nextKeyMoveOperation)
                        finalMoveOperations = [nextKeyMoveOperation] + operations
                        nextKeyMoveOperation = nextKeyMoveOperation.nextOperation
                        traversedProgress += 1
                    }

                    for (tileView, moveOperation) in zip(tileViews, finalMoveOperations) {
                        tileView.transform = .identity
                        tileView.frame = tileView.frame.applying(transform)
                        boardView.tilePositions[tileView] = moveOperation.targetPosition
                    }

                    UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0,
                                   options: [.allowUserInteraction], animations: {
                                       zip(self.tileViews, finalMoveOperations).forEach {
                                           self.boardView.place($0, at: $1.targetPosition)
                                       }
                    })

                    lowerTiles()

                    boardView.delegate.boardDidChange(boardView)
                } else {
                    boardView.board.cancel(keyMoveOperation)

                    for tileView in tileViews {
                        tileView.transform = .identity
                        tileView.frame = tileView.frame.applying(transform)
                    }

                    var tilesToAnimate = [TileView: TilePosition]()
                    zip(tileViews, moveOperations).forEach { tileView, moveOperation in
                        tilesToAnimate[tileView] = moveOperation.startPosition
                    }

                    var finalMoveOperationsOrNil: [TileMoveOperation]?
                    var nextKeyMoveOperation = keyMoveOperation.reversed.nextOperation

                    var traversedProgress: CGFloat = -1
                    while case let .possible(after: operations) = boardView.board.canPerform(nextKeyMoveOperation),
                        projectedProgress < 0.5 + traversedProgress {
                        boardView.board.perform(nextKeyMoveOperation)
                        finalMoveOperationsOrNil = [nextKeyMoveOperation] + operations
                        nextKeyMoveOperation = nextKeyMoveOperation.nextOperation
                        traversedProgress -= 1
                    }

                    if let finalMoveOperations = finalMoveOperationsOrNil {
                        let finalTileViews = finalMoveOperations.map { self.boardView.tile(at: $0.startPosition)! }

                        zip(finalTileViews, finalMoveOperations).forEach {
                            tilesToAnimate[$0] = $1.targetPosition
                            self.boardView.tilePositions[$0] = $1.targetPosition
                        }

                        boardView.delegate.boardDidChange(boardView)
                    }

                    UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0,
                                   options: [.allowUserInteraction], animations: {
                                       tilesToAnimate.forEach {
                                           self.boardView.place($0, at: $1)
                                       }
                    })

                    lowerTiles()
                }

                isComplete = true
            default:
                let progress = DragOperation.dragProgress(with: translation, towards: direction,
                                                          dragDistance: boardView.dragDistance)

                if progress >= 1 {
                    isComplete = true
                    lowerTiles()
                    sender.setTranslation(.zero, in: boardView)

                    boardView.board.complete(keyMoveOperation)
                    boardView.delegate.boardDidChange(boardView)
                    for (tileView, moveOperation) in zip(tileViews, moveOperations) {
                        tileView.transform = .identity
                        tileView.frame = tileView.frame.applying(transform)
                        boardView.tilePositions[tileView] = moveOperation.targetPosition
                    }
                } else if progress <= 0 {
                    isComplete = true
                    lowerTiles()
                    sender.setTranslation(.zero, in: boardView)

                    boardView.board.cancel(keyMoveOperation)
                } else {
                    tileViews.forEach { $0.transform = transform }
                }
            }
        }

        private func raiseTiles() {
            if tilesAreRaised { return }

            let animation = CABasicAnimation()
            animation.duration = 0.25
            animation.fromValue = 0
            animation.toValue = DragOperation.tileShadowOpacity

            tileViews.forEach {
                $0.layer.shadowOffset = .zero
                $0.layer.shadowColor = DragOperation.tileShadowColor
                $0.layer.shadowRadius = DragOperation.tileShadowRadius

                $0.layer.shadowOpacity = DragOperation.tileShadowOpacity
                $0.layer.add(animation, forKey: "shadowOpacity")
            }

            tilesAreRaised = true
        }

        private func lowerTiles() {
            if !tilesAreRaised { return }

            let animation = CABasicAnimation()
            animation.duration = 0.25
            animation.fromValue = DragOperation.tileShadowOpacity
            animation.toValue = 0

            tileViews.forEach {
                $0.layer.shadowOpacity = 0
                $0.layer.add(animation, forKey: "shadowOpacity")
            }

            tilesAreRaised = false
        }

        private static func dragDirection(from translation: CGPoint,
                                          given possibleDirections: Set<TileMoveDirection>) -> TileMoveDirection? {
            let leftDraggable = possibleDirections.contains(.left)
            let rightDraggable = possibleDirections.contains(.right)
            let upDraggable = possibleDirections.contains(.up)
            let downDraggable = possibleDirections.contains(.down)

            switch (leftDraggable, rightDraggable, upDraggable, downDraggable) {
            case (true, true, true, true):
                if abs(translation.x) > abs(translation.y) {
                    if translation.x < 0 { return .left }
                    else { return .right }
                } else {
                    if translation.y < 0 { return .up }
                    else { return .down }
                }
            case (true, true, false, false):
                return translation.x < 0 ? .left : .right
            case (false, false, true, true):
                return translation.y < 0 ? .up : .down
            case (true, false, true, false):
                return abs(translation.x) > abs(translation.y) ? .left : .up
            case (false, true, false, true):
                return abs(translation.x) > abs(translation.y) ? .right : .down
            case (true, false, false, true):
                return abs(translation.x) > abs(translation.y) ? .left : .down
            case (false, true, true, false):
                return abs(translation.x) > abs(translation.y) ? .right : .up
            case (true, true, true, false):
                return abs(translation.x) > abs(translation.y) ? (translation.x < 0 ? .left : .right) : .up
            case (true, true, false, true):
                return abs(translation.x) > abs(translation.y) ? (translation.x < 0 ? .left : .right) : .down
            case (true, false, true, true):
                return abs(translation.x) > abs(translation.y) ? .left : (translation.y < 0 ? .up : .down)
            case (false, true, true, true):
                return abs(translation.x) > abs(translation.y) ? .right : (translation.y < 0 ? .up : .down)
            case (true, false, false, false):
                return .left
            case (false, true, false, false):
                return .right
            case (false, false, true, false):
                return .up
            case (false, false, false, true):
                return .down
            case (false, false, false, false):
                return nil
            }
        }

        private static func clipTranslation(_ translation: CGPoint, to distance: CGFloat,
                                            towards direction: TileMoveDirection) -> CGPoint {
            switch direction {
            case .left:
                return CGPoint(x: max(-distance, min(translation.x, 0)), y: 0)
            case .right:
                return CGPoint(x: min(distance, max(translation.x, 0)), y: 0)
            case .up:
                return CGPoint(x: 0, y: max(-distance, min(translation.y, 0)))
            case .down:
                return CGPoint(x: 0, y: min(distance, max(translation.y, 0)))
            }
        }

        private static func projectTranslation(translation: CGPoint, velocity: CGPoint) -> CGPoint {
            return CGPoint(
                x: projectTranslation(translation: translation.x, velocity: velocity.x),
                y: projectTranslation(translation: translation.y, velocity: velocity.y)
            )
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

        private static func dragProgress(with translation: CGPoint, towards direction: TileMoveDirection,
                                         dragDistance: CGFloat) -> CGFloat {
            switch direction {
            case .left:
                return -translation.x / dragDistance
            case .right:
                return translation.x / dragDistance
            case .up:
                return -translation.y / dragDistance
            case .down:
                return translation.y / dragDistance
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
