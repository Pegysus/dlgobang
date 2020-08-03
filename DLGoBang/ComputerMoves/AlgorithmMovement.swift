//
//  AlgorithmMovement.swift
//  DLGoBang
//
//  Created by Max Yeh on 7/8/20.
//  Copyright © 2020 Max Yeh. All rights reserved.
//

import Foundation
import SpriteKit

class AlgorithmMovement {
    
    // Global Variables
    
    static let sharedInstance = AlgorithmMovement()
    
    // Properties
    
    let INF = 1000000000
    let dirx = [1, 1, 0, -1, -1, -1, 0, 1]
    let diry = [0, 1, 1, 1, 0, -1, -1, -1]
    let jDirx = [2, 2, 0, -2, -2, -2, 0, 2]
    let jDiry = [0, 2, 2, 2, 0, -2, -2, -2]
    
    var checkGrid = [[Int]](repeating: [Int](repeating: 0, count: 19), count: 19)
    
    var possibleMoves: [CGPoint] = []
    
    var block2O: [CGPoint] = []
    var block3O: [CGPoint] = []
    var block4O: [CGPoint] = []
    var block2C: [CGPoint] = []
    var block3C: [CGPoint] = []
    var block4C: [CGPoint] = []
    var block44: [CGPoint] = []
    var block43: [CGPoint] = []
    var block33: [CGPoint] = []
    
    var attack2O: [CGPoint] = []
    var attack3O: [CGPoint] = []
    var attack4O: [CGPoint] = []
    var attack2C: [CGPoint] = []
    var attack3C: [CGPoint] = []
    var attack4C: [CGPoint] = []
    
    var setupBlock: [CGPoint] = []
    
    // Methods
    
    func computerMakeMove(boardState: [[Int]], whitePlaced: CGPoint, gameStart: Bool, level: Int = 1) -> CGPoint {
        
        reset()
        
        if(gameStart) {
            for i in 0...7 { possibleMoves.append(CGPoint(x: Int(whitePlaced.x) + dirx[i], y: Int(whitePlaced.y) + diry[i])) }
        } else {
            let (otherMoves, otherLoc, otherChain) = checkAllWhitePossibilities(boardState: boardState, level: level)
            resetBlocks()
            
            var largestChain = checkWhiteConsecutive(boardState: boardState, loc: whitePlaced) // initial largest chain, no jumps, no setupt
            var allChains = checkAllWhiteConsecutive(boardState: boardState, loc: whitePlaced, isAdding: false)
//            print("Main loop, chain: \(largestChain)")
//            print("Main loop, chains: \(allChains)")
//            print("Main loop, block2O: \(block2O)")
//            print("Main loop, block3O: \(block3O)")
//            print("Main loop, block4O: \(block4O)")
//            print("Main loop, block2C: \(block2C)")
//            print("Main loop, block3C: \(block3C)")
//            print("Main loop, block4C: \(block4C)")
            
            print(checkWhiteBorders(boardState: boardState, loc: whitePlaced, chain: largestChain))
            // Change chain based on jump threat
//            let (bestBlock, newChain) = addChainJumps(boardState: boardState, loc: whitePlaced, largestChain: largestChain)
//            print("Main loop, newChain: \(newChain)")
//            print("Main loop, nextBlock: \(bestBlock)")
            
            var (bestBlock, newChain) = (CGPoint(x: 0, y: 0), -1)
            if(level >= 2) {
                (bestBlock, newChain) = checkAllWhiteBorders(boardState: boardState, loc: whitePlaced, openings: allChains, curChain: largestChain)
//                print("Main loop, newChain: \(newChain)")
//                print("Main loop, nextBlock: \(bestBlock)")
            }
            
            if(largestChain < newChain) {
                largestChain = newChain
                changeBlocks(chain: largestChain, move: [bestBlock])
                // consec = [twoC, twoO, threeC, threeO, fourC, fourO]
                if(largestChain == Int(PositionRanking.OpenTwo)) {
                    allChains[1] += 1
                } else if(largestChain == Int(PositionRanking.ClosedTwo)) {
                    allChains[0] += 1
                } else if(largestChain == Int(PositionRanking.OpenThree)) {
                    allChains[3] += 1
                } else if(largestChain == Int(PositionRanking.ClosedThree)) {
                    allChains[2] += 1
                } else if(largestChain == Int(PositionRanking.OpenFour)) {
                    allChains[5] += 1
                } else if(largestChain == Int(PositionRanking.ClosedFour)) {
                    allChains[4] += 1
                }
            }
            
            // checks the setup and changes threat based on setup
            var (setupBlock, setupChain) = (CGPoint(x: 0, y: 0), -1)
            if(level == 3) {
                (setupBlock, setupChain) = checkWhiteSetup(boardState: boardState, loc: whitePlaced, threat: largestChain, consec: allChains)
                if(largestChain < Int(PositionRanking.OpenThree)) {
                    largestChain = setupChain
                }
                print("Main loop, chain: \(largestChain)")
            }
            
            var focusPlacement = whitePlaced
            if(largestChain < otherChain) {
                focusPlacement = otherLoc
                largestChain = otherChain
                changeBlocks(chain: largestChain, move: otherMoves)
            }
            print("Main loop, chain: \(largestChain)")
            
            if(largestChain == -1) { // check to see if there is a jump
                let x = Int(focusPlacement.x), y = Int(focusPlacement.y)
                var rightMove: [CGPoint] = []
                // print("finding right move")
                for i in 0...7 {
                    // print("i: \(i)")
                    if(checkBounds(point: CGPoint(x: x+jDirx[i], y: y+jDiry[i])) && checkBounds(point: CGPoint(x: x+dirx[i], y: y+diry[i]))) {
                        // print(boardState[x+jDirx[i]][y+jDiry[i]])
                        // print(boardState[x+dirx[i]][y+diry[i]])
                        if(boardState[x+jDirx[i]][y+jDiry[i]] == 1 && boardState[x+dirx[i]][y+diry[i]] == 0) {
                            let (move, strength) = checkWhiteJump(boardState: boardState, loc: CGPoint(x: x+jDirx[i], y: y+jDiry[i]), dirJump: (dirx[i], diry[i]))
                            if(strength > largestChain) {
                                largestChain = strength
                                rightMove = [move]
                            }
                        }
                    }
                }
                if(largestChain == PositionRanking.ClosedFour) {
                    possibleMoves = rightMove
                } else {
                    possibleMoves = attackOnMove(boardState: boardState, threat: largestChain)  // Just go attack, no setup and no connection (random move)
                    // print("No danger jump, printing largest chain: \(largestChain)")
                    if(possibleMoves.count == 0 && rightMove.count > 0) {
                        possibleMoves = rightMove
                    } else if(possibleMoves.count == 0 && rightMove.count == 0) {
                        // print("Uh oh! Spaghetio!")
                        possibleMoves = [CGPoint(x: 0, y: 0)]
                    }
                }
            } else if(largestChain == PositionRanking.FourFour) {
                print("Main loop, blocking four four")
                possibleMoves = attackOnMove(boardState: boardState, threat: largestChain)
                if(possibleMoves.count == 0) {
                    possibleMoves = [setupBlock]
                }
            } else if(largestChain == PositionRanking.FourThree) {
                print("Main loop, blocking four three")
                possibleMoves = attackOnMove(boardState: boardState, threat: largestChain)
                if(possibleMoves.count == 0) {
                    possibleMoves = [setupBlock]
                }
            } else if(largestChain == PositionRanking.ThreeThree) {
                print("Main loop, blocking three three")
                possibleMoves = attackOnMove(boardState: boardState, threat: largestChain)
                if(possibleMoves.count == 0) {
                    possibleMoves = [setupBlock]
                }
            } else if(largestChain == PositionRanking.OpenFour) {  // Game lost, but still attempt to block
                possibleMoves = attackOnMove(boardState: boardState, threat: largestChain)
                print("Main loop, Open Four: \(possibleMoves)")
                if(possibleMoves.count == 0) {
                    possibleMoves = block4O
                    if(bestBlock != CGPoint(x: 0, y: 0)) {
                        possibleMoves.append(bestBlock)
                    }
                }
            } else if(largestChain == PositionRanking.ClosedFour) { // Prevent game lost by blocking 4 pieces
                possibleMoves = attackOnMove(boardState: boardState, threat: largestChain)
                print("Main loop, Closed Four: \(possibleMoves)")
                if(possibleMoves.count == 0) {
                    possibleMoves = block4C
                    if(bestBlock != CGPoint(x: 0, y: 0)) {
                        possibleMoves.append(bestBlock)
                    }
                }
                
            } else if(largestChain == PositionRanking.OpenThree) { // Open 3, so maybe can look for opportunity to attack if plausible
                possibleMoves = attackOnMove(boardState: boardState, threat: largestChain)
                if(possibleMoves.count == 0) {
                    possibleMoves = block3O
                    if(bestBlock != CGPoint(x: 0, y: 0)) {
                        possibleMoves.append(bestBlock)
                    }
                }
            } else if(largestChain == PositionRanking.ClosedThree) { // Switch to attacking mode here, no setup and no attack from white
                possibleMoves = attackOnMove(boardState: boardState, threat: largestChain)
                if(possibleMoves.count == 0) {
                    possibleMoves = block3C
                    if(bestBlock != CGPoint(x: 0, y: 0)) {
                        possibleMoves.append(bestBlock)
                    }
                }
            } else if(largestChain == PositionRanking.OpenTwo) { // Switch to attacking mode here, no setup and no attack from white
                possibleMoves = attackOnMove(boardState: boardState, threat: largestChain)
                // print("Main loop, Open 2 attacks: \(possibleMoves)")
                // print("Main loop, Open 2 blocks: \(block2O)")
                if(possibleMoves.count == 0) {
                    possibleMoves = block2O
                    if(bestBlock != CGPoint(x: 0, y: 0)) {
                        possibleMoves.append(bestBlock)
                    }
                }
            } else if(largestChain == PositionRanking.ClosedTwo) { // Switch to attacking mode ehre, no setup and no attack from white
                possibleMoves = attackOnMove(boardState: boardState, threat: largestChain)
                if(possibleMoves.count == 0) {
                    possibleMoves = block2C
                    if(bestBlock != CGPoint(x: 0, y: 0)) {
                        possibleMoves.append(bestBlock)
                    }
                }
            }
        }
        
        return possibleMoves.randomElement()!
        
    }
    
