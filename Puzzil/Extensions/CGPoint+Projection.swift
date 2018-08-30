//
//  CGRect+Center.swift
//  Puzzil
//
//  Created by Rizadh Nizam on 2018-08-12.
//  Copyright © 2018 Rizadh Nizam. All rights reserved.
//

import CoreGraphics
import UIKit.UIScrollView

private let defaultDecelerationRate = UIScrollView.DecelerationRate.normal.rawValue

extension CGPoint {
    private func project(initialVelocity: CGFloat, decelerationRate: CGFloat) -> CGFloat {
        return (initialVelocity / 1000) * decelerationRate / (1 - decelerationRate)
    }

    func projected(by velocity: CGPoint, decelerationRate: CGFloat = defaultDecelerationRate) -> CGPoint {
        return CGPoint(
            x: x + project(initialVelocity: velocity.x, decelerationRate: decelerationRate),
            y: y + project(initialVelocity: velocity.y, decelerationRate: decelerationRate)
        )
    }

    func magnitude(towards direction: TileMoveDirection, lowerBound: CGFloat = -.infinity, upperBound: CGFloat = .infinity) -> CGFloat {
        let rawMagnitude: CGFloat

        switch direction {
        case .left:
            rawMagnitude = -x
        case .right:
            rawMagnitude = x
        case .up:
            rawMagnitude = -y
        case .down:
            rawMagnitude = y
        }

        if rawMagnitude < lowerBound { return lowerBound }
        if rawMagnitude > upperBound { return upperBound }
        return rawMagnitude
    }
}
