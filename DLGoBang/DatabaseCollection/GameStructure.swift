//
//  GameStructure.swift
//  DLGoBang
//
//  Created by Max Yeh on 7/28/20.
//  Copyright © 2020 Max Yeh. All rights reserved.
//

import Foundation

struct GameDate {
    var timestamp: String
}

struct GameMove {
    var player: String
    var x: Int
    var y: Int
}

struct GameLevel {
    var level: Int
}