    func checkAllWhitePossibilities(boardState: [[Int]], level: Int) -> ([CGPoint], CGPoint, Int) {
        var largestChain = -1, loc = CGPoint(x: 0, y: 0), bestMoves: [CGPoint] = []
        for i in 0...18 {
            for j in 0...18 {
                if(boardState[i][j] == 1) {
                    let curChain = checkWhiteConsecutive(boardState: boardState, loc: CGPoint(x: i, y: j))
                    let allChains = checkAllWhiteConsecutive(boardState: boardState, loc: CGPoint(x: i, y: j), isAdding: false)
                    var (bestBlock, jumpChain) = (CGPoint(x: 0, y: 0), -1)
                    if(level >= 2) {
                        (bestBlock, jumpChain) = checkAllWhiteBorders(boardState: boardState, loc: CGPoint(x: i, y: j), openings: allChains, curChain: curChain)
                    }
                    if(jumpChain > curChain && jumpChain > largestChain) {
                        bestMoves = [bestBlock]
                        largestChain = jumpChain
                        loc = CGPoint(x: i, y: j)
                    } else if(curChain > largestChain) {
                        if(curChain == Int(PositionRanking.OpenTwo)) {
                            bestMoves = block2O
                        } else if(curChain == Int(PositionRanking.OpenThree)) {
                            bestMoves = block3O
                        } else if(curChain == Int(PositionRanking.OpenFour)) {
                            bestMoves = block4O
                        } else if(curChain == Int(PositionRanking.ClosedTwo)) {
                            bestMoves = block2C
                        } else if(curChain == Int(PositionRanking.ClosedThree)) {
                            bestMoves = block3C
                        } else if(curChain == Int(PositionRanking.ClosedFour)) {
                            bestMoves = block4C
                        }
                        largestChain = curChain
                        loc = CGPoint(x: i, y: j)
                    }
                    
                    if(curChain > largestChain) {
                        largestChain = curChain
                        loc = CGPoint(x: i, y: j)
                    }
                    
                    resetBlocks()
                }
            }
        }
        return (bestMoves, loc, largestChain)
    }
    
    func checkWhiteConsecutive(boardState: [[Int]], loc: CGPoint, isAdding: Bool = true) -> Int { // returns the highest-order consecutive chain of enemy
        let twoC = closedTwo(boardState: boardState, curColor: 1, loc: loc, isAdding: isAdding)
        let twoO = openTwo(boardState: boardState, curColor: 1, loc: loc, isAdding: isAdding)
        let threeC = closedThree(boardState: boardState, curColor: 1, loc: loc, isAdding: isAdding)
        let threeO = openThree(boardState: boardState, curColor: 1, loc: loc, isAdding: isAdding)
        let fourC = closedFour(boardState: boardState, curColor: 1, loc: loc, isAdding: isAdding)
        let fourO = openFour(boardState: boardState, curColor: 1, loc: loc, isAdding: isAdding)
        
        if(fourO > 0) { return Int(PositionRanking.OpenFour) }
        if(fourC > 0) { return Int(PositionRanking.ClosedFour) }
        if(threeO > 0) { return Int(PositionRanking.OpenThree) }
        if(twoO > 0) { return Int(PositionRanking.OpenTwo) }
        if(threeC > 0) { return Int(PositionRanking.ClosedThree) }
        if(twoC > 0) { return Int(PositionRanking.ClosedTwo) }
        return -1
    }
    
    func checkAllWhiteConsecutive(boardState: [[Int]], loc: CGPoint, isAdding: Bool = true) -> [Int] {
        var consec: [Int] = []
        
        let twoC = Int(closedTwo(boardState: boardState, curColor: 1, loc: loc, isAdding: isAdding))
        let twoO = Int(openTwo(boardState: boardState, curColor: 1, loc: loc, isAdding: isAdding))
        let threeC = Int(closedThree(boardState: boardState, curColor: 1, loc: loc, isAdding: isAdding))
        let threeO = Int(openThree(boardState: boardState, curColor: 1, loc: loc, isAdding: isAdding))
        let fourC = Int(closedFour(boardState: boardState, curColor: 1, loc: loc, isAdding: isAdding))
        let fourO = Int(openFour(boardState: boardState, curColor: 1, loc: loc, isAdding: isAdding))
        
        consec = [twoC, twoO, threeC, threeO, fourC, fourO]
        
        return consec
    }
    
    func checkAllWhiteBorders(boardState: [[Int]], loc: CGPoint, openings: [Int], curChain: Int) -> (CGPoint, Int) {
        var move = CGPoint(x: 0, y: 0), strength = curChain
        // print("checkAllWhiteBorders, checking white borders: \(loc)")
        if(openings[0] > 0) { // closed two
            let (moveCTwo, strengthCTwo) = addChainJumps(boardState: boardState, loc: loc, largestChain: Int(PositionRanking.ClosedTwo))
            if(strengthCTwo > strength) {
                strength = strengthCTwo
                move = moveCTwo
            }
        }
        if(openings[1] > 0) { // open two
            let (moveOTwo, strengthOTwo) = addChainJumps(boardState: boardState, loc: loc, largestChain: Int(PositionRanking.OpenTwo))
            if(strengthOTwo > strength) {
                strength = strengthOTwo
                move = moveOTwo
            }
        }
        if(openings[2] > 0) { // closed three
            let (moveCThree, strengthCThree) = addChainJumps(boardState: boardState, loc: loc, largestChain: Int(PositionRanking.ClosedThree))
            if(strengthCThree > strength) {
                strength = strengthCThree
                move = moveCThree
            }
        }
        if(openings[3] > 0) { // open three
            let (moveOThree, strengthOThree) = addChainJumps(boardState: boardState, loc: loc, largestChain: Int(PositionRanking.OpenThree))
            if(strengthOThree > strength) {
                strength = strengthOThree
                move = moveOThree
            }
        }
        
        return (move, strength)
    }
    
    func addChainJumps(boardState: [[Int]], loc: CGPoint, largestChain: Int) -> (CGPoint, Int) {
        var chain = largestChain
        let (move, strength) = checkWhiteBorders(boardState: boardState, loc: loc, chain: largestChain)
        let dir = (Int(-(loc.x-move.x)), Int(-(loc.y-move.y)))
        
        if(strength == PositionRanking.OpenOne) {
            if(largestChain <= PositionRanking.OpenOne) {
                if(boardState[Int(loc.x)+dir.0][Int(loc.y)+dir.1] == 0) {
                    // print("open 1 + 1")
                    chain = Int(PositionRanking.OpenTwo)
                } else {
                    // print("closed 1 + 1")
                    chain = Int(PositionRanking.ClosedTwo)
                }
            } else if(largestChain == PositionRanking.ClosedTwo) {
                chain = Int(PositionRanking.ClosedThree)
            } else if(largestChain == PositionRanking.OpenTwo) {
                chain = Int(PositionRanking.OpenThree)
            } else if(largestChain == PositionRanking.ClosedThree || largestChain >= PositionRanking.OpenThree) {
                chain = Int(PositionRanking.ClosedFour)
            }
        } else if(strength == PositionRanking.OpenTwo) {
            if(largestChain <= PositionRanking.OpenOne) {
                if(boardState[Int(loc.x)+dir.0][Int(loc.y)+dir.1] == 0) {
                    // print("open 1 + 2")
                    chain = Int(PositionRanking.OpenThree)
                } else {
                    // print("closed 1 + 2")
                    chain = Int(PositionRanking.ClosedThree)
                }
            } else if(largestChain >= PositionRanking.ClosedTwo) {
                chain = Int(PositionRanking.ClosedFour)
            }
        } else if(strength == PositionRanking.OpenThree) {
            chain = Int(PositionRanking.ClosedFour)
        } else if(strength == PositionRanking.ClosedTwo) {
            if(largestChain <= PositionRanking.OpenOne) {
                if(boardState[Int(loc.x)+dir.0][Int(loc.y)+dir.1] == 0) {
                    // print("open 1 + 2C")
                    chain = Int(PositionRanking.ClosedThree)
                }
            } else if(largestChain >= PositionRanking.ClosedTwo) {
                chain = Int(PositionRanking.ClosedFour)
            }
        } else if(strength == PositionRanking.ClosedThree) {
            chain = Int(PositionRanking.ClosedFour)
        }
        
        return (move, chain)
    }
    
