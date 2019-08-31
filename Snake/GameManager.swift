//
//  GameManager.swift
//  Snake
//
//  Created by Leandro Costa on 31/08/2019.
//  Copyright © 2019 Leandro Costa. All rights reserved.
//

import SpriteKit

class GameManager {
    
    var scene: GameScene!
    var nextTime: Double?
    // timeExtension is used to make the snake moves faster
    var timeExtension: Double = 0.2
    var playerDirection: Int = 4
    var currentScore: Int = 0
    let speedFactor = 0.02
    let screenWidth = 19
    let screenHeight = 37
    let initialX = 10
    let initialY = 10
    
    init(scene: GameScene) {
        self.scene = scene
    }
    
    /// Initialize the snake and snake food initial positions
    func initGame() {
        scene.playerPositions.append((initialX, initialY))
        scene.playerPositions.append((initialX, initialY + 1))
        scene.playerPositions.append((initialX, initialY + 2))
        renderChange()
        generateNewPoint()
    }
    
    /// Render the screen
    func renderChange() {
        for (node, x, y) in scene.gameArray {
            if contains(a: scene.playerPositions, v: (x,y)) {
                node.fillColor = SKColor.cyan
            } else {
                node.fillColor = SKColor.clear
                if scene.scorePos != nil {
                    if Int((scene.scorePos?.x)!) == y && Int((scene.scorePos?.y)!) == x {
                        node.fillColor = SKColor.red
                    }
                }
            }
        }
    }
    
    func contains(a:[(Int, Int)], v:(Int,Int)) -> Bool {
        let (c1, c2) = v
        for (v1, v2) in a { if v1 == c1 && v2 == c2 { return true } }
        return false
    }
    
    /// Update the position of the player using for directions
    private func updatePlayerPosition() {
        var xChange = -1
        var yChange = 0
        switch playerDirection {
        case 1:
            //left
            xChange = -1
            yChange = 0
            break
        case 2:
            //up
            xChange = 0
            yChange = -1
            break
        case 3:
            //right
            xChange = 1
            yChange = 0
            break
        case 4:
            //down
            xChange = 0
            yChange = 1
            break
        case 0:
            //dead
            xChange = 0
            yChange = 0
            break
        default:
            break
        }
        if scene.playerPositions.count > 0 {
            var start = scene.playerPositions.count - 1
            while start > 0 {
                scene.playerPositions[start] = scene.playerPositions[start - 1]
                start -= 1
            }
            scene.playerPositions[0] = (scene.playerPositions[0].0 + yChange, scene.playerPositions[0].1 + xChange)
        }
        if scene.playerPositions.count > 0 {
            let x = scene.playerPositions[0].1
            let y = scene.playerPositions[0].0
            if y > screenHeight {
                scene.playerPositions[0].0 = 0
            } else if y < 0 {
                scene.playerPositions[0].0 = screenHeight
            } else if x > screenWidth {
                scene.playerPositions[0].1 = 0
            } else if x < 0 {
                scene.playerPositions[0].1 = screenWidth
            }
        }
        renderChange()
    }
    
    
    func swipe(ID: Int) {
        if !(ID == 2 && playerDirection == 4) && !(ID == 4 && playerDirection == 2) {
            if !(ID == 1 && playerDirection == 3) && !(ID == 3 && playerDirection == 1) {
                if playerDirection != 0 {
                    playerDirection = ID
                }
            }
        }
    }
    
    /// Create a new point of snake food
    private func generateNewPoint() {
        var randomX = CGFloat(arc4random_uniform(UInt32(screenWidth)))
        var randomY = CGFloat(arc4random_uniform(UInt32(screenHeight)))
        while contains(a: scene.playerPositions, v: (Int(randomX), Int(randomY))) {
            randomX = CGFloat(arc4random_uniform(UInt32(screenWidth)))
            randomY = CGFloat(arc4random_uniform(UInt32(screenHeight)))
        }
        scene.scorePos = CGPoint(x: randomX, y: randomY)
    }
    
    /// Check if the score should be updated
    private func checkForScore() {
        if scene.scorePos != nil {
            let x = scene.playerPositions[0].0
            let y = scene.playerPositions[0].1
            if Int((scene.scorePos?.x)!) == y && Int((scene.scorePos?.y)!) == x {
                currentScore += 1
                scene.currentScore.text = "Score: \(currentScore)"
                let remainder = (Int(scene.currentScore.text ?? "0") ?? 0) % 10
                if (remainder == 0 && timeExtension >= speedFactor) {
                    timeExtension-=speedFactor
                }
                generateNewPoint()
                scene.playerPositions.append(scene.playerPositions.last!)
                scene.playerPositions.append(scene.playerPositions.last!)
                scene.playerPositions.append(scene.playerPositions.last!)
            }
        }
    }
    
    /// Check if the snake is still alive, if not it removes the snake positions and reset its direction
    private func checkForDeath() {
        if scene.playerPositions.count > 0 {
            var arrayOfPositions = scene.playerPositions
            let headOfSnake = arrayOfPositions[0]
            arrayOfPositions.remove(at: 0)
            if contains(a: arrayOfPositions, v: headOfSnake) {
                playerDirection = 0
            }
        }
    }
    
    /// Check if it is a game over, if is true then this method will clean some attributes
    private func finishAnimation() {
        if playerDirection == 0 && scene.playerPositions.count > 0 {
            updateScore()
            playerDirection = 4
            //animation has completed
            scene.scorePos = nil
            scene.playerPositions.removeAll()
            renderChange()
            //return to menu
            scene.currentScore.run(SKAction.scale(to: 0, duration: 0.4)) {
                self.scene.currentScore.isHidden = true
            }
            scene.gameBG.run(SKAction.scale(to: 0, duration: 0.4)) {
                self.scene.gameBG.isHidden = true
                self.scene.gameLogo.isHidden = false
                self.scene.gameLogo.run(SKAction.move(to: CGPoint(x: 0, y: (self.scene.frame.size.height / 2) - 200),
                                                      duration: 0.5)) {
                                                        self.scene.playButton.isHidden = false
                                                        self.scene.playButton.run(SKAction.scale(to: 1, duration: 0.3))
                                                        self.scene.bestScore.run(SKAction.move(to: CGPoint(x: 0, y: self.scene.gameLogo.position.y - 50),
                                                                                               duration: 0.3))
                }
            }
        }
    }
    
    /// Update score and best score when the game has finished
    private func updateScore() {
        if currentScore > UserDefaults.standard.integer(forKey: "bestScore") {
            UserDefaults.standard.set(currentScore, forKey: "bestScore")
        }
        currentScore = 0
        scene.currentScore.text = "Score: 0"
        scene.bestScore.text = "Best Score: \(UserDefaults.standard.integer(forKey: "bestScore"))"
    }
    
    /// Control if its time to move in the game
    func update(time: Double) {
        if nextTime == nil {
            nextTime = time + timeExtension
        } else {
            if time >= nextTime! {
                nextTime = time + timeExtension
                updatePlayerPosition()
                checkForScore()
                checkForDeath()
                finishAnimation()
            }
        }
    }
    
}

