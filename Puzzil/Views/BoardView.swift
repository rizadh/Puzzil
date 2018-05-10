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
    var isAwaitingBoard = true {
        didSet {
            if isAwaitingBoard {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
        }
    }

    weak var delegate: BoardViewDelegate!
    private var tiles = [TileView: TileInfo]()
    private var tileGuides = [[UILayoutGuide]]()
    private var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)

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

        addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        activityIndicator.color = .themePageControlActive
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

            let moveOperation = TileMoveOperation(moving: direction, from: position)

            if #available(iOS 10, *) {
                beginAnimation(for: moveOperation)
            } else {
                animate(moveOperation)
            }
        case .changed:
            if #available(iOS 10, *) {
                let translation = sender.translation(in: self)
                updateAnimation(for: tileView, with: translation)
            }
        default:
            if #available(iOS 10, *) {
                let velocity = sender.velocity(in: self)
                completeAnimation(for: tileView, with: velocity)
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
        switch board.canPerform(moveOperation) {
        case let .possible(after: operations):
            for operation in operations + [moveOperation] {
                perform(operation)
            }

            board.perform(moveOperation)
            delegate.boardDidChange(self)
        case .notPossible:
            fatalError("Cannot animate an impossible move operation")
        }

        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut, animations: {
            self.layoutIfNeeded()
        })
    }

    // MARK: - Tile Layout

    func reloadBoard() {
        clearTiles()

        let (rowCount, columnCount) = delegate.expectedBoardDimensions(self)

        generateLayoutGuides(rowCount: rowCount, columnCount: columnCount)

        isAwaitingBoard = true

        delegate.newBoard(for: self) { board in
            self.isAwaitingBoard = false
            self.board = board
            self.layoutTiles()

            self.tiles.keys.forEach { tileView in
                tileView.alpha = 0
                tileView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            }

            for (tileView, tileInfo) in self.tiles {
                let relativeY = 1 - Double(tileInfo.position.row) / Double(board.rowCount)

                UIView.animate(withDuration: 0.125, delay: 0.125 * relativeY, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
                    tileView.alpha = 1
                    tileView.transform = .identity
                })
            }

            Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(self.boardWasPresented), userInfo: nil, repeats: false)
        }
    }

    @objc private func boardWasPresented() {
        delegate?.boardWasPresented(self)
    }

    private func clearTiles() {
        tiles.keys.forEach { $0.removeFromSuperview() }
        tiles.removeAll()

        tileGuides.forEach { $0.forEach(removeLayoutGuide(_:)) }
        tileGuides = []
    }

    // MARK: Layout Guide Generation

    private func generateLayoutGuides(rowCount: Int, columnCount: Int) {
        // Generate column guides

        var columnGuides = [UILayoutGuide]()
        var lastColumnAnchor = leftAnchor

        for columnIndex in 0..<columnCount {
            let columnGuide = UILayoutGuide()
            columnGuides.append(columnGuide)
            addLayoutGuide(columnGuide)

            columnGuide.leftAnchor.constraint(equalTo: lastColumnAnchor, constant: columnIndex == 0 ? 16 : 8).isActive = true
            lastColumnAnchor = columnGuide.rightAnchor
        }

        rightAnchor.constraint(equalTo: lastColumnAnchor, constant: 16).isActive = true

        // Generate row guides

        var rowGuides = [UILayoutGuide]()
        var lastRowAnchor = topAnchor

        for rowIndex in 0..<rowCount {
            let rowGuide = UILayoutGuide()
            rowGuides.append(rowGuide)
            addLayoutGuide(rowGuide)

            rowGuide.topAnchor.constraint(equalTo: lastRowAnchor, constant: rowIndex == 0 ? 16 : 8).isActive = true
            lastRowAnchor = rowGuide.bottomAnchor
        }

        bottomAnchor.constraint(equalTo: lastRowAnchor, constant: 16).isActive = true

        // Generate tile guides

        for columnGuide in columnGuides {
            var tileGuidesForRow = [UILayoutGuide]()
            for rowGuide in rowGuides {
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
                tileGuidesForRow.append(tileGuide)
            }
            tileGuides.append(tileGuidesForRow)
        }
    }

    // MARK: Tile Creation

    private func layoutTiles() {
        for position in TilePosition.traversePositions(rows: board.rowCount, columns: board.columnCount) {
            guard let text = board.tileText(at: position) else { continue }

            let tile = TileView()
            tile.translatesAutoresizingMaskIntoConstraints = false
            tile.text = text

            if isDynamic {
                tile.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tileWasTapped(_:))))
                tile.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(tileWasDragged(_:))))
                let pressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(tileWasPressed(_:)))
                pressGestureRecognizer.minimumPressDuration = 0
                pressGestureRecognizer.delegate = self
                tile.addGestureRecognizer(pressGestureRecognizer)
            }

            addSubview(tile)
            place(tile, at: position)
        }
    }

    // MARK: Tile Placement

    private func remove(_ tile: TileView) {
        let constraints = tiles[tile]!.constraints

        NSLayoutConstraint.deactivate(constraints)

        tiles.removeValue(forKey: tile)
    }

    private func place(_ tile: TileView, at position: TilePosition) {
        let tileGuide = tileGuides[position.column][position.row]

        let constraints = [
            tile.leftAnchor.constraint(equalTo: tileGuide.leftAnchor),
            tile.rightAnchor.constraint(equalTo: tileGuide.rightAnchor),
            tile.topAnchor.constraint(equalTo: tileGuide.topAnchor),
            tile.bottomAnchor.constraint(equalTo: tileGuide.bottomAnchor),
        ]

        NSLayoutConstraint.activate(constraints)

        tiles[tile] = TileInfo(position: position, constraints: constraints)
    }

    private func perform(_ moveOperation: TileMoveOperation) {
        let tileView = tile(at: moveOperation.sourcePosition)
        remove(tileView)
        place(tileView, at: moveOperation.targetPosition)
    }
}

// MARK: - Interactive Drag Support

@available(iOS 10, *)
extension BoardView {
    private func beginAnimation(for moveOperation: TileMoveOperation) {
        let tileView = tile(at: moveOperation.sourcePosition)
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
                                              moveOperation: moveOperation,
                                              requiredMoveOperations: operations)

        dragOperations[tileView] = dragOperation
    }

    private func updateAnimation(for tileView: TileView, with translation: CGPoint) {
        guard let dragOperation = dragOperations[tileView] else { return }

        let fractionComplete = dragOperation.fractionComplete(with: translation)
        dragOperation.animator.fractionComplete = fractionComplete
    }

    private func completeAnimation(for tileView: TileView, with velocity: CGPoint) {
        guard let dragOperation = dragOperations[tileView] else { return }

        let animator = dragOperation.animator
        let velocityAdjustment = dragOperation.fractionComplete(with: velocity)

        if animator.fractionComplete + velocityAdjustment < 0.5 {
            animator.isReversed = true
            dragOperation.allOperations.map { $0.reversed }.forEach(perform)
            board.cancel(dragOperation.moveOperation)
        } else {
            board.complete(dragOperation.moveOperation)
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