    func checkWhiteJump(boardState: [[Int]], loc: CGPoint, dirJump: (Int, Int), isAdding: Bool = false) -> (CGPoint, Int) {
        let x = Int(loc.x), y = Int(loc.y)
        var move = CGPoint(x: x - dirJump.0, y: y - dirJump.1), strength = -1
        
        let twoO = openTwo(boardState: boardState, curColor: 1, loc: loc, isAdding: isAdding)
        let threeO = openThree(boardState: boardState, curColor: 1, loc: loc, isAdding: isAdding)
        let threeC = closedThree(boardState: boardState, curColor: 1, loc: loc, isAdding: isAdding)
        
        if(threeO > 0 || threeC > 0) {
            strength = Int(PositionRanking.ClosedFour)
        } else if(twoO > 0) {
            strength = Int(PositionRanking.OpenThree)
        } else if(checkBounds(point: CGPoint(x: x+dirJump.0, y: y+dirJump.1)) && boardState[x+dirJump.0][y+dirJump.1] == 0) {
            //print("check for open 2")
            //print("point: (\(x+dirJump.0), \(y+dirJump.0))")
            //print(boardState[x+dirJump.0][y+dirJump.0])
            strength = Int(PositionRanking.OpenTwo)
        }
        
        return (move, strength)
    }
    
    func checkWhiteJump2(boardState: [[Int]], loc: CGPoint, dirJump: (Int, Int), isAdding: Bool = false) -> (CGPoint, Int) {
        var x = Int(loc.x), y = Int(loc.y)
        var move = CGPoint(x: x - dirJump.0, y: y - dirJump.1), strength = -1, length = 0, isBlocked = true
        
        //print("stone: \(boardState[x][y])")
        //print("jump: \(dirJump)")
        
        while(checkBounds(point: CGPoint(x: x, y: y)) && boardState[x][y] == 1) {
            x += dirJump.0
            y += dirJump.1
            length += 1
        }
        
        if(boardState[x][y] == 0) {
            isBlocked = false
        }
        
        if(length >= 3 && !isBlocked) {
            strength = Int(PositionRanking.OpenThree)
        } else if(length >= 3 && isBlocked) {
            strength = Int(PositionRanking.ClosedThree)
        } else if(length == 2 && !isBlocked) {
            strength = Int(PositionRanking.OpenTwo)
        } else if(length == 2 && isBlocked) {
            // print("found closed 2")
            strength = Int(PositionRanking.ClosedTwo)
        } else if(length == 1 && !isBlocked) {
            // print("found open 1")
            strength = Int(PositionRanking.OpenOne)
        }
        
        return (move, strength)
    }
    
    func checkWhiteBorders(boardState: [[Int]], loc: CGPoint, chain: Int, isAdding: Bool = false) -> (CGPoint, Int) {
        var move = CGPoint(x: 0, y: 0), strength = -1
        if(chain == PositionRanking.OpenThree) {
            // print("see open 3")
            for point in block3O {
                let maxi = max(abs(point.x-loc.x), abs(point.y-loc.y))
                let dir = (Int((point.x-loc.x)/(maxi)), Int((point.y-loc.y)/(maxi)))
                let jumpPoint = CGPoint(x: Int(point.x)+dir.0, y: Int(point.y)+dir.1)
                if(checkBounds(point: jumpPoint) && boardState[Int(jumpPoint.x)][Int(jumpPoint.y)] == 1) {
                    let (curMove, curStrength) = checkWhiteJump2(boardState: boardState, loc: jumpPoint, dirJump: dir, isAdding: false)
                    if(curStrength > strength || (curStrength == Int(PositionRanking.ClosedTwo) && strength == Int(PositionRanking.OpenOne))) {
                        move = curMove
                        strength = curStrength
                    }
                }
            }
        } else if(chain == PositionRanking.OpenTwo) {
            for point in block2O {
                let maxi = max(abs(point.x-loc.x), abs(point.y-loc.y))
                let dir = (Int((point.x-loc.x)/(maxi)), Int((point.y-loc.y)/(maxi)))
                let jumpPoint = CGPoint(x: Int(point.x)+dir.0, y: Int(point.y)+dir.1)
                if(checkBounds(point: jumpPoint) && boardState[Int(jumpPoint.x)][Int(jumpPoint.y)] == 1) {
                    // print("found a jump: \(dir1), \(point1)")
                    let (curMove, curStrength) = checkWhiteJump2(boardState: boardState, loc: jumpPoint, dirJump: dir, isAdding: false)
                    if(curStrength > strength || (curStrength == Int(PositionRanking.ClosedTwo) && strength == Int(PositionRanking.OpenOne))) {
                        move = curMove
                        strength = curStrength
                    }
                }
            }
        } else if(chain == PositionRanking.ClosedThree) {
            for point in block3C {
                let maxi = max(abs(point.x-loc.x), abs(point.y-loc.y))
                let dir = (Int((point.x-loc.x)/(maxi)), Int((point.y-loc.y)/(maxi)))
                let jumpPoint = CGPoint(x: Int(point.x)+dir.0, y: Int(point.y)+dir.1)
                if(checkBounds(point: jumpPoint) && boardState[Int(jumpPoint.x)][Int(jumpPoint.y)] == 1) {
                    let (curMove, curStrength) = checkWhiteJump2(boardState: boardState, loc: jumpPoint, dirJump: dir, isAdding: false)
                    if(curStrength > strength || (curStrength == Int(PositionRanking.ClosedTwo) && strength == Int(PositionRanking.OpenOne))) {
                        move = curMove
                        strength = curStrength
                    }
                }
            }
        } else if(chain == PositionRanking.ClosedTwo) {
            // print("see closed 2")
            for point in block2C {
                let maxi = max(abs(point.x-loc.x), abs(point.y-loc.y))
                let dir = (Int((point.x-loc.x)/(maxi)), Int((point.y-loc.y)/(maxi)))
                let jumpPoint = CGPoint(x: Int(point.x)+dir.0, y: Int(point.y)+dir.1)
                if(checkBounds(point: jumpPoint) && boardState[Int(jumpPoint.x)][Int(jumpPoint.y)] == 1) {
                    let (curMove, curStrength) = checkWhiteJump2(boardState: boardState, loc: jumpPoint, dirJump: dir, isAdding: false)
                    if(curStrength > strength || (curStrength == Int(PositionRanking.ClosedTwo) && strength == Int(PositionRanking.OpenOne))) {
                        move = curMove
                        strength = curStrength
                    }
                }
            }
        }
        
        return (move, strength)
    }
    
    func changeBlocks(chain: Int, move: [CGPoint]) {
        if(chain == Int(PositionRanking.OpenTwo)) {
            block2O = move
        } else if(chain == Int(PositionRanking.ClosedTwo)) {
            block2C = move
        } else if(chain == Int(PositionRanking.OpenThree)) {
            block3O = move
        } else if(chain == Int(PositionRanking.ClosedThree)) {
            block3C = move
        } else if(chain == Int(PositionRanking.OpenFour)) {
            block4O = move
        } else if(chain == Int(PositionRanking.ClosedFour)) {
            block4C = move
        }
    }
    
