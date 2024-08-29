//
//  GameScene.swift
//  SpaceShipGame
//
//  Created by Maryam Kaveh on 5/31/1403 AP.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var starField: SKEmitterNode!
    var timer: Timer!
    var gasTimer: Timer!
    var player: SKSpriteNode!
    var gas: SKSpriteNode!
    var lifeLabel: SKLabelNode!
    var gameOverLabel: SKLabelNode!
    var restartButton: SKSpriteNode!
    var finalScoreLabel: SKLabelNode!
    var life: Int = 3 {
        didSet {
            lifeLabel.text = Array(repeating: "❤️", count: life).joined()
        }
    }
    var scoreLabel: SKLabelNode!
    var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var possibleAliens = ["alien1", "alien2", "alien3", "alien4", "alien5"]
    var torpedoCategory: UInt32 = 0x1 << 3
    var alienCategory: UInt32 = 0x1 << 2
    var playerCategory: UInt32 = 0x1 << 1
    var gasCategory: UInt32 = 0x1 << 0
    
   // let motionManager = CMMotionManager()
   // var xAcceleration: CGFloat = 0
    
    override func didMove(to view: SKView) {
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        setupStarField()
        setupPlayer()
        setupScoreLabel()
        setupLifeLabel()
        setupRetartButton()
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
        gasTimer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(addGas), userInfo: nil, repeats: true)

//        motionManager.accelerometerUpdateInterval = 0.2
//        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { data, error in
//            guard let data = data else {
//                print("Error occured in acceleration!: \(String(describing: error))")
//                return
//            }
            
