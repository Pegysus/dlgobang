//
//  GameScene.swift
//  DLGoBang
//
//  Created by Max Yeh on 7/6/20.
//  Copyright © 2020 Max Yeh. All rights reserved.
//

import SpriteKit
import GameplayKit
import SQLite3
import FirebaseDatabase

class GameScene: SKScene {
    
    // Properties
    
    var board: SKSpriteNode!
    var tempStones: [[SKSpriteNode]] = []
    var currentPlace: SKShapeNode!
    
    var winnerPlace: [CGPoint] = []
    var winnerNodes = [SKShapeNode?](repeating: nil, count: 10)
    var gameOverPanel: SKSpriteNode!
    var playAgainButton: SKSpriteNode!
    var winnerLabel: SKLabelNode!
    var helpButton: SKSpriteNode!
    
    var convertGrid = [[CGPoint]](repeating: [CGPoint](repeating: CGPoint(x: 0, y: 0), count: 19), count: 19)
    var grid = [[Int]](repeating: [Int](repeating: 0, count: 19), count: 19)
    var moves: [(String, Int, Int)] = []
    
    var firstGame = true
    var level = 1
    var isBlackMove = false
    var isWhiteMove = true
    var gameStart = true
    var victory = false
    var victor = ""
    
    var cameraNode = SKCameraNode()
    var previousCameraPoint: CGPoint = .zero
    var zoomInScale = 1.0
    var isZoomedIn = false
    var centerPoint = CGPoint(x: 207, y: 448)
    var distFromCenter: CGPoint = .zero
    
    let id = UUID().uuidString
    let insertStatement = "INSERT INTO GoBangGames(gameID, player, x, y, timestamp) VALUES (?, ?, ?, ?, ?)"
    
    var ref: DatabaseReference!
    var stamp: String!
    
    // State Changes
    
    func changePlayerTurn() {
        if(isBlackMove) {
            isBlackMove = false; isWhiteMove = true
        } else {
            isBlackMove = true; isWhiteMove = false
        }
    }
    
    func changeVictory(winner: String) {
        victory = true
        victor = winner
        addGameOverPanel()
        gameOver()
    }
    
    // Methods
    