    func checkWhiteSetup(boardState: [[Int]], loc: CGPoint, threat: Int, consec: [Int]) -> (CGPoint, Int) { // returns whether the piece placed setups a strong attack
        var tempState = boardState
        var chain = threat, move = CGPoint(x: 0, y: 0)
        
        if(threat == Int(PositionRanking.OpenThree)) {
            for i in 0...consec[3]-1 {
                let point1 = block3O[i]
                
                tempState[Int(point1.x)][Int(point1.y)] = 1
                let fourfour1 = checkFourAndFour(boardState: tempState, loc: point1)
                if(fourfour1) { move = point1; chain = Int(PositionRanking.FourFour) }
                let fourthree1 = checkFourAndThree(boardState: tempState, loc: point1)
                if(fourthree1) { move = point1; chain = Int(PositionRanking.FourThree) }
                let threethree1 = checkThreeAndThree(boardState: tempState, loc: point1)
                if(threethree1) { move = point1; chain = Int(PositionRanking.ThreeThree) }
                tempState[Int(point1.x)][Int(point1.y)] = 0
            }
        } else if(threat == Int(PositionRanking.ClosedThree) && block3C.count > 0) {
            for i in 0...consec[2]-1 {
                let point = block3C[i]
                
                tempState[Int(point.x)][Int(point.y)] = 1
                let fourfour = checkFourAndFour(boardState: tempState, loc: point)
                if(fourfour) { move = point; chain = Int(PositionRanking.FourFour) }
                let fourthree = checkFourAndThree(boardState: tempState, loc: point)
                if(fourthree) { move = point; chain = Int(PositionRanking.FourThree) }
                let threethree = checkThreeAndThree(boardState: tempState, loc: point)
                if(threethree) { move = point; chain = Int(PositionRanking.ThreeThree) }
                tempState[Int(point.x)][Int(point.y)] = 0
            }
        } else if(threat == Int(PositionRanking.OpenTwo)) {
            for i in 0...consec[1]-1 {
                let point1 = block2O[i]
                
                tempState[Int(point1.x)][Int(point1.y)] = 1
                let fourfour1 = checkFourAndFour(boardState: tempState, loc: point1)
                if(fourfour1) { move = point1; chain = Int(PositionRanking.FourFour) }
                let fourthree1 = checkFourAndThree(boardState: tempState, loc: point1)
                if(fourthree1) { move = point1; chain = Int(PositionRanking.FourThree) }
                let threethree1 = checkThreeAndThree(boardState: tempState, loc: point1)
                if(threethree1) { move = point1; chain = Int(PositionRanking.ThreeThree) }
                tempState[Int(point1.x)][Int(point1.y)] = 0
            }
        } else if(threat == Int(PositionRanking.ClosedTwo)) {
            for i in 0...consec[0]-1 {
                if(i < block2C.count) {
                    let point = block2C[i]
                    
                    tempState[Int(point.x)][Int(point.y)] = 1
                    let fourfour = checkFourAndFour(boardState: tempState, loc: point)
                    if(fourfour) { move = point; chain = Int(PositionRanking.FourFour) }
                    let fourthree = checkFourAndThree(boardState: tempState, loc: point)
                    if(fourthree) { move = point; chain = Int(PositionRanking.FourThree) }
                    let threethree = checkThreeAndThree(boardState: tempState, loc: point)
                    if(threethree) { move = point; chain = Int(PositionRanking.ThreeThree) }
                    tempState[Int(point.x)][Int(point.y)] = 0
                }
            }
        }
        
        // Check directions close by just in case
        for i in 0...7 {
            if(checkBounds(point: CGPoint(x: Int(loc.x)+dirx[i], y: Int(loc.y)+diry[i])) && tempState[Int(loc.x)+dirx[i]][Int(loc.y)+diry[i]] == 0) {
                let point = CGPoint(x: Int(loc.x)+dirx[i], y: Int(loc.y)+diry[i])
                
                tempState[Int(point.x)][Int(point.y)] = 1
                let fourfour = checkFourAndFour(boardState: tempState, loc: point)
                if(fourfour) { move = point; chain = Int(PositionRanking.FourFour) }
                let fourthree = checkFourAndThree(boardState: tempState, loc: point)
                if(fourthree) { move = point; chain = Int(PositionRanking.FourThree) }
                let threethree = checkThreeAndThree(boardState: tempState, loc: point)
                if(threethree) { move = point; chain = Int(PositionRanking.ThreeThree) }
                tempState[Int(point.x)][Int(point.y)] = 0
            }
            if(checkBounds(point: CGPoint(x: Int(loc.x)+jDirx[i], y: Int(loc.y)+jDiry[i])) && tempState[Int(loc.x)+jDirx[i]][Int(loc.y)+jDiry[i]] == 0) {
                let point = CGPoint(x: Int(loc.x)+jDirx[i], y: Int(loc.y)+jDiry[i])
                
                tempState[Int(point.x)][Int(point.y)] = 1
                let fourfour = checkFourAndFour(boardState: tempState, loc: point)
                if(fourfour) { move = point; chain = Int(PositionRanking.FourFour) }
                let fourthree = checkFourAndThree(boardState: tempState, loc: point)
                if(fourthree) { move = point; chain = Int(PositionRanking.FourThree) }
                let threethree = checkThreeAndThree(boardState: tempState, loc: point)
                if(threethree) { move = point; chain = Int(PositionRanking.ThreeThree) }
                tempState[Int(point.x)][Int(point.y)] = 0
            }
        }
        
        return (move, chain) // To be implemented
    }
    
    func checkFourAndFour(boardState: [[Int]], loc: CGPoint) -> Bool {
        // consec = [twoC, twoO, threeC, threeO, fourC, fourO]
        let consec = checkAllWhiteConsecutive(boardState: boardState, loc: loc, isAdding: false)
        if(consec[4]+consec[5] >= 2) {
            return true
        }
        
        return false // To be implemented
    }
    
    func checkFourAndThree(boardState: [[Int]], loc: CGPoint) -> Bool {
        let consec = checkAllWhiteConsecutive(boardState: boardState, loc: loc, isAdding: false)
        if((consec[4] > 0 || consec[5] > 0) && consec[3] > 0) {
            return true
        }
        return false // To be implemented
    }
    
    func checkThreeAndThree(boardState: [[Int]], loc: CGPoint) -> Bool {
        let consec = checkAllWhiteConsecutive(boardState: boardState, loc: loc, isAdding: false)
        if((consec[3] >= 2)) {
            return true
        }
        
        return false // To be implemented
    }
    
    func checkBlackConsecutive(boardState: [[Int]], loc: CGPoint, isAdding: Bool = true) -> [Int] {
        var consec: [Int] = []
        
        let twoC = Int(closedTwo(boardState: boardState, curColor: 2, loc: loc, isAdding: isAdding))
        let twoO = Int(openTwo(boardState: boardState, curColor: 2, loc: loc, isAdding: isAdding))
        let threeC = Int(closedThree(boardState: boardState, curColor: 2, loc: loc, isAdding: isAdding))
        let threeO = Int(openThree(boardState: boardState, curColor: 2, loc: loc, isAdding: isAdding))
        let fourC = Int(closedFour(boardState: boardState, curColor: 2, loc: loc, isAdding: isAdding))
        let fourO = Int(openFour(boardState: boardState, curColor: 2, loc: loc, isAdding: isAdding))
        
        consec = [twoC, twoO, threeC, threeO, fourC, fourO]
        
        return consec
    }
    
    func checkBlackBorders(boardState: [[Int]], loc: CGPoint, chain: Int, isAdding: Bool = false) -> (CGPoint, Int) {
        var move = CGPoint(x: 0, y: 0), strength = -1
        if(chain == Int(AttackRanking.ClosedThree)) {
            for point in attack3C {
                let attackPoint = point
                let x = Int(point.x), y = Int(point.y)
                let maxi = max(abs(x-Int(loc.x)), abs(y-Int(loc.y)))
                let dir = (Int((x-Int(loc.x))/maxi), Int((y-Int(loc.y))/maxi))
                
                let point = CGPoint(x: x+dir.0, y: y+dir.1)
                if(checkBounds(point: point) && boardState[Int(point.x)][Int(point.y)] == 2 && strength < AttackRanking.ClosedFour) {
                    move = attackPoint
                    strength = Int(AttackRanking.ClosedFour)
                }
            }
        } else if(chain == Int(AttackRanking.OpenTwo)) {
            for point in attack2O {
                let attackPoint = point
                let x = Int(point.x), y = Int(point.y)
                let maxi = max(abs(x-Int(loc.x)), abs(y-Int(loc.y)))
                let dir = (Int((x-Int(loc.x))/maxi), Int((y-Int(loc.y))/maxi))
                
                let point = CGPoint(x: x+dir.0, y: y+dir.1)
                if(checkBounds(point: point) && boardState[Int(point.x)][Int(point.y)] == 2) {
                    if(boardState[Int(point.x)+dir.0][Int(point.y)+dir.1] == 2) {
                        move = attackPoint
                        strength = Int(AttackRanking.ClosedFour)
                    } else if (boardState[Int(point.x)+dir.0][Int(point.y)+dir.1] == 0) {
                        move = attackPoint
                        strength = Int(AttackRanking.OpenThree)
                    } else {
                        move = attackPoint
                        strength = Int(AttackRanking.ClosedThree)
                    }
                }
            }
        } else if(chain == Int(AttackRanking.ClosedTwo)) {
            for point in attack2C {
                let attackPoint = point
                let x = Int(point.x), y = Int(point.y)
                let maxi = max(abs(x-Int(loc.x)), abs(y-Int(loc.y)))
                let dir = (Int((x-Int(loc.x))/maxi), Int((y-Int(loc.y))/maxi))
                
                let point = CGPoint(x: x+dir.0, y: y+dir.1)
                if(checkBounds(point: point) && boardState[Int(point.x)][Int(point.y)] == 2) {
                    if(boardState[Int(point.x)+dir.0][Int(point.y)+dir.1] == 2) {
                        move = attackPoint
                        strength = Int(AttackRanking.ClosedFour)
                    } else if (boardState[Int(point.x)+dir.0][Int(point.y)+dir.1] == 0) {
                        move = attackPoint
                        strength = Int(AttackRanking.ClosedThree)
                    }
                }
            }
        } else if(chain == Int(AttackRanking.OpenThree)) {
            for point in attack3O {
                let attackPoint = point
                let x = Int(point.x), y = Int(point.y)
                let maxi = max(abs(x-Int(loc.x)), abs(y-Int(loc.y)))
                let dir = (Int((x-Int(loc.x))/maxi), Int((y-Int(loc.y))/maxi))
                
                let point = CGPoint(x: x+dir.0, y: y+dir.1)
                if(checkBounds(point: point) && boardState[Int(point.x)][Int(point.y)] == 2 && strength < AttackRanking.ClosedFour) {
                    move = attackPoint
                    strength = Int(AttackRanking.ClosedFour)
                }
            }
        } else if(chain == Int(AttackRanking.OpenOne)) {
            for i in 0...7 {
                if(checkBounds(point: CGPoint(x: Int(loc.x)+dirx[i], y: Int(loc.y)+diry[i])) && checkBounds(point: CGPoint(x: Int(loc.x)-dirx[i], y:Int(loc.y)-diry[i]))
                    && boardState[Int(loc.x)+dirx[i]][Int(loc.y)+diry[i]] == 0 && boardState[Int(loc.x)-dirx[i]][Int(loc.y)-diry[i]] != 2) {
                    var point = CGPoint(x: Int(loc.x)+jDirx[i], y: Int(loc.y)+jDiry[i])
                    let pointBehind = CGPoint(x: Int(loc.x)-dirx[i], y: Int(loc.y)-diry[i])
                    var open = false
                    if(checkBounds(point: pointBehind) && boardState[Int(pointBehind.x)][Int(pointBehind.y)] == 0) { open = true }
                    if(checkBounds(point: point) && boardState[Int(point.x)][Int(point.y)] == 2) {
                        var chain = 0, originalPoint = CGPoint(x: Int(loc.x)+dirx[i], y: Int(loc.y)+diry[i])
                        while(boardState[Int(point.x)][Int(point.y)] == 2) {
                            chain += 1
                            point = CGPoint(x: Int(point.x)+dirx[i], y: Int(point.y)+diry[i])
                        }
                        if(chain >= 3) {
                            move = originalPoint
                            strength = Int(AttackRanking.ClosedFour)
                        } else if(chain == 2 && open && boardState[Int(point.x)][Int(point.y)] == 0) {
                            move = originalPoint
                            strength = Int(AttackRanking.OpenThree)
                        }  else if(chain == 1 && open && boardState[Int(point.x)][Int(point.y)] == 0) {
                            move = originalPoint
                            strength = Int(AttackRanking.OpenTwo)
                        } else if(chain == 2 && (open || boardState[Int(point.x)][Int(point.y)] == 0)) {
                            move = originalPoint
                            strength = Int(AttackRanking.ClosedThree)
                        } else if(chain == 1 && (open || boardState[Int(point.x)][Int(point.y)] == 0)) {
                            move = originalPoint
                            strength = Int(AttackRanking.ClosedTwo)
                        }
                    }
                }
            }
        }
        return (move, strength)
    }
    
