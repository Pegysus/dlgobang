//
//  AttackRanking.swift
//  DLGoBang
//
//  Created by Max Yeh on 7/9/20.
//  Copyright © 2020 Max Yeh. All rights reserved.
//

import Foundation

struct AttackRanking {
    static let OpenOne:      Int8 = 2 // currently only 1
    static let ClosedTwo:    Int8 = 0 // currently only C2
    static let OpenTwo:      Int8 = 3 // currently open 2
    static let ClosedThree:  Int8 = 1 // currently C3
    static let OpenThree:    Int8 = 6 // currently O3 (win)
    static let ClosedFour:   Int8 = 7 // currently C4 (win)
    static let OpenFour:     Int8 = 8 // currently O4 (win)
    static let ThreeThree:   Int8 = 5 // if placed, will become 3/3
    static let FourThree:    Int8 = 9 // if placed, will become 4/3
    static let FourFour:     Int8 = 10
    static let FourTwo:      Int8 = 4
}