    override func didMove(to view: SKView) {
        // print("Current level: \(level)")
        reset()
        setupNodes()
        setupFirebase()
        if(firstGame) { flashHelp() }
        
        let panGesture = UIPanGestureRecognizer()
        panGesture.addTarget(self, action: #selector(panGestureAction(_:)))
        view.addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func doubleTapped() {
        print("zooming in")
        if(!isZoomedIn) {
            zoomIn()
        } else if(isZoomedIn) {
            zoomOut()
        }
    }
    
    @objc func panGestureAction(_ sender: UIPanGestureRecognizer) {
        if(!isZoomedIn) { return }
        // If the movement just began, save the first camera position
        if sender.state == .began {
            previousCameraPoint = cameraNode.position
        }
        // Perform the translation
        let translation = sender.translation(in: self.view)
        let newPosition = CGPoint(
            x: previousCameraPoint.x + translation.x * -1,
            y: previousCameraPoint.y + translation.y
        )
        distFromCenter = newPosition - centerPoint
        cameraNode.position = newPosition
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first else { return }
        let node = atPoint(touch.location(in: self))
        
        var position = touch.location(in: view)
        print("position \(position)")
        print("distFromCenter \(distFromCenter)")
        position = (position-centerPoint)*CGPoint(x: zoomInScale, y: zoomInScale) + centerPoint + CGPoint(x: distFromCenter.x, y: -distFromCenter.y)
        print("position \(position)")
        //print(position)
        if(node.name == "play_again") {
            playAgain()
        } else if(node.name == "help_button") {
            
        } else if(!victory) {
            checkMovement(position: position)
        }
        
    }
    
    func checkMovement(position: CGPoint) {
        for i in 0...18 {
            for j in 0...18 {
                let dist = calcDist(pos1: convertGrid[i][18-j], pos2: position)
                if(dist <= board.frame.width/36.0 && grid[i][j] == 0 && isWhiteMove) {
                    addStoneWhite(loc: CGPoint(x: i, y: j))
                    print("white made move: (\(i), \(j))")
                    changePlayerTurn()
                    if(!victory) {
                        computerMakeMove(boardState: grid, whitePlaced: CGPoint(x: i, y: j))
                    }
                }
            }
        }
    }
    
    func computerMakeMove(boardState: [[Int]], whitePlaced: CGPoint) {
        let move = AlgorithmMovement.sharedInstance.computerMakeMove(boardState: grid, whitePlaced: whitePlaced, gameStart: gameStart, level: level)
        if(gameStart) { gameStart = false }
        print("black made move: \(move)")
        addStoneBlack(loc: move)
        changePlayerTurn()
    }
    
    func storeMove(move: String, x: Int, y: Int) {
        moves.append((move, x, y))
        storeMoveToSQL(move: move, x: x, y: y)
    }
    
    func storeMoveToSQL(move: String, x: Int, y: Int) {
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        .appendingPathComponent("DLGoBang.sqlite")
        
        var db: OpaquePointer?
        guard sqlite3_open(fileURL.path, &db) == SQLITE_OK else {
            print("error opening database")
            sqlite3_close(db)
            db = nil
            return
        }
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertStatement, -1, &statement, nil) == SQLITE_OK {
            let uuid: String = id
            let player: String = move
            let x: Int32 = Int32(x)
            let y: Int32 = Int32(y)
            let timestamp: Date = Date()
            
            sqlite3_bind_text(statement, 1, uuid, -1, nil)
            sqlite3_bind_text(statement, 2, player, -1, nil)
            sqlite3_bind_int(statement, 3, x)
            sqlite3_bind_int(statement, 4, y)
            if timestamp == timestamp {
                sqlite3_bind_double(statement, 5, timestamp.timeIntervalSinceReferenceDate)
            } else {
                sqlite3_bind_null(statement, 5)
            }
        }
    }
    
    func storeWinner() {
        let dateItem = GameDate(timestamp: stamp)
        let dateRef = ref.child("timestamp")
        dateRef.setValue(dateItem.timestamp)
        
        let levelItem = GameLevel(level: level)
        let levelRef = ref.child("level")
        levelRef.setValue(levelItem.level)
        
        for i in 0..<moves.count {
            let move = GameMove(player: moves[i].0, x: moves[i].1, y: moves[i].2)
            
            let moveRef = ref.child("moves")
            let curMoveRef = moveRef.child(String(i+1))
            curMoveRef.setValue(["player": move.player, "x": move.x, "y": move.y])
        }
        
        let winner = victor
        
        let winnerRef = ref.child("victor")
        winnerRef.setValue(winner)
    }
    
    func calcDist(pos1: CGPoint, pos2: CGPoint) -> CGFloat {
        return sqrt(pow(pos1.x-pos2.x, 2) + pow(pos1.y-pos2.y, 2))
    }
    
    func flashHelp() {
        let wait = SKAction.wait(forDuration: 1.5)
        let grow1 = SKAction.resize(byWidth: 12, height: 12, duration: 0.4)
        let grow2 = SKAction.resize(byWidth: 5, height: 5, duration: 0.2)
        let shrink1 = SKAction.resize(byWidth: -5, height: -5, duration: 0.1)
        let shrink2 = SKAction.resize(byWidth: -12, height: -12, duration: 0.3)
        
        helpButton.run(SKAction.sequence([wait, SKAction.repeat(SKAction.sequence([grow1, grow2, shrink1, shrink2]), count: 3)]))
    }
    
    func zoomIn() {
        let zoomInAction = SKAction.scale(to: 0.5, duration: 0.7)
        zoomInScale = 0.5
        cameraNode.run(zoomInAction)
        isZoomedIn = true
    }
    
    func zoomOut() {
        let resetToCenter = SKAction.move(to: centerPoint, duration: 0.7)
        let zoomInAction = SKAction.scale(to: 1.0, duration: 0.7)
        zoomInScale = 1.0
        distFromCenter = .zero
        cameraNode.run(resetToCenter)
        cameraNode.run(zoomInAction)
        isZoomedIn = false
    }
    
    func gameOver() {
        storeWinner()
        if(currentPlace != nil) { removeStoneBackground() }
        zoomOut()
        flashVictory()
        showPanel()
    }
    
    func flashVictory() {
        for i in 0 ..< winnerPlace.count { addWinnerBackground(loc: winnerPlace[i], iter: i) }
        
        let wait = SKAction.wait(forDuration: 0.7)
        let fadeOut = SKAction.fadeAlpha(to: 0.1, duration: 0.5)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        
        for i in 0 ..< winnerPlace.count {
            winnerNodes[i]!.run(
                SKAction.sequence(
                    [wait, SKAction.repeat(SKAction.sequence([fadeIn, fadeOut]), count: 3), fadeIn]
                )
            )
        }
    }
    
    func showPanel() {
        let move = SKAction.move(by: CGVector(dx: 0, dy: -0.33*(self.frame.height)), duration: 0.8)
        playAgainButton.run(SKAction.sequence([SKAction.wait(forDuration: 4.5), move]))
        gameOverPanel.run(SKAction.sequence([SKAction.wait(forDuration: 4.5), move]))
        winnerLabel.run(SKAction.sequence([SKAction.wait(forDuration: 4.5), move]))
    }
       
    func removePanel() {
        let moveDown = SKAction.move(by: CGVector(dx: 0, dy: -10), duration: 0.5)
        let moveUp = SKAction.move(by: CGVector(dx: 0, dy: 0.33*(self.frame.height)+10), duration: 0.2)
        let wait = SKAction.wait(forDuration: 0.4)
        playAgainButton.run(SKAction.sequence([moveDown, moveUp, wait]))
        winnerLabel.run(SKAction.sequence([moveDown, moveUp, wait]))
        gameOverPanel.run(SKAction.sequence([moveDown, moveUp, wait]), completion: newScene)
    }
    
    func cycleFlashBlackMove() {
        let wait = SKAction.wait(forDuration: 8)
        let fadeOut = SKAction.fadeAlpha(to: 0.1, duration: 0.5)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        currentPlace.run(SKAction.sequence([wait, SKAction.repeat(SKAction.sequence([fadeIn, fadeOut]), count: 3), fadeIn]),
                         completion: cycleFlashBlackMove)
    }
    
    func playAgain() {
        reset()
        removePanel()
    }
    
    func newScene() {
        let scene = GameScene(size: size)
        scene.scaleMode = scaleMode

        scene.firstGame = false
        if(victor == "White") {
            scene.level = level+1
            if(scene.level > 3) { scene.level = 3 }
        } else {
            scene.level = level
        }

        let moveIn = SKTransition.moveIn(with: .left, duration: 0.5)
        view!.presentScene(scene, transition: moveIn)
    }
    
    func reset() {
        moves.removeAll()
        grid = [[Int]](repeating: [Int](repeating: 0, count: 19), count: 19)
    }
    
}

// Configurations

extension GameScene {
    