    func checkAllBlackBorders(openings: [Int], boardState: [[Int]], loc: CGPoint) -> [Int] {
        // consec = [twoC, twoO, threeC, threeO, fourC, fourO]
        var newOpenings = openings
        // print("checkAllBlackBorders, Checking Black Borders: \(loc)")
        if(openings[0] > 0) { // currently closed two
            let (moveCTwo, strengthCTwo) = checkBlackBorders(boardState: boardState, loc: loc, chain: Int(AttackRanking.ClosedTwo))
            changeAttackingMoves(strength: strengthCTwo, move: moveCTwo)
            newOpenings = changeOpenings(openings: newOpenings, strength: strengthCTwo)
            // print("checkAllBlackBorders, C2: (\(moveCTwo), \(strengthCTwo))")
        }
        if(openings[1] > 0) { // currently open two
            let (moveOTwo, strengthOTwo) = checkBlackBorders(boardState: boardState, loc: loc, chain: Int(AttackRanking.OpenTwo))
            changeAttackingMoves(strength: strengthOTwo, move: moveOTwo)
            newOpenings = changeOpenings(openings: newOpenings, strength: strengthOTwo)
            // print("checkAllBlackBorders, O2: (\(moveOTwo), \(strengthOTwo))")
        }
        if(openings[2] > 0) { // currently closed three
            let (moveCThree, strengthCThree) = checkBlackBorders(boardState: boardState, loc: loc, chain: Int(AttackRanking.ClosedThree))
            changeAttackingMoves(strength: strengthCThree, move: moveCThree)
            newOpenings = changeOpenings(openings: newOpenings, strength: strengthCThree)
            // print("checkAllBlackBorders, C3: (\(moveCThree), \(strengthCThree))")
        }
        if(openings[3] > 0) { // currently open three
            let (moveOThree, strengthOThree) = checkBlackBorders(boardState: boardState, loc: loc, chain: Int(AttackRanking.OpenThree))
            changeAttackingMoves(strength: strengthOThree, move: moveOThree)
            newOpenings = changeOpenings(openings: newOpenings, strength: strengthOThree)
            // print("checkAllBlackBorders, O3: (\(moveOThree), \(strengthOThree))")
        }
        let (moveOne, strengthOne) = checkBlackBorders(boardState: boardState, loc: loc, chain: Int(AttackRanking.OpenOne))
        changeAttackingMoves(strength: strengthOne, move: moveOne)
        newOpenings = changeOpenings(openings: newOpenings, strength: strengthOne)
        // print("checkAllBlackBorders, 1: (\(moveOne), \(strengthOne))")
        
        return newOpenings
    }
    
    func changeAttackingMoves(strength: Int, move: CGPoint) {
        if(strength == Int(AttackRanking.ClosedTwo)) {
            attack2C.append(move)
        } else if(strength == Int(AttackRanking.OpenTwo)) {
            attack2O.append(move)
        } else if(strength == Int(AttackRanking.ClosedThree)) {
            attack3C.append(move)
        } else if(strength == Int(AttackRanking.OpenThree)) {
            attack3O.append(move)
        } else if(strength == Int(AttackRanking.ClosedFour)) {
            attack4C.append(move)
        } else if(strength == Int(AttackRanking.OpenFour)) {
            attack4O.append(move)
        }
    }
    
    func changeOpenings(openings: [Int], strength: Int) -> [Int] {
        var newOpenings = openings
        if(strength == AttackRanking.ClosedTwo) {
            newOpenings[0] += 1
        } else if(strength == AttackRanking.OpenTwo) {
            newOpenings[1] += 1
        } else if(strength == AttackRanking.ClosedThree) {
            newOpenings[2] += 1
        } else if(strength == AttackRanking.OpenThree) {
            newOpenings[3] += 1
        } else if(strength == AttackRanking.ClosedFour) {
            newOpenings[4] += 1
        } else if(strength == AttackRanking.OpenFour) {
            newOpenings[5] += 1
        }
        
        return newOpenings
    }
    
