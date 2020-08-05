//
//  MenuScene.swift
//  DLGoBang
//
//  Created by Max Yeh on 8/4/20.
//  Copyright © 2020 Max Yeh. All rights reserved.
//

import SpriteKit
import GameplayKit

class MenuScene: SKScene {
    
    // Properties
    
    var board: SKSpriteNode!
    
    // Dummy buttons
    var helpButton: SKSpriteNode!
    var pauseButton: SKSpriteNode!
    var instructions: SKSpriteNode!
    var backgroundInstructions: SKSpriteNode!
    var about: SKSpriteNode!
    var backgroundAbout: SKSpriteNode!
    var pausePanel: SKSpriteNode!
    var resumeButton: SKSpriteNode!
    var restartButton: SKSpriteNode!
    var quitButton: SKSpriteNode!
    var backgroundPause: SKSpriteNode!
    
    // buttons
    var startGameButton: SKSpriteNode!
    var howToButton: SKSpriteNode!
    var aboutButton: SKSpriteNode!
    
    // States
    var isInAbout = false
    var isInHowTo = false
    
    // Systems
    
    // State Changes
    
    func changeAboutState() {
        if(isInAbout) { isInAbout = false }
        else { isInAbout = true }
    }
    
    func changeHowToState() {
        if(isInHowTo) { isInHowTo = false }
        else { isInHowTo = true }
    }
    
    override func didMove(to view: SKView) {
        setupNodes()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first else { return }
        let node = atPoint(touch.location(in: self))
        
        if(node.name == "how_to_background" && isInHowTo) {
            changeHowToState()
            removeInstructions()
        } else if(node.name == "about_background" && isInAbout) {
            changeAboutState()
            removeAbout()
        } else if(node.name == "start_game" && !isInAbout && !isInHowTo) {
            startGame()
        } else if(node.name == "how_to" && !isInAbout && !isInHowTo) {
            changeHowToState()
            showInstructions()
        } else if(node.name == "about" && !isInAbout && !isInHowTo) {
            changeAboutState()
            showAbout()
        }
    }
    
    func startGame() {
        let scene = GameScene(size: size)
        scene.scaleMode = scaleMode
        scene.level = 1
        scene.firstGame = true

        let fade = SKTransition.crossFade(withDuration: 0.5)
        view!.presentScene(scene, transition: fade)
    }
    
    func showInstructions() {
        addInstructionPanel()
        let wait = SKAction.wait(forDuration: 0.05)
        let move = SKAction.move(by: CGVector(dx: 0, dy: -self.frame.height), duration: 0.4)
        let fade = SKAction.fadeAlpha(to: 0.4, duration: 0.4)
        instructions.run(SKAction.sequence([wait, move]))
        backgroundInstructions.run(SKAction.sequence([wait, fade]))
    }
    
    func removeInstructions() {
        let move = SKAction.move(by: CGVector(dx: 0, dy: self.frame.height), duration: 0.4)
        let fade = SKAction.fadeOut(withDuration: 0.4)
        backgroundInstructions.run(fade)
        instructions.run(move, completion: removeInstructionPanel)
    }
    
    func showAbout() {
        addAboutPanel()
        let move = SKAction.move(by: CGVector(dx: 0, dy: -self.frame.height), duration: 0.4)
        let fade = SKAction.fadeAlpha(to: 0.4, duration: 0.4)
        about.run(move)
        backgroundAbout.run(fade)
    }
    
    func removeAbout() {
        let move = SKAction.move(by: CGVector(dx: 0, dy: self.frame.height), duration: 0.4)
        let fade = SKAction.fadeOut(withDuration: 0.4)
        backgroundAbout.run(fade)
        about.run(move, completion: removeAboutPanel)
    }
    
}

// Configurations

extension MenuScene {
    
    func setupNodes() {
        createBackground()
        createBoard()
        addHeader()
        addFront()
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
    }
    
    func addInstructionPanel() {
        instructions = SKSpriteNode(imageNamed: "how_to_panel")
        backgroundInstructions = SKSpriteNode(color: .black, size: self.size)
        
        instructions.name = "instructions"
        instructions.size = CGSize(width: 11*self.frame.width/12, height: 21*(11*self.frame.width/12)/17)
        instructions.position = CGPoint(x: self.frame.width/2, y: 3*self.frame.height/2)
        instructions.zPosition = 30.0
        
        backgroundInstructions.name = "how_to_background"
        backgroundInstructions.alpha = 0.01
        backgroundInstructions.zPosition = 27.5
        backgroundInstructions.position = CGPoint(x: self.frame.width/2, y: self.frame.height/2)
        
        addChild(instructions)
        addChild(backgroundInstructions)
    }
    