    func setupNodes() {
        createBackground()
        createBoard()
        addHeader()
        setupCamera()
    }
    
    func setupFirebase() {
        ref = Database.database().reference(withPath: id)
        stamp = createDate()
    }
    
    func createDate() -> String {
        let dateFormatter = DateFormatter()
        let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
        dateFormatter.locale = enUSPosixLocale
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        dateFormatter.calendar = Calendar(identifier: .gregorian)

        let date = dateFormatter.string(from: Foundation.Date())
        return date
    }
    
    func createBackground() {
        let background = SKSpriteNode()
        background.name = "background"
        background.size = CGSize(width: self.frame.width, height: self.frame.height)
        background.anchorPoint = .zero
        background.position = .zero
        background.zPosition = -20.0
        background.color = UIColor(rgb: 0x303945)
        addChild(background)
    }
    
    func setupCamera() {
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.position = CGPoint(x: self.frame.width/2.0, y: self.frame.height/2.0)
    }
    
    func createBoard() {
        // Board setup
        board = SKSpriteNode(imageNamed: "gomoku_board")
        board.name = "Board"
        board.size = CGSize(width: self.frame.width, height: self.frame.width)
        board.position = CGPoint(x: self.frame.width/2.0, y: self.frame.height/2.0)
        board.zPosition = -10.0
        board.color = UIColor(rgb: 0xfadea0)
        board.colorBlendFactor = 1.0
        board.alpha = 0.8
        addChild(board)
        
        // background for opacity
        let bg = SKSpriteNode()
        bg.name = "bg"
        bg.size = CGSize(width: self.frame.width, height: self.frame.width)
        bg.position = CGPoint(x: self.frame.width/2.0, y: self.frame.height/2.0)
        bg.zPosition = -15.0
        bg.color = .gray
        addChild(bg)
        
        // Setup nodes for board
        for i in -9...9 {
            for j in -9...9 {
                convertGrid[i+9][j+9] = CGPoint(x: board.position.x+(CGFloat(i)*board.frame.width/18.0),
                                                y: board.position.y+(CGFloat(j)*board.frame.height/18.0))
            }
        }
        print(convertGrid[0][0])
    }
    