    func attackOnMove(boardState: [[Int]], threat: Int) -> [CGPoint] {
        var moves: [CGPoint] = []
        var tempState = boardState
        if(threat == Int(PositionRanking.ClosedFour) || threat == Int(PositionRanking.OpenFour) || threat == Int(PositionRanking.FourFour) || threat == Int(PositionRanking.FourThree) || threat == Int(PositionRanking.ThreeThree)) {
            // print("attackOnMove, opponent made 4")
            var bestAttack = -1
            
            for i in 0...18 {
                for j in 0...18 {
                    if(boardState[i][j] == 2) {
                        var openings = checkBlackConsecutive(boardState: boardState, loc: CGPoint(x: i, y: j))
                        openings = checkAllBlackBorders(openings: openings, boardState: boardState, loc: CGPoint(x: i, y: j))
                        if(openings[5] > 0 && bestAttack < Int(AttackRanking.OpenFour)) {
                            // print("attackOnMove, found OpenFour, (\(i), \(j))")
                            moves = attack4O
                            // print("attackOnMove, moves: \(moves)")
                            bestAttack = Int(AttackRanking.OpenFour)
                        }
                        if(openings[4] > 0 && bestAttack < Int(AttackRanking.ClosedFour)) {
                            // print("attackOnMove, found ClosedFour")
                            moves = attack4C
                            bestAttack = Int(AttackRanking.ClosedFour)
                        }
                    }
                    
                    resetAttacks()
                }
            }
        } else if(threat == Int(PositionRanking.OpenThree)) {
            // print("attackOnMove, opponent made open 3")
            var bestAttack = -1
            
            for i in 0...18 {
                for j in 0...18 {
                    if(boardState[i][j] == 2) {
                        var openings = checkBlackConsecutive(boardState: boardState, loc: CGPoint(x: i, y: j))
                        openings = checkAllBlackBorders(openings: openings, boardState: boardState, loc: CGPoint(x: i, y: j))
                        // print("attackOnMove, openings against open 3: \(openings)")
                        if(openings[5] > 0 && bestAttack < Int(AttackRanking.OpenFour)) {
                            moves = attack4O
                            bestAttack = Int(AttackRanking.OpenFour)
                        }
                        if(openings[4] > 0 && bestAttack < Int(AttackRanking.ClosedFour)) {
                            moves = attack4C
                            bestAttack = Int(AttackRanking.ClosedFour)
                        }
                        if(openings[3] > 0 && bestAttack < Int(AttackRanking.OpenThree)) {
                            moves = attack3O
                            bestAttack = Int(AttackRanking.OpenThree)
                        }
                        if(openings[2] > 0 && bestAttack < Int(AttackRanking.ClosedThree)) {
                            if(attack3C.count > 0) {
                                tempState[Int(attack3C[0].x)][Int(attack3C[0].y)] = 2
                                
                                let chain = checkBlackConsecutive(boardState: boardState, loc: CGPoint(x: attack3C[0].x, y: attack3C[0].y), isAdding: false)
//                                if(chain[1] > 0) {
//                                    moves = attack3C
//                                    bestAttack = Int(AttackRanking.FourTwo)
//                                }
                                if(chain[3] > 0) {
                                    moves = attack3C
                                    bestAttack = Int(AttackRanking.FourThree)
                                }
                                if(chain[5] > 0 || chain[4] > 1) {
                                    moves = attack3C
                                    bestAttack = Int(AttackRanking.FourFour)
                                }
                                
                                tempState[Int(attack3C[0].x)][Int(attack3C[0].y)] = 0
                            }
                        }
                    }
                    
                    resetAttacks()
                }
            }
        } else if(threat == Int(PositionRanking.OpenTwo)) {
            // print("attackOnMove, opponent made open 2")
            var bestAttack = -1
            
            for i in 0...18 {
                for j in 0...18 {
                    if(boardState[i][j] == 2) {
                        var openings = checkBlackConsecutive(boardState: boardState, loc: CGPoint(x: i, y: j))
                        openings = checkAllBlackBorders(openings: openings, boardState: boardState, loc: CGPoint(x: i, y: j))
                        if(openings[5] > 0 && bestAttack < Int(AttackRanking.OpenFour)) {
                            moves = attack4O
                            bestAttack = Int(AttackRanking.OpenFour)
                        }
                        if(openings[4] > 0 && bestAttack < Int(AttackRanking.ClosedFour)) {
                            moves = attack4C
                            bestAttack = Int(AttackRanking.ClosedFour)
                        }
                        if(openings[3] > 0 && bestAttack < Int(AttackRanking.OpenThree)) {
                            moves = attack3O
                            bestAttack = Int(AttackRanking.OpenThree)
                        }
                        if(openings[1] > 0 && bestAttack < Int(AttackRanking.OpenTwo)) {
                            moves = attack2O
                            bestAttack = Int(AttackRanking.OpenTwo)
                        }
                        if(openings[2] > 0 && bestAttack < Int(AttackRanking.ClosedThree)) {
                            if(attack3C.count > 0) {
                                tempState[Int(attack3C[0].x)][Int(attack3C[0].y)] = 2
                                
                                let chain = checkBlackConsecutive(boardState: boardState, loc: CGPoint(x: attack3C[0].x, y: attack3C[0].y), isAdding: false)
                                if(chain[1] > 0) {
                                    moves = attack3C
                                    bestAttack = Int(AttackRanking.FourTwo)
                                }
                                if(chain[3] > 0) {
                                    moves = attack3C
                                    bestAttack = Int(AttackRanking.FourThree)
                                }
                                if(chain[5] > 0 || chain[4] > 1) {
                                    moves = attack3C
                                    bestAttack = Int(AttackRanking.FourFour)
                                }
                                
                                tempState[Int(attack3C[0].x)][Int(attack3C[0].y)] = 0
                            }
                        }
                    }
                    
                    resetAttacks()
                }
            }
        } else {
            // print("no pressure")
            var bestAttack = -1
            
            for i in 0...18 {
                for j in 0...18 {
                    if(boardState[i][j] == 2) {
                        var openings = checkBlackConsecutive(boardState: boardState, loc: CGPoint(x: i, y: j))
                        openings = checkAllBlackBorders(openings: openings, boardState: boardState, loc: CGPoint(x: i, y: j))
                        // print("x: \(i), y: \(j)")
                        // print("openings: \(openings)")
                        if(openings[5] > 0 && bestAttack < Int(AttackRanking.OpenFour)) {
                            moves = attack4O
                            bestAttack = Int(AttackRanking.OpenFour)
                        }
                        if(openings[4] > 0 && bestAttack < Int(AttackRanking.ClosedFour)) {
                            moves = attack4C
                            bestAttack = Int(AttackRanking.ClosedFour)
                        }
                        if(openings[3] > 0 && bestAttack < Int(AttackRanking.OpenThree)) {
                            moves = attack3O
                            bestAttack = Int(AttackRanking.OpenThree)
                        }
                        if(openings[2] > 0 && bestAttack < Int(AttackRanking.ClosedThree)) {
                            if(attack3C.count > 0) {
                                tempState[Int(attack3C[0].x)][Int(attack3C[0].y)] = 2
                               
                                let chain = checkBlackConsecutive(boardState: boardState, loc: CGPoint(x: attack3C[0].x, y: attack3C[0].y), isAdding: false)
                                if(chain[3] > 0 || chain[4] > 1 || chain[5] > 0) {
                                    moves = attack3C
                                    bestAttack = Int(AttackRanking.FourThree)
                                } else {
                                    moves = attack3C
                                    bestAttack = Int(AttackRanking.ClosedThree)
                                }
                                
                                tempState[Int(attack3C[0].x)][Int(attack3C[0].y)] = 0
                            }
                        }
                        if(openings[1] > 0 && bestAttack < Int(AttackRanking.OpenTwo)) {
                           moves = attack2O
                           bestAttack = Int(AttackRanking.OpenTwo)
                        }
                        if(bestAttack < Int(AttackRanking.OpenOne)){
                            // print("x: \(i), y: \(j)")
                            for k in 0...7 {
                                // print("checking: x: \(i+dirx[k]), y: \(j+diry[k])")
                                if(checkBounds(point: CGPoint(x: i+dirx[k], y: j+diry[k])) && boardState[i+dirx[k]][j+diry[k]] == 0) {
                                    tempState[i+dirx[k]][j+diry[k]] = 2
                                    
                                    let chain = checkBlackConsecutive(boardState: tempState, loc: CGPoint(x: i+dirx[k], y: j+diry[k]), isAdding: false)
                                    // print("chain: \(chain)")
                                    if(chain[1] > 0) {
                                        moves.append(CGPoint(x: i+dirx[k], y: j+diry[k]))
                                        // print("good: \(moves)")
                                    }
                                    
                                    tempState[i+dirx[k]][j+diry[k]] = 0
                                }
                                   
                                resetAttacks()
                            }
                        }
                        if(openings[0] > 0 && bestAttack < Int(AttackRanking.ClosedTwo)) {
                            moves = attack2C
                            bestAttack = Int(AttackRanking.ClosedTwo)
                        }
                    }
                    
                    resetAttacks()
                }
            }
        }
        return moves
    }
    
    func resetAttacks() {
        attack2O.removeAll()
        attack3O.removeAll()
        attack4O.removeAll()
        attack2C.removeAll()
        attack3C.removeAll()
        attack4C.removeAll()
    }
    
    func resetBlocks() {
        block2O.removeAll()
        block3O.removeAll()
        block4O.removeAll()
        block2C.removeAll()
        block3C.removeAll()
        block4C.removeAll()
    }
    
    func reset() {
        possibleMoves.removeAll()
        resetBlocks()
        resetAttacks()
        checkGrid = [[Int]](repeating: [Int](repeating: 0, count: 19), count: 19)
    }
    
}

extension AlgorithmMovement {
    
    // Configs/Repetitive Methods
    
    func openTwo(boardState: [[Int]], curColor: Int, loc: CGPoint, isAdding: Bool = true) -> Double {
        let x = Int(loc.x), y = Int(loc.y)
        let total = consecutiveOpen(num: 2, boardState: boardState, point: CGPoint(x: x, y: y), curColor: curColor, isAdding: isAdding)
        return total
    }

    func closedTwo(boardState: [[Int]], curColor: Int, loc: CGPoint, isAdding: Bool = true) -> Double {
        let x = Int(loc.x), y = Int(loc.y)
        let total = consecutiveClosed(num: 2, boardState: boardState, point: CGPoint(x: x, y: y), curColor: curColor, isAdding: isAdding)
        return total
    }

    func openThree(boardState: [[Int]], curColor: Int, loc: CGPoint, isAdding: Bool = true) -> Double {
        let x = Int(loc.x), y = Int(loc.y)
        let total = consecutiveOpen(num: 3, boardState: boardState, point: CGPoint(x: x, y: y), curColor: curColor, isAdding: isAdding)
        return total
    }

    func closedThree(boardState: [[Int]], curColor: Int, loc: CGPoint, isAdding: Bool = true) -> Double {
        let x = Int(loc.x), y = Int(loc.y)
        let total = consecutiveClosed(num: 3, boardState: boardState, point: CGPoint(x: x, y: y), curColor: curColor, isAdding: isAdding)
        return total
    }

    func openFour(boardState: [[Int]], curColor: Int, loc: CGPoint, isAdding: Bool = true) -> Double {
        let x = Int(loc.x), y = Int(loc.y)
        let total = consecutiveOpen(num: 4, boardState: boardState, point: CGPoint(x: x, y: y), curColor: curColor, isAdding: isAdding)
        return total
    }

    func closedFour(boardState: [[Int]], curColor: Int, loc: CGPoint, isAdding: Bool = true) -> Double {
        let x = Int(loc.x), y = Int(loc.y)
        let total = consecutiveClosed(num: 4, boardState: boardState, point: CGPoint(x: x, y: y), curColor: curColor, isAdding: isAdding)
        return total
    }
    
    func checkBounds(point: CGPoint) -> Bool {
        if(point.x < 0 || point.x > 18 || point.y < 0 || point.y > 18) {
            return false
        }
        return true
    }

    func isNotBlocked(boardState: [[Int]], point: CGPoint, curColor: Int) -> Bool {
        let x = Int(point.x), y = Int(point.y)
        if(!checkBounds(point: point)) { return false }
        if(boardState[x][y] != 0 && boardState[x][y] != curColor) { return false }
        return true
    }
    
    func isNotBlockedNoCol(boardState: [[Int]], point: CGPoint) -> Bool {
        let x = Int(point.x), y = Int(point.y)
        if(!checkBounds(point: point)) { return false }
        if(boardState[x][y] != 0) { return false }
        return true
    }
    