//            let acceleration = data.acceleration
//            self.xAcceleration = CGFloat(acceleration.x) * 0.75 + self.xAcceleration * 0.25
        //}
    }
    
    func setupStarField() {
        starField = SKEmitterNode(fileNamed: "Starfield")
         starField.position = CGPoint(x: 0, y: 900)
         starField.advanceSimulationTime(10)
         self.addChild(starField)
         starField.zPosition = -1
    }
    
    func setupPlayer() {
        player = SKSpriteNode(imageNamed: "shuttle")
        player.position = CGPoint(x: self.frame.size.width / 2, y: player.size.height / 2 + 20)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.categoryBitMask = playerCategory
        player.physicsBody?.contactTestBitMask = alienCategory
        player.physicsBody?.collisionBitMask = 0
        player.physicsBody?.isDynamic = true
        
        self.addChild(player)
    }
    
    func setupScoreLabel() {
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.position = CGPoint(x: 90, y: self.frame.size.height - 55)
        scoreLabel.fontSize = 18
        scoreLabel.fontName = "AmericanTypewriter-Bold"
        scoreLabel.fontColor = UIColor.white
        score = 0
        
        self.addChild(scoreLabel)
    }
    
    func setupLifeLabel() {
        lifeLabel = SKLabelNode(text: "❤️❤️❤️")
        lifeLabel.position = CGPoint(x: 75, y: self.frame.size.height - 80)
        lifeLabel.fontSize = 12
        lifeLabel.fontName = "AmericanTypewriter-Bold"
        lifeLabel.fontColor = UIColor.red
        life = 3
        
        self.addChild(lifeLabel)
        
    }
    func setupRetartButton() {
        
        restartButton = SKSpriteNode(imageNamed: "restart")
        restartButton.position = CGPoint(x: self.size.width / 2, y: self.frame.size.height / 2 - 5)
        restartButton.size = CGSize(width: 30, height: 30)
        restartButton.name = "restart"
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let node = self.nodes(at: location).first
            
            if node?.name == "restart" {
                restartGame()
            } else {
                fireTorpedo()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            player.position = CGPoint(x: touch.location(in: self).x, y: player.position.y)
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var first: SKPhysicsBody
        var second: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            first = contact.bodyA
            second = contact.bodyB
        } else {
            first = contact.bodyB
            second = contact.bodyA
        }
       
        if (first.categoryBitMask & alienCategory) != 0 && (second.categoryBitMask & torpedoCategory) != 0  {
            // bodyA is alien
            torpedoDidColideWithAlien(torpedoNode: contact.bodyB.node as! SKSpriteNode, alienNode: contact.bodyA.node as! SKSpriteNode)
        }
        
        if (first.categoryBitMask & playerCategory) != 0 && (second.categoryBitMask & alienCategory) != 0  {
            // bodyA is player
            playerDidColideWithAlien(playerNode: contact.bodyA.node as! SKSpriteNode, alienNode: contact.bodyB.node as! SKSpriteNode)
        }
        
        if (first.categoryBitMask & gasCategory) != 0 && (second.categoryBitMask & torpedoCategory) != 0  {
            // bodyA is gas
            torpedoDidCollideWithGas(torpedoNode: contact.bodyB.node as! SKSpriteNode, gasNode: contact.bodyA.node as! SKSpriteNode)
        }
    }
    
    func torpedoDidCollideWithGas(torpedoNode: SKSpriteNode, gasNode: SKSpriteNode) {
        
        self.run(SKAction.playSoundFileNamed("collision", waitForCompletion: false))
        torpedoNode.removeFromParent()
        gasNode.removeFromParent()
        
        if life < 3 {
            life += 1
        }
    }
    
    func torpedoDidColideWithAlien(torpedoNode: SKSpriteNode, alienNode: SKSpriteNode) {
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = alienNode.position
        self.addChild(explosion)
        
        self.run(SKAction.playSoundFileNamed("explosion", waitForCompletion: false))
        torpedoNode.removeFromParent()
        alienNode.removeFromParent()
        
        self.run(SKAction.wait(forDuration: 2)) {
            explosion.removeFromParent()
        }
        
        score += 5
    }
    
    func playerDidColideWithAlien(playerNode: SKSpriteNode, alienNode: SKSpriteNode) {

        let spark = SKSpriteNode(imageNamed: "fire")
        spark.position = CGPoint(x: player.position.x, y: player.position.y)
        spark.size = CGSize(width:95, height: 95)
        spark.zPosition = 2
        self.addChild(spark)
        self.run(SKAction.wait(forDuration: 0.1)) {
            spark.removeFromParent()
        }
        
        life -= 1
        if life == 0 {
            playerNode.removeFromParent()
            gameOver()
        } else {
            self.run(SKAction.playSoundFileNamed("collision", waitForCompletion: false))
        }
    }
    
    @objc func addAlien() {
        possibleAliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleAliens) as! [String]
        let alien = SKSpriteNode(imageNamed: possibleAliens[0])
        let randomPosition = GKRandomDistribution(lowestValue: 0, highestValue: Int(self.frame.size.width) - 50).nextInt()
        alien.position = CGPoint(x: CGFloat(randomPosition), y: self.frame.size.height + alien.size.height)
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.isDynamic = true
        
        alien.physicsBody?.categoryBitMask = alienCategory
        alien.physicsBody?.contactTestBitMask = torpedoCategory | playerCategory
        alien.physicsBody?.collisionBitMask = 0
        
        self.addChild(alien)
        
        let animationDuration: TimeInterval = 6
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: CGFloat(randomPosition), y: -alien.size.height), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        
        alien.run(SKAction.sequence(actionArray))
    }
    
    @objc func addGas() {
        // add gas stations
        let gas = SKSpriteNode(imageNamed: "gas")
        let gasRandomPosition = GKRandomDistribution(lowestValue: 0, highestValue: Int(self.frame.size.width) - 50).nextInt()
        gas.position = CGPoint(x: CGFloat(gasRandomPosition), y: self.frame.size.height + gas.size.height)
        gas.size = CGSize(width: 15, height: 15)
        gas.physicsBody = SKPhysicsBody(rectangleOf: gas.size)
        gas.physicsBody?.isDynamic = true
        
        gas.physicsBody?.categoryBitMask = gasCategory
        gas.physicsBody?.contactTestBitMask = torpedoCategory
        gas.physicsBody?.collisionBitMask = 0
        
        self.addChild(gas)
        
        let animationDuration: TimeInterval = 5
        var gasActionArray = [SKAction]()
        gasActionArray.append(SKAction.move(to: CGPoint(x: CGFloat(gasRandomPosition), y: -gas.size.height), duration: animationDuration))
        gasActionArray.append(SKAction.removeFromParent())
        gas.run(SKAction.sequence(gasActionArray))
    }
    
    func fireTorpedo() {
        self.run(SKAction.playSoundFileNamed("laser", waitForCompletion: false))
        
        let torpedo = SKSpriteNode(imageNamed: "torpedo")
        torpedo.position = CGPoint(x: player.position.x, y: player.size.height + 30)
        torpedo.size = CGSize(width: 10, height: 10)
        torpedo.physicsBody = SKPhysicsBody(circleOfRadius: torpedo.size.width / 2)
        torpedo.physicsBody?.isDynamic = true
        
        torpedo.physicsBody?.categoryBitMask = torpedoCategory
        torpedo.physicsBody?.contactTestBitMask = alienCategory | gasCategory
        torpedo.physicsBody?.collisionBitMask = 0
        torpedo.physicsBody?.usesPreciseCollisionDetection = true
        
        self.addChild(torpedo)
        
        let animationDuration: TimeInterval = 1
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: player.position.x, y: self.frame.size.height + 15), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        torpedo.run(SKAction.sequence(actionArray))
    }
    
    func gameOver() {
        self.run(SKAction.playSoundFileNamed("gameover", waitForCompletion: false))
        
        gameOverLabel = SKLabelNode(text: "GAME OVER!")
        gameOverLabel.position = CGPoint(x: self.size.width / 2, y: self.frame.size.height / 2 + 50)
        gameOverLabel.fontSize = 42
        gameOverLabel.fontName = "AmericanTypewriter-Bold"
        gameOverLabel.fontColor = UIColor.red
        
        self.addChild(gameOverLabel)
        timer.invalidate()
        gasTimer.invalidate()
        
        scoreLabel.removeFromParent()
        player.removeFromParent()
        finalScoreLabel = SKLabelNode(text: "You scored: \(score)")
        finalScoreLabel.position = CGPoint(x: self.size.width / 2, y: self.frame.size.height / 2 + 20)
        finalScoreLabel.fontSize = 22
        finalScoreLabel.fontName = "AmericanTypewriter-Bold"
        finalScoreLabel.fontColor = UIColor.white
        
        self.addChild(finalScoreLabel)
        self.addChild(restartButton)
    }
    
    func restartGame() {
        score = 0
        life = 3
        
        setupPlayer()
        setupScoreLabel()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
        gasTimer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(addGas), userInfo: nil, repeats: true)
        
        gameOverLabel.removeFromParent()
        finalScoreLabel.removeFromParent()
        restartButton.removeFromParent()
    }
    
    //override func didSimulatePhysics() {
//        player.position.x += xAcceleration * 50
//        if player.position.x < -20 {
//            player.position = CGPoint(x: self.size.width + 20, y: player.position.y)
//        } else if player.position.x > self.size.width + 20 {
//            player.position = CGPoint(x: -20, y: player.position.y)
//        }
   // }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
