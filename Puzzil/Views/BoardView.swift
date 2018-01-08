//
//  BoardView.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-28.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import UIKit

class BoardView: GradientView {
    var tilePositions = [TileView: TilePosition]()
    var tileConstraints = [TileView: [NSLayoutConstraint]]()
    var rowGuides = [UILayoutGuide]()
    var columnGuides = [UILayoutGuide]()
    var delegate: BoardViewDelegate! {
        didSet { setupSubviews() }
    }

    init() {
        super.init(from: .themeForegroundPink, to: .themeForegroundOrange)

        isOpaque = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func clippingPath(for gradientBounds: CGRect) -> CGPath {
        let cornerRadius: CGFloat = 32
        let borderWidth: CGFloat = 8

        let outer = UIBezierPath(roundedRect: gradientBounds, cornerRadius: cornerRadius)
        let innerBounds = gradientBounds.insetBy(dx: borderWidth, dy: borderWidth)
        let innerRadius = cornerRadius - borderWidth
        let inner = UIBezierPath(roundedRect: innerBounds, cornerRadius: innerRadius)

        let shape = UIBezierPath()
        shape.append(inner)
        shape.append(outer)

        return shape.cgPath
    }

    private func setupGestureRecognizer() {
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(tileWasDragged(_:))))
    }

    @objc private func tileWasDragged(_ sender: UISwipeGestureRecognizer) {
        let tile = sender.view as! TileView
        let position = tilePositions[tile]!
        let direction = TileMoveDirection(from: sender.direction)!

        let newPosition = position.moved(direction)
        if delegate.boardView(self, canMoveTileAt: position, direction) ?? false {
            move(tile, to: newPosition)
            let timer = CADisplayLink(target: tile, selector: #selector(tile.updateGradient))
            timer.add(to: .main, forMode: .defaultRunLoopMode)
            let animator = UIViewPropertyAnimator(duration: 0.25, dampingRatio: 1) {
                self.layoutIfNeeded()
            }

            animator.addCompletion { _ in
                timer.remove(from: .main, forMode: .defaultRunLoopMode)
            }

            animator.startAnimation()
            delegate.boardView(self, tileWasMoved: direction, from: position)
        }
    }

    private func setupSubviews() {
        clearTiles()
        generateColumnLayoutGuides()
        generateRowLayoutGuides()
        layoutTiles()
    }

    private func clearTiles() {
        tilePositions.keys.forEach { $0.removeFromSuperview() }
        tilePositions.removeAll()

        rowGuides.forEach(removeLayoutGuide(_:))
        rowGuides.removeAll()

        columnGuides.forEach(removeLayoutGuide(_:))
        rowGuides.removeAll()
    }

    private func generateColumnLayoutGuides() {
        let columns = delegate.numberOfColumns(in: self)

        var lastAnchor = leftAnchor
        var constraints = [NSLayoutConstraint]()

        for columnIndex in 0..<columns {
            let columnGuide = UILayoutGuide()
            constraints.append(columnGuide.leftAnchor.constraint(equalTo: lastAnchor, constant: columnIndex == 0 ? 16 : 8))
            columnGuides.append(columnGuide)
            columnGuide.widthAnchor.constraint(equalToConstant: 10)
            addLayoutGuide(columnGuide)
            lastAnchor = columnGuide.rightAnchor
        }

        constraints.append(rightAnchor.constraint(equalTo: lastAnchor, constant: 16))

        NSLayoutConstraint.activate(constraints)
    }

    private func generateRowLayoutGuides() {
        let rows = delegate.numberOfRows(in: self)

        var lastAnchor = topAnchor
        var constraints = [NSLayoutConstraint]()

        for rowIndex in 0..<rows {
            let rowGuide = UILayoutGuide()
            constraints.append(rowGuide.topAnchor.constraint(equalTo: lastAnchor, constant: rowIndex == 0 ? 16 : 8))
            rowGuides.append(rowGuide)
            rowGuide.heightAnchor.constraint(equalToConstant: 10)
            addLayoutGuide(rowGuide)
            lastAnchor = rowGuide.bottomAnchor
        }

        constraints.append(bottomAnchor.constraint(equalTo: lastAnchor, constant: 16))

        NSLayoutConstraint.activate(constraints)
    }

    private func layoutTiles() {
        let columns = delegate.numberOfColumns(in: self)
        let rows = delegate.numberOfRows(in: self)

        TilePosition.traversePositions(boundedBy: TilePosition(row: rows, column: columns)) { position in
            guard let text = delegate.boardView(self, textForTileAt: position) else {
                return
            }

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
    }

    private func remove(_ tile: TileView) {
        let constraints = tileConstraints[tile]!

        NSLayoutConstraint.deactivate(constraints)

        tilePositions.removeValue(forKey: tile)
        tileConstraints.removeValue(forKey: tile)
    }

    private func place(_ tile: TileView, at position: TilePosition) {
        let rowGuide = rowGuides[position.row]
        let columnGuide = columnGuides[position.column]

        let constraints = [
            tile.leftAnchor.constraint(equalTo: columnGuide.leftAnchor),
            tile.rightAnchor.constraint(equalTo: columnGuide.rightAnchor),
            tile.topAnchor.constraint(equalTo: rowGuide.topAnchor),
            tile.bottomAnchor.constraint(equalTo: rowGuide.bottomAnchor),
            tile.widthAnchor.constraint(equalTo: tile.heightAnchor),
        ]

        NSLayoutConstraint.activate(constraints)

        tilePositions[tile] = position
        tileConstraints[tile] = constraints
    }

    private func move(_ tile: TileView, to position: TilePosition) {
        remove(tile)
        place(tile, at: position)
    }
}
