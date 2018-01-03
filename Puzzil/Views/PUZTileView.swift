//
//  PUZTileView.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-30.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import UIKit

class PUZTileView: UIView {
    private(set) var label: String = ""

    convenience init(label: String) {
        self.init()

        self.label = label

        layer.cornerRadius = 16
    }
}
