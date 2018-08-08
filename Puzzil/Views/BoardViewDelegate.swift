//
//  BoardViewDelegate.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-06.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import Foundation

protocol BoardViewDelegate: NSObjectProtocol {
    func newBoard(for boardView: BoardView) -> Board
    func boardDidChange(_ boardView: BoardView)
    func progressDidChange(_ boardView: BoardView)
}
