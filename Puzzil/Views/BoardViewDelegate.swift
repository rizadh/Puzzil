//
//  BoardViewDelegate.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-06.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import Foundation

protocol BoardViewDelegate {
    func numberOfRows(in boardView: BoardView) -> Int
    func numberOfColumns(in boardView: BoardView) -> Int
    func boardView(_ boardView: BoardView, textForTileAt position: TilePosition) -> String?
    func boardView(_ boardView: BoardView, canMoveTileAt source: TilePosition, to target: TilePosition) -> Bool?
    func boardView(_ boardView: BoardView, tileWasMovedFrom source: TilePosition, to target: TilePosition)
}
