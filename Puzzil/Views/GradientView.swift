//
//  GradientView
//  Puzzil
//
//  Created by Rizadh Nizam on 2017-12-23.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import Foundation
import UIKit

class GradientView: UIView {
    private let gradient: CAGradientLayer
    private let gradientMask = CAShapeLayer()

    init(from startColor: UIColor, to endColor: UIColor) {
        gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.colors = [startColor.cgColor, endColor.cgColor]
        gradient.mask = gradientMask

        super.init(frame: .zero)

        layer.addSublayer(gradient)
        clipsToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateGradient()
    }

    @objc func updateGradient() {
        guard let position = superview?.convert(frame.origin, to: nil) else {
            return
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradient.frame = UIScreen.main.bounds.offsetBy(dx: -position.x, dy: -position.y)
        gradientMask.frame = bounds.offsetBy(dx: position.x, dy: position.y)
        gradientMask.path = clippingPath(for: bounds)
        gradientMask.fillRule = kCAFillRuleEvenOdd
        CATransaction.commit()
    }

    func clippingPath(for gradientBounds: CGRect) -> CGPath {
        return UIBezierPath(rect: gradientBounds).cgPath
    }
}