    func addStoneWhite(loc: CGPoint) {
        let stone = SKSpriteNode(imageNamed: "gomoku_stone_white")
        stone.name = "WhiteStone"
        stone.size = CGSize(width: self.frame.width/20, height: self.frame.width/20)
        stone.position = convertGrid[Int(loc.x)][Int(loc.y)]
        grid[Int(loc.x)][Int(loc.y)] = 1
        stone.zPosition = 10.0
        addChild(stone)
        
        storeMove(move: "W", x: Int(loc.x), y: Int(loc.y))
        print("stone added for white")
        if(checkWin(justPlaced: loc)) {
            print("white won!")
            changeVictory(winner: "White")
        }
    }
    
    func addStoneBlack(loc: CGPoint) {
        let stone = SKSpriteNode(imageNamed: "gomoku_stone_black")
        stone.name = "BlackStone"
        stone.size = CGSize(width: self.frame.width/20, height: self.frame.width/20)
        stone.position = convertGrid[Int(loc.x)][Int(loc.y)]
        grid[Int(loc.x)][Int(loc.y)] = 2
        stone.zPosition = 10.0
        addChild(stone)
        
        if(currentPlace != nil) { removeStoneBackground() }
        addStoneBackground(loc: loc)
        cycleFlashBlackMove()
        
        storeMove(move: "B", x: Int(loc.x), y: Int(loc.y))
        print("stone added for black")
        if(checkWin(justPlaced: loc)) {
            print("black won!")
            changeVictory(winner: "Black")
        }
    }
    
    func addStoneBackground(loc: CGPoint) {
        currentPlace = SKShapeNode(circleOfRadius: CGFloat(self.frame.width/60))
        currentPlace.position = convertGrid[Int(loc.x)][Int(loc.y)]
        currentPlace.glowWidth = 10.0
        currentPlace.fillColor = .white
        currentPlace.zPosition = 5.0
        addChild(currentPlace)
    }
    
    func removeStoneBackground() {
        currentPlace.removeFromParent()
    }
    
    func addWinnerBackground(loc: CGPoint, iter: Int) {
        winnerNodes[iter] = SKShapeNode(circleOfRadius: CGFloat(self.frame.width/60))
        winnerNodes[iter]!.position = convertGrid[Int(loc.x)][Int(loc.y)]
        winnerNodes[iter]!.glowWidth = 10.0
        winnerNodes[iter]!.fillColor = .white
        winnerNodes[iter]!.zPosition = 5.0
        winnerNodes[iter]!.alpha = 0.1
        addChild(winnerNodes[iter]!)
    }
    
    func addGameOverPanel() {
        gameOverPanel = SKSpriteNode(imageNamed: "game_over_panel")
        playAgainButton = SKSpriteNode(imageNamed: "play_again")
        
        gameOverPanel.position = CGPoint(x: self.frame.width/2.0, y: self.frame.height/2.0+0.66*(self.frame.height))
        gameOverPanel.size = CGSize(width: self.frame.width/1.2, height: 0.7 * self.frame.width/1.2)
        gameOverPanel.zPosition = 20.0
        
        playAgainButton.position = CGPoint(x: gameOverPanel.position.x, y: (self.frame.height/2.0)/1.14+0.66*(self.frame.height))
        playAgainButton.name = "play_again"
        playAgainButton.size = CGSize(width: self.frame.width/2.0, height: 0.3 * self.frame.width/2.0)
        playAgainButton.zPosition = 25.0
        
        winnerLabel = SKLabelNode(fontNamed: "Thonburi-Bold")
        winnerLabel.text = "\(victor) won!"
        winnerLabel.fontSize = 30
        winnerLabel.fontColor = .white
        winnerLabel.position = CGPoint(x: self.frame.width/2.0, y: (self.frame.height/2.0)+0.66*(self.frame.height))
        winnerLabel.zPosition = 25.0
        
        addChild(gameOverPanel)
        addChild(playAgainButton)
        addChild(winnerLabel)
    }
    