    func removeInstructionPanel() {
        instructions.removeFromParent()
        backgroundInstructions.removeFromParent()
    }
    
    func addAboutPanel() {
        about = SKSpriteNode(imageNamed: "about_panel")
        backgroundAbout = SKSpriteNode(color: .black, size: self.size)
        
        about.name = "about"
        about.size = CGSize(width: 11*self.frame.width/12, height: 21*(11*self.frame.width/12)/17)
        about.position = CGPoint(x: self.frame.width/2, y: 3*self.frame.height/2)
        about.zPosition = 30.0
        
        backgroundAbout.name = "about_background"
        backgroundAbout.alpha = 0.01
        backgroundAbout.zPosition = 27.5
        backgroundAbout.position = CGPoint(x: self.frame.width/2, y: self.frame.height/2)
        
        addChild(about)
        addChild(backgroundAbout)
    }
    
    func removeAboutPanel() {
        about.removeFromParent()
        backgroundAbout.removeFromParent()
    }
    
    func addHeader() {
        let header = SKSpriteNode()
        header.size = CGSize(width: self.frame.width, height: self.frame.height/10)
        header.anchorPoint = .zero
        header.position = CGPoint(x: 0, y: 9*self.frame.height/10)
        header.color = UIColor(rgb: 0x314C5B)
        header.zPosition = -15.0
        header.drawBorder(color: .white, width: 2)
        
        let headerLevel = SKLabelNode(fontNamed: "Thonburi-Bold")
        headerLevel.text = "Level:"
        headerLevel.fontSize = 24
        headerLevel.fontColor = .gray
        headerLevel.position = CGPoint(x: self.frame.width/7, y: 9.2*self.frame.height/10)
        
//        let image = UIImage.init(systemName: "questionmark.circle")?.withTintColor(UIColor(rgb: 0x76AD94))
//        let data = image!.pngData()
//        let newImage = UIImage(data: data!)
//        let texture = SKTexture(image: newImage!)
        helpButton = SKSpriteNode(imageNamed: "question_button")
        helpButton.name = "help_button"
        helpButton.size = CGSize(width: self.frame.width/8, height: self.frame.width/8)
        helpButton.position = CGPoint(x: 13*self.frame.width/14, y: 9.35*self.frame.height/10)
        
        pauseButton = SKSpriteNode(imageNamed: "pause_button")
        pauseButton.name = "pause_button"
        pauseButton.size = CGSize(width: self.frame.width/8, height: self.frame.width/8)
        pauseButton.position = CGPoint(x: 13*self.frame.width/14-self.frame.width/8, y: 9.35*self.frame.height/10)
        
        addChild(header)
        addChild(headerLevel)
        addChild(helpButton)
        addChild(pauseButton)
    }
    
    func addFront() {
        let titleText = SKLabelNode(fontNamed: "Avenir-Black")
        titleText.text = "DLGoBang"
        titleText.fontSize = 72
        titleText.fontColor = .white
        titleText.position = CGPoint(x: self.frame.width/2, y: 3*self.frame.height/4)
        titleText.zPosition = 0
        
        startGameButton = SKSpriteNode(imageNamed: "start_button")
        startGameButton.name = "start_game"
        startGameButton.size = CGSize(width: 4*self.frame.width/5, height: 2*self.frame.width/15)
        startGameButton.position = CGPoint(x: self.frame.width/2, y: 3*self.frame.height/5)
        startGameButton.zPosition = 1.0
        
        howToButton = SKSpriteNode(imageNamed: "how_to_button")
        howToButton.name = "how_to"
        howToButton.size = CGSize(width: 4*self.frame.width/5, height: 2*self.frame.width/15)
        howToButton.position = CGPoint(x: self.frame.width/2, y: self.frame.height/2)
        howToButton.zPosition = 1.0
        
        aboutButton = SKSpriteNode(imageNamed: "about_button")
        aboutButton.name = "about"
        aboutButton.size = CGSize(width: 4*self.frame.width/5, height: 2*self.frame.width/15)
        aboutButton.position = CGPoint(x: self.frame.width/2, y: 2*self.frame.height/5)
        aboutButton.zPosition = 1.0
        
        let background = SKSpriteNode(color: .black, size: self.size)
        background.alpha = 0.3
        background.zPosition = -1
        background.position = CGPoint(x: self.frame.width/2, y: self.frame.width/2)
        
        addChild(titleText)
        addChild(startGameButton)
        addChild(howToButton)
        addChild(aboutButton)
        addChild(background)
    }
    
}
