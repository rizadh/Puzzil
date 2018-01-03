//
//  CGRect+Centered.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-01-01.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import CoreGraphics

extension CGRect {
    init(center: CGPoint, size: CGSize) {
        let originX = center.x - (size.width / 2)
        let originY = center.y - (size.height / 2)
        let origin = CGPoint(x: originX, y: originY)

        self.init(origin: origin, size: size)
    }

    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}
