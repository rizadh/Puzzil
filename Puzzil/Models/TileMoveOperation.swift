//
//  TileMove.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-08.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import Foundation

struct TileMoveOperation {
    let position: TilePosition
    let direction: TileMoveDirection

    var targetPosition: TilePosition {
        return position.moved(direction)
    }

    var nextOperation: TileMoveOperation {
        return TileMoveOperation(position: targetPosition, direction: direction)
    }
}
