//
//  StaticBoardView.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-08-10.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import UIKit

class StaticBoardView: BoardView, BoardViewDelegate {
    var staticBoard: Board {
        didSet {
            reloadBoard()
        }
    }

    init(board: Board) {
        staticBoard = board

        super.init()

        isUserInteractionEnabled = false
        delegate = self
        reloadBoard()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func newBoard(for boardView: BoardView) -> Board {
        return staticBoard
    }

    func boardDidChange(_ boardView: BoardView) {
        fatalError("Static board cannot change")
    }

    func progressDidChange(_ boardView: BoardView, incremental: Bool) {
        fatalError("Static board progress cannot change")
    }
}
