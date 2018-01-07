//
//  PUZBoardViewDelegate.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-06.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import Foundation

protocol PUZBoardViewDelegate {
    func numberOfRows(in boardView: PUZBoardView) -> Int
    func numberOfColumns(in boardView: PUZBoardView) -> Int
    func boardView(_ boardView: PUZBoardView, textForTileAt position: PUZTilePosition) -> String?
    func boardView(_ boardView: PUZBoardView, canMoveTileAt source: PUZTilePosition, to target: PUZTilePosition) -> Bool?
    func boardView(_ boardView: PUZBoardView, tileWasMovedFrom source: PUZTilePosition, to target: PUZTilePosition)
}