    func addHeader() {
        let header = SKSpriteNode()
        header.size = CGSize(width: self.frame.width, height: self.frame.height/10)
        header.anchorPoint = .zero
        header.position = CGPoint(x: 0, y: 9*self.frame.height/10)
        header.color = UIColor(rgb: 0x2A4C5C)
        header.zPosition = -15.0
        header.drawBorder(color: .black, width: 100)
        
        let headerLevel = SKLabelNode(fontNamed: "Thonburi-Bold")
        headerLevel.text = "Level: \(level)"
        headerLevel.fontSize = 24
        headerLevel.fontColor = .white
        headerLevel.position = CGPoint(x: self.frame.width/7, y: 9.2*self.frame.height/10)
        
        helpButton = SKSpriteNode(imageNamed: "question_button")
        helpButton.name = "help_button"
        helpButton.size = CGSize(width: self.frame.width/8, height: self.frame.width/8)
        helpButton.position = CGPoint(x: 8*self.frame.width/9, y: 9.35*self.frame.height/10)
        
        addChild(header)
        addChild(headerLevel)
        addChild(helpButton)
    }
    
    // repetitive methods
    
    func checkWin(justPlaced: CGPoint) -> Bool {

        //print(justPlaced)

        var inARow = 1
        let x = Int(justPlaced.x), y = Int(justPlaced.y)
        var curColor = grid[x][y], consecutiveUp = true, consecutiveDown = true
        var points: [CGPoint] = [justPlaced]

        // check horizonatal
        for i in 1...4 {
            if(x+i <= 18 && grid[x+i][y] == curColor && consecutiveUp) { inARow += 1; points.append(CGPoint(x: x+i, y: y)) }
            if(x-i >= 0 && grid[x-i][y] == curColor && consecutiveDown) { inARow += 1; points.append(CGPoint(x: x-i, y: y)) }
            if(x+i <= 18 && grid[x+i][y] != curColor) { consecutiveUp = false }
            if(x-i >= 0 && grid[x-i][y] != curColor) { consecutiveDown = false }
        }
        //print(inARow)
        if(inARow >= 5) { winnerPlace = points; return true }

        // check vertical
        inARow = 1; consecutiveUp = true; consecutiveDown = true; points = [justPlaced]
        for i in 1...4 {
            if(y+i <= 18 && grid[x][y+i] == curColor && consecutiveUp) { inARow += 1; points.append(CGPoint(x: x, y: y+i)) }
            if(y-i >= 0 && grid[x][y-i] == curColor && consecutiveDown) { inARow += 1; points.append(CGPoint(x: x, y: y-i)) }
            if(y+i <= 18 && grid[x][y+i] != curColor) { consecutiveUp = false }
            if(y-i >= 0 && grid[x][y-i] != curColor) { consecutiveDown = false }
        }
        //print(inARow)
        if(inARow >= 5) { winnerPlace = points; return true }

        // check diagonal1
        inARow = 1; consecutiveUp = true; consecutiveDown = true; points = [justPlaced]
        for i in 1...4 {
            if(x+i <= 18 && y+i <= 18 && grid[x+i][y+i] == curColor && consecutiveUp) { inARow += 1; points.append(CGPoint(x: x+i, y: y+i)) }
            if(x-i >= 0 && y-i >= 0 && grid[x-i][y-i] == curColor && consecutiveDown) { inARow += 1; points.append(CGPoint(x: x-i, y: y-i)) }
            if(x+i <= 18 && y+i <= 18 && grid[x+i][y+i] != curColor) { consecutiveUp = false }
            if(x-i >= 0 && y-i >= 0 && grid[x-i][y-i] != curColor) { consecutiveDown = false }
        }
        //print(inARow)
        if(inARow >= 5) { winnerPlace = points; return true }

        // check diagonal2
        inARow = 1; consecutiveUp = true; consecutiveDown = true; points = [justPlaced]
        for i in 1...4 {
            if(x+i <= 18 && y-i >= 0 && grid[x+i][y-i] == curColor && consecutiveUp) { inARow += 1; points.append(CGPoint(x: x+i, y: y-i)) }
            if(x-i >= 0 && y+i <= 18 && grid[x-i][y+i] == curColor && consecutiveDown) { inARow += 1; points.append(CGPoint(x: x-i, y: y+i)) }
            if(x+i <= 18 && y-i >= 0 && grid[x+i][y-i] != curColor) { consecutiveUp = false }
            if(x-i >= 0 && y+i <= 18 && grid[x-i][y+i] != curColor) { consecutiveDown = false }
        }
        //print(inARow)
        if(inARow >= 5) { winnerPlace = points; return true }
        return false

    }
    
}
