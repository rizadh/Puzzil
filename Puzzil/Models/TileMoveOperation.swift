//
//  TileMove.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-08.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import Foundation

struct TileMoveOperation: Equatable, Hashable {
    let startPosition: TilePosition
    let direction: TileMoveDirection

    var targetPosition: TilePosition {
        return startPosition.moved(direction)
    }

    var nextOperation: TileMoveOperation {
        return TileMoveOperation(position: targetPosition, direction: direction)
    }

    var reversed: TileMoveOperation {
        return TileMoveOperation(position: targetPosition, direction: direction.opposite)
    }

    init(position: TilePosition, direction: TileMoveDirection) {
        startPosition = position
        self.direction = direction
    }
}
