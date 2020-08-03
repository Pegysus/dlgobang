//
//  SKSpriteNodeExt.swift
//  DLGoBang
//
//  Created by Max Yeh on 8/1/20.
//  Copyright © 2020 Max Yeh. All rights reserved.
//

import Foundation
import SpriteKit

extension SKSpriteNode {
    func drawBorder(color: UIColor, width: CGFloat) {
        let shapeNode = SKShapeNode(rect: frame)
        shapeNode.fillColor = .clear
        shapeNode.strokeColor = color
        shapeNode.lineWidth = width
        shapeNode.zPosition = -15.0
        addChild(shapeNode)
    }
}
