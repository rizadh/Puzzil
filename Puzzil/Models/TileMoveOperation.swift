//
//  TileMove.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-08.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import Foundation

struct TileMoveOperation: Equatable, Hashable {
    let position: TilePosition
    let direction: TileMoveDirection
    let targetPosition: TilePosition

    var nextOperation: TileMoveOperation { return TileMoveOperation(moving: direction, from: targetPosition) }

    init(moving direction: TileMoveDirection, from position: TilePosition) {
        self.position = position
        self.direction = direction
        targetPosition = position.moved(direction)
    }
}
