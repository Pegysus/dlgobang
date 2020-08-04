//
//  UIImageExt.swift
//  DLGoBang
//
//  Created by Max Yeh on 8/3/20.
//  Copyright © 2020 Max Yeh. All rights reserved.
//

import Foundation
import SpriteKit

extension UIImage {
    func withBackground(color: UIColor, opaque: Bool = true) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        
        guard let ctx = UIGraphicsGetCurrentContext(), let image = cgImage else { return self }
        defer { UIGraphicsEndImageContext() }
        
        let rect = CGRect(origin: .zero, size: size)
        ctx.setFillColor(color.cgColor)
        ctx.fill(rect)
        ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height))
        ctx.draw(image, in: rect)
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}
