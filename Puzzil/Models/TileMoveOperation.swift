//
//  TileMove.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-08.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import Foundation

struct TileMoveOperation: Equatable, Hashable {
    let sourcePosition: TilePosition
    let direction: TileMoveDirection

    var targetPosition: TilePosition {
        return sourcePosition.moved(direction)
    }

    var nextOperation: TileMoveOperation {
        return TileMoveOperation(moving: direction, from: targetPosition)
    }

    var reversed: TileMoveOperation {
        return TileMoveOperation(moving: direction.opposite, from: targetPosition)
    }

    init(moving direction: TileMoveDirection, from position: TilePosition) {
        sourcePosition = position
        self.direction = direction
    }
}
