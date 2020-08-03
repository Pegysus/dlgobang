//
//  GameViewController.swift
//  DLGoBang
//
//  Created by Max Yeh on 7/6/20.
//  Copyright © 2020 Max Yeh. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import SQLite3
import Firebase

class GameViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createDB()
        
        let skView = view as! SKView
        let scene = GameScene(size: view.bounds.size)
        scene.level = 1
        scene.firstGame = true
        scene.scaleMode = .aspectFit
        scene.size = view.bounds.size
        
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsPhysics = true
        skView.ignoresSiblingOrder = true
        skView.presentScene(scene)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func createDB() {
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        .appendingPathComponent("DLGoBang.sqlite")
        
        var db: OpaquePointer?
        guard sqlite3_open(fileURL.path, &db) == SQLITE_OK else {
            print("error opening database")
            sqlite3_close(db)
            db = nil
            return
        }
        if sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS GoBangGames (gameID UUID PRIMARY KEY, player TEXT, x INT, y INT, timestamp DATE)", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error creating table: \(errmsg)")
        }
    }
}
