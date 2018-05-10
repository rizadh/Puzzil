//
//  Tile.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-24.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import Foundation

struct Tile {
    var targets: [TilePosition]
    var text: String
}

extension Tile: CustomStringConvertible {
    var description: String {
        return text
    }
}
