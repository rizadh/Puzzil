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
    func boardView(_ boardView: BoardView, tileTextAt position: TilePosition) -> String?
    func boardView(_ boardView: BoardView, canPerform moveOperation: TileMoveOperation) -> Bool?
    func boardView(_ boardView: BoardView, didPerform moveOperation: TileMoveOperation)
}