    func consecutiveOpen(num: Int, boardState: [[Int]], point: CGPoint, curColor: Int, isAdding: Bool = true) -> Double {
        var total = 0.0
        let x = Int(point.x), y = Int(point.y)

        // horizontal
        var boundOneX = 0, boundTwoX = 0, boundOneY = 0, boundTwoY = 0
        var consecutiveOne = true, consecutiveTwo = true, consec = 1
        for i in 1...(num-1) {
            if(x+i <= 18 && boardState[x+i][y] == curColor && consecutiveOne) { consec += 1; boundOneX = x+i+1; boundOneY = y }
            if(x-i >= 0 && boardState[x-i][y] == curColor && consecutiveTwo) { consec += 1; boundTwoX = x-i-1; boundTwoY = y }
            if(x+i <= 18 && boardState[x+i][y] != curColor && consecutiveOne) { consecutiveOne = false; boundOneX = x+i; boundOneY = y }
            if(x-i >= 0 && boardState[x-i][y] != curColor && consecutiveTwo) { consecutiveTwo = false; boundTwoX = x-i; boundTwoY = y }
        }
        if(isNotBlockedNoCol(boardState: boardState, point: CGPoint(x: boundOneX, y: boundOneY)) &&
            isNotBlockedNoCol(boardState: boardState, point: CGPoint(x: boundTwoX, y: boundTwoY)) && consec == num) {
            total += 1
            if(num == 2 && curColor == 1 && isAdding) { addOpenTwoBlock(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 3 && curColor == 1 && isAdding) { addOpenThreeBlock(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 4 && curColor == 1 && isAdding) { addOpenFourBlock(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            
            if(num == 2 && curColor == 2 && isAdding) { addOpenTwoAttack(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 3 && curColor == 2 && isAdding) { addOpenThreeAttack(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 4 && curColor == 2 && isAdding) { addOpenFourAttack(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
        }

        // vertical
        boundOneX = 0; boundTwoX = 0; boundOneY = 0; boundTwoY = 0
        consecutiveOne = true; consecutiveTwo = true; consec = 1
        for i in 1...(num-1) {
            if(y+i <= 18 && boardState[x][y+i] == curColor && consecutiveOne) { consec += 1; boundOneX = x; boundOneY = y+i+1 }
            if(y-i >= 0 && boardState[x][y-i] == curColor && consecutiveTwo) { consec += 1; boundTwoX = x; boundTwoY = y-i-1 }
            if(y+i <= 18 && boardState[x][y+i] != curColor && consecutiveOne) { consecutiveOne = false; boundOneX = x; boundOneY = y+i }
            if(y-i >= 0 && boardState[x][y-i] != curColor && consecutiveTwo) { consecutiveTwo = false; boundTwoX = x; boundTwoY = y-i }
        }
        if(isNotBlockedNoCol(boardState: boardState, point: CGPoint(x: boundOneX, y: boundOneY)) &&
            isNotBlockedNoCol(boardState: boardState, point: CGPoint(x: boundTwoX, y: boundTwoY)) && consec == num) {
            total += 1
            if(num == 2 && curColor == 1 && isAdding) { addOpenTwoBlock(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 3 && curColor == 1 && isAdding) { addOpenThreeBlock(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 4 && curColor == 1 && isAdding) { addOpenFourBlock(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            
            if(num == 2 && curColor == 2 && isAdding) { addOpenTwoAttack(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 3 && curColor == 2 && isAdding) { addOpenThreeAttack(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 4 && curColor == 2 && isAdding) { addOpenFourAttack(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
        }

        // diagonal1
        boundOneX = 0; boundTwoX = 0; boundOneY = 0; boundTwoY = 0
        consecutiveOne = true; consecutiveTwo = true; consec = 1
        for i in 1...(num-1) {
            if(x+i <= 18 && y+i <= 18 && boardState[x+i][y+i] == curColor && consecutiveOne) { consec += 1; boundOneX = x+i+1; boundOneY = y+i+1 }
            if(x-i >= 0 && y-i >= 0 && boardState[x-i][y-i] == curColor && consecutiveTwo) { consec += 1; boundTwoX = x-i-1; boundTwoY = y-i-1 }
            if(x+i <= 18 && y+i <= 18 && boardState[x+i][y+i] != curColor && consecutiveOne) { consecutiveOne = false; boundOneX = x+i; boundOneY = y+i }
            if(x-i >= 0 && y-i >= 0 && boardState[x-i][y-i] != curColor && consecutiveTwo) { consecutiveTwo = false; boundTwoX = x-i; boundTwoY = y-i }
        }
        if(isNotBlockedNoCol(boardState: boardState, point: CGPoint(x: boundOneX, y: boundOneY)) &&
            isNotBlockedNoCol(boardState: boardState, point: CGPoint(x: boundTwoX, y: boundTwoY)) && consec == num) {
            total += 1
            if(num == 2 && curColor == 1 && isAdding) { addOpenTwoBlock(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 3 && curColor == 1 && isAdding) { addOpenThreeBlock(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 4 && curColor == 1 && isAdding) { addOpenFourBlock(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            
            if(num == 2 && curColor == 2 && isAdding) { addOpenTwoAttack(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 3 && curColor == 2 && isAdding) { addOpenThreeAttack(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 4 && curColor == 2 && isAdding) { addOpenFourAttack(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
        }

        // diagonal2
        boundOneX = 0; boundTwoX = 0; boundOneY = 0; boundTwoY = 0
        consecutiveOne = true; consecutiveTwo = true; consec = 1
        for i in 1...(num-1) {
            if(x+i <= 18 && y-i >= 0 && boardState[x+i][y-i] == curColor && consecutiveOne) { consec += 1; boundOneX = x+i+1; boundOneY = y-i-1 }
            if(x-i >= 0 && y+i <= 18 && boardState[x-i][y+i] == curColor && consecutiveTwo) { consec += 1; boundTwoX = x-i-1; boundTwoY = y+i+1 }
            if(x+i <= 18 && y-i >= 0 && boardState[x+i][y-i] != curColor && consecutiveOne) { consecutiveOne = false; boundOneX = x+i; boundOneY = y-i }
            if(x-i >= 0 && y+i <= 18 && boardState[x-i][y+i] != curColor && consecutiveTwo) { consecutiveTwo = false; boundTwoX = x-i; boundTwoY = y+i }
        }
        if(isNotBlockedNoCol(boardState: boardState, point: CGPoint(x: boundOneX, y: boundOneY)) &&
            isNotBlockedNoCol(boardState: boardState, point: CGPoint(x: boundTwoX, y: boundTwoY)) && consec == num) {
            total += 1
            if(num == 2 && curColor == 1 && isAdding) { addOpenTwoBlock(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 3 && curColor == 1 && isAdding) { addOpenThreeBlock(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 4 && curColor == 1 && isAdding) { addOpenFourBlock(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            
            if(num == 2 && curColor == 2 && isAdding) { addOpenTwoAttack(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 3 && curColor == 2 && isAdding) { addOpenThreeAttack(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 4 && curColor == 2 && isAdding) { addOpenFourAttack(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
        }

        return total
    }

    func consecutiveClosed(num: Int, boardState: [[Int]], point: CGPoint, curColor: Int, isAdding: Bool = true) -> Double {
        var total = 0.0
        let x = Int(point.x), y = Int(point.y)

        // horizontal
        var boundOneX = 0, boundTwoX = 0, boundOneY = 0, boundTwoY = 0
        var consecutiveOne = true, consecutiveTwo = true, consec = 1
        for i in 1...(num-1) {
            if(x+i <= 18 && boardState[x+i][y] == curColor && consecutiveOne) { consec += 1; boundOneX = x+i+1; boundOneY = y }
            if(x-i >= 0 && boardState[x-i][y] == curColor && consecutiveTwo) { consec += 1; boundTwoX = x-i-1; boundTwoY = y }
            if(x+i <= 18 && boardState[x+i][y] != curColor && consecutiveOne) { consecutiveOne = false; boundOneX = x+i; boundOneY = y }
            if(x-i >= 0 && boardState[x-i][y] != curColor && consecutiveTwo) { consecutiveTwo = false; boundTwoX = x-i; boundTwoY = y }
        }
        if(((isNotBlocked(boardState: boardState, point: CGPoint(x: boundOneX, y: boundOneY), curColor: curColor) ||
            isNotBlocked(boardState: boardState, point: CGPoint(x: boundTwoX, y: boundTwoY), curColor: curColor)) &&
            !(isNotBlocked(boardState: boardState, point: CGPoint(x: boundOneX, y: boundOneY), curColor: curColor) &&
            isNotBlocked(boardState: boardState, point: CGPoint(x: boundTwoX, y: boundTwoY), curColor: curColor))) && consec == num) {
            total += 1
            if(num == 2 && curColor == 1 && isAdding) { addClosedTwoBlock(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 3 && curColor == 1 && isAdding) { addClosedThreeBlock(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 4 && curColor == 1 && isAdding) { addClosedFourBlock(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            
            if(num == 2 && curColor == 2 && isAdding) { addClosedTwoAttack(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 3 && curColor == 2 && isAdding) { addClosedThreeAttack(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 4 && curColor == 2 && isAdding) { addClosedFourAttack(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
        }

        // vertical
        boundOneX = 0; boundTwoX = 0; boundOneY = 0; boundTwoY = 0
        consecutiveOne = true; consecutiveTwo = true; consec = 1
        for i in 1...(num-1) {
            if(y+i <= 18 && boardState[x][y+i] == curColor && consecutiveOne) { consec += 1; boundOneX = x; boundOneY = y+i+1 }
            if(y-i >= 0 && boardState[x][y-i] == curColor && consecutiveTwo) { consec += 1; boundTwoX = x; boundTwoY = y-i-1 }
            if(y+i <= 18 && boardState[x][y+i] != curColor && consecutiveOne) { consecutiveOne = false; boundOneX = x; boundOneY = y+i }
            if(y-i >= 0 && boardState[x][y-i] != curColor && consecutiveTwo) { consecutiveTwo = false; boundTwoX = x; boundTwoY = y-i }
        }
        if(((isNotBlocked(boardState: boardState, point: CGPoint(x: boundOneX, y: boundOneY), curColor: curColor) ||
            isNotBlocked(boardState: boardState, point: CGPoint(x: boundTwoX, y: boundTwoY), curColor: curColor)) &&
            !(isNotBlocked(boardState: boardState, point: CGPoint(x: boundOneX, y: boundOneY), curColor: curColor) &&
            isNotBlocked(boardState: boardState, point: CGPoint(x: boundTwoX, y: boundTwoY), curColor: curColor))) && consec == num) {
            total += 1
            if(num == 2 && curColor == 1 && isAdding) { addClosedTwoBlock(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 3 && curColor == 1 && isAdding) { addClosedThreeBlock(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 4 && curColor == 1 && isAdding) { addClosedFourBlock(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            
            if(num == 2 && curColor == 2 && isAdding) { addClosedTwoAttack(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 3 && curColor == 2 && isAdding) { addClosedThreeAttack(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 4 && curColor == 2 && isAdding) { addClosedFourAttack(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
        }

        // diagonal1
        boundOneX = 0; boundTwoX = 0; boundOneY = 0; boundTwoY = 0
        consecutiveOne = true; consecutiveTwo = true; consec = 1
        for i in 1...(num-1) {
            if(x+i <= 18 && y+i <= 18 && boardState[x+i][y+i] == curColor && consecutiveOne) { consec += 1; boundOneX = x+i+1; boundOneY = y+i+1 }
            if(x-i >= 0 && y-i >= 0 && boardState[x-i][y-i] == curColor && consecutiveTwo) { consec += 1; boundTwoX = x-i-1; boundTwoY = y-i-1 }
            if(x+i <= 18 && y+i <= 18 && boardState[x+i][y+i] != curColor && consecutiveOne) { consecutiveOne = false; boundOneX = x+i; boundOneY = y+i }
            if(x-i >= 0 && y-i >= 0 && boardState[x-i][y-i] != curColor && consecutiveTwo) { consecutiveTwo = false; boundTwoX = x-i; boundTwoY = y-i }
        }
       if(((isNotBlocked(boardState: boardState, point: CGPoint(x: boundOneX, y: boundOneY), curColor: curColor) ||
            isNotBlocked(boardState: boardState, point: CGPoint(x: boundTwoX, y: boundTwoY), curColor: curColor)) &&
            !(isNotBlocked(boardState: boardState, point: CGPoint(x: boundOneX, y: boundOneY), curColor: curColor) &&
            isNotBlocked(boardState: boardState, point: CGPoint(x: boundTwoX, y: boundTwoY), curColor: curColor))) && consec == num) {
            total += 1
            if(num == 2 && curColor == 1 && isAdding) { addClosedTwoBlock(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 3 && curColor == 1 && isAdding) { addClosedThreeBlock(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 4 && curColor == 1 && isAdding) { addClosedFourBlock(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
        
            if(num == 2 && curColor == 2 && isAdding) { addClosedTwoAttack(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 3 && curColor == 2 && isAdding) { addClosedThreeAttack(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 4 && curColor == 2 && isAdding) { addClosedFourAttack(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
        }

        // diagonal2
        boundOneX = 0; boundTwoX = 0; boundOneY = 0; boundTwoY = 0
        consecutiveOne = true; consecutiveTwo = true; consec = 1
        for i in 1...(num-1) {
            if(x+i <= 18 && y-i >= 0 && boardState[x+i][y-i] == curColor && consecutiveOne) { consec += 1; boundOneX = x+i+1; boundOneY = y-i-1 }
            if(x-i >= 0 && y+i <= 18 && boardState[x-i][y+i] == curColor && consecutiveTwo) { consec += 1; boundTwoX = x-i-1; boundTwoY = y+i+1 }
            if(x+i <= 18 && y-i >= 0 && boardState[x+i][y-i] != curColor && consecutiveOne) { consecutiveOne = false; boundOneX = x+i; boundOneY = y-i }
            if(x-i >= 0 && y+i <= 18 && boardState[x-i][y+i] != curColor && consecutiveTwo) { consecutiveTwo = false; boundTwoX = x-i; boundTwoY = y+i }
        }
        if(((isNotBlocked(boardState: boardState, point: CGPoint(x: boundOneX, y: boundOneY), curColor: curColor) ||
            isNotBlocked(boardState: boardState, point: CGPoint(x: boundTwoX, y: boundTwoY), curColor: curColor)) &&
            !(isNotBlocked(boardState: boardState, point: CGPoint(x: boundOneX, y: boundOneY), curColor: curColor) &&
            isNotBlocked(boardState: boardState, point: CGPoint(x: boundTwoX, y: boundTwoY), curColor: curColor))) && consec == num) {
            total += 1
            if(num == 2 && curColor == 1 && isAdding) { addClosedTwoBlock(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 3 && curColor == 1 && isAdding) { addClosedThreeBlock(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 4 && curColor == 1 && isAdding) { addClosedFourBlock(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            
            if(num == 2 && curColor == 2 && isAdding) { addClosedTwoAttack(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 3 && curColor == 2 && isAdding) { addClosedThreeAttack(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
            else if(num == 4 && curColor == 2 && isAdding) { addClosedFourAttack(boardState: boardState, boundOne: CGPoint(x: CGFloat(boundOneX), y: CGFloat(boundOneY)),
                                            boundTwo: CGPoint(x: CGFloat(boundTwoX), y: CGFloat(boundTwoY))) }
        }

        return total
    }
    
    func addOpenTwoBlock(boardState: [[Int]], boundOne: CGPoint, boundTwo: CGPoint) {
        if(isNotBlockedNoCol(boardState: boardState, point: boundOne)) { block2O.append(boundOne) }
        if(isNotBlockedNoCol(boardState: boardState, point: boundTwo)) { block2O.append(boundTwo) }
    }
    func addOpenThreeBlock(boardState: [[Int]], boundOne: CGPoint, boundTwo: CGPoint) {
        if(isNotBlockedNoCol(boardState: boardState, point: boundOne)) { block3O.append(boundOne) }
        if(isNotBlockedNoCol(boardState: boardState, point: boundTwo)) { block3O.append(boundTwo) }
    }
    func addOpenFourBlock(boardState: [[Int]], boundOne: CGPoint, boundTwo: CGPoint) {
        if(isNotBlockedNoCol(boardState: boardState, point: boundOne)) { block4O.append(boundOne) }
        if(isNotBlockedNoCol(boardState: boardState, point: boundTwo)) { block4O.append(boundTwo) }
    }
    func addClosedTwoBlock(boardState: [[Int]], boundOne: CGPoint, boundTwo: CGPoint) {
        if(isNotBlockedNoCol(boardState: boardState, point: boundOne)) { block2C.append(boundOne) }
        if(isNotBlockedNoCol(boardState: boardState, point: boundTwo)) { block2C.append(boundTwo) }
    }
    func addClosedThreeBlock(boardState: [[Int]], boundOne: CGPoint, boundTwo: CGPoint) {
        if(isNotBlockedNoCol(boardState: boardState, point: boundOne)) { block3C.append(boundOne) }
        if(isNotBlockedNoCol(boardState: boardState, point: boundTwo)) { block3C.append(boundTwo) }
    }
    func addClosedFourBlock(boardState: [[Int]], boundOne: CGPoint, boundTwo: CGPoint) {
        if(isNotBlockedNoCol(boardState: boardState, point: boundOne)) { block4C.append(boundOne) }
        if(isNotBlockedNoCol(boardState: boardState, point: boundTwo)) { block4C.append(boundTwo) }
    }
    
    func addOpenTwoAttack(boardState: [[Int]], boundOne: CGPoint, boundTwo: CGPoint) {
        if(isNotBlockedNoCol(boardState: boardState, point: boundOne)) { attack2O.append(boundOne) }
        if(isNotBlockedNoCol(boardState: boardState, point: boundTwo)) { attack2O.append(boundTwo) }
    }
    func addOpenThreeAttack(boardState: [[Int]], boundOne: CGPoint, boundTwo: CGPoint) {
        if(isNotBlockedNoCol(boardState: boardState, point: boundOne)) { attack3O.append(boundOne) }
        if(isNotBlockedNoCol(boardState: boardState, point: boundTwo)) { attack3O.append(boundTwo) }
    }
    func addOpenFourAttack(boardState: [[Int]], boundOne: CGPoint, boundTwo: CGPoint) {
        // print("addOpenFourAttack, adding attack: \(boundOne), \(boundTwo)")
        if(isNotBlockedNoCol(boardState: boardState, point: boundOne)) { attack4O.append(boundOne) }
        if(isNotBlockedNoCol(boardState: boardState, point: boundTwo)) { attack4O.append(boundTwo) }
    }
    func addClosedTwoAttack(boardState: [[Int]], boundOne: CGPoint, boundTwo: CGPoint) {
        if(isNotBlockedNoCol(boardState: boardState, point: boundOne)) { attack2C.append(boundOne) }
        if(isNotBlockedNoCol(boardState: boardState, point: boundTwo)) { attack2C.append(boundTwo) }
    }
    func addClosedThreeAttack(boardState: [[Int]], boundOne: CGPoint, boundTwo: CGPoint) {
        if(isNotBlockedNoCol(boardState: boardState, point: boundOne)) { attack3C.append(boundOne) }
        if(isNotBlockedNoCol(boardState: boardState, point: boundTwo)) { attack3C.append(boundTwo) }
    }
    func addClosedFourAttack(boardState: [[Int]], boundOne: CGPoint, boundTwo: CGPoint) {
        if(isNotBlockedNoCol(boardState: boardState, point: boundOne)) { attack4C.append(boundOne) }
        if(isNotBlockedNoCol(boardState: boardState, point: boundTwo)) { attack4C.append(boundTwo) }
    }
    
}

