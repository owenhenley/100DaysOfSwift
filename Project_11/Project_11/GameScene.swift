//
//  GameScene.swift
//  Project_11
//
//  Created by Owen Henley on 03/06/2019.
//  Copyright © 2019 Owen Henley. All rights reserved.
//

import SpriteKit
import UIKit

class GameScene: SKScene {

    // MARK: - Properties

    private var scoreLabel: SKLabelNode!
    private var ballLimit: Int = 15 {
        didSet {
            if ballLimit == 0 {
                showGameOverAlert()
            }
        }
    }

    private var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }

    private var editLabel: SKLabelNode!
    private var editingMode: Bool = false {
        didSet {
            if editingMode {
                editLabel.text = "Done"
            } else {
                editLabel.text = "Edit"
            }
        }
    }


    // MARK: - SKScene Methods

    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)

        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: 980, y: 700)
        addChild(scoreLabel)

        editLabel = SKLabelNode(fontNamed: "Chalkduster")
        editLabel.text = " Edit"
        editLabel.position = CGPoint(x: 80, y: 700)
        addChild(editLabel)

        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.contactDelegate = self

        makeSlot(at: CGPoint(x: 128, y: 0), isGood: true)
        makeSlot(at: CGPoint(x: 384, y: 0), isGood: false)
        makeSlot(at: CGPoint(x: 640, y: 0), isGood: true)
        makeSlot(at: CGPoint(x: 896, y: 0), isGood: false)

        makeBoucer(at: CGPoint(x: 0, y: 0))
        makeBoucer(at: CGPoint(x: 256, y: 0))
        makeBoucer(at: CGPoint(x: 512, y: 0))
        makeBoucer(at: CGPoint(x: 768, y: 0))
        makeBoucer(at: CGPoint(x: 1024, y: 0))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        let location = touch.location(in: self)
        let objects = nodes(at: location)

        guard let frame = view?.frame else {
            fatalError("There is no view")
        }
        let dropLimit = frame.height - 100

        if objects.contains(editLabel) {
            editingMode.toggle()
        } else {
            if editingMode {
                let size = CGSize(width: Int.random(in: 16...128), height: 16)
                let box = SKSpriteNode(color: UIColor(red: CGFloat.random(in: 0...1), green: CGFloat.random(in: 0...1), blue: CGFloat.random(in: 0...1), alpha: 1), size: size)
                box.zRotation = CGFloat.random(in: 0...3)
                box.position = location
                box.physicsBody = SKPhysicsBody(rectangleOf: box.size)
                box.physicsBody?.isDynamic = false
                box.name = "box"
                addChild(box)
            } else {
                if location.y > dropLimit {
                    self.isUserInteractionEnabled = false
                    let ball = randomBall()
                    ball.physicsBody = SKPhysicsBody(circleOfRadius: ball.size.width / 2)
                    ball.physicsBody?.restitution = 0.5
                    ball.physicsBody?.contactTestBitMask = ball.physicsBody?.collisionBitMask ?? 0
                    ball.position = location
                    ball.name = "ball"
                    addChild(ball)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func randomBall() -> SKSpriteNode {
        SKSpriteNode(imageNamed: Ball.all.randomElement() ?? "ballRed")
    }

    private func makeBoucer(at position: CGPoint) {
        let bouncer = SKSpriteNode(imageNamed: "bouncer")
        bouncer.position = position
        bouncer.physicsBody = SKPhysicsBody(circleOfRadius: bouncer.size.width / 2)
        bouncer.physicsBody?.isDynamic = false
        addChild(bouncer)
    }

    private func makeSlot(at position: CGPoint, isGood: Bool) {
        var slotBase: SKSpriteNode
        var slotGlow: SKSpriteNode

        if isGood {
            slotBase = SKSpriteNode(imageNamed: "slotBaseGood")
            slotGlow = SKSpriteNode(imageNamed: "slotGlowGood")
            slotBase.name = "good"
        } else {
            slotBase = SKSpriteNode(imageNamed: "slotBaseBad")
            slotGlow = SKSpriteNode(imageNamed: "slotGlowBad")
            slotBase.name = "bad"
        }

        slotBase.position = position
        slotGlow.position = position

        slotBase.physicsBody = SKPhysicsBody(rectangleOf: slotBase.size)
        slotBase.physicsBody?.isDynamic = false

        addChild(slotBase)
        addChild(slotGlow)

        let spin = SKAction.rotate(byAngle: .pi, duration: 10)
        let spinForever = SKAction.repeatForever(spin)
        slotGlow.run(spinForever)
    }

    private func showGameOverAlert() {
        let ac = UIAlertController(title: "Game Over", message: "You ran out of balls. Your final score was: \(score)!", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Reset", style: .default, handler: (resetGame)))
        self.view?.window?.rootViewController?.present(ac, animated: true)
    }

    @objc private func resetGame(action: UIAlertAction) {
        ballLimit = 15
        score = 0

        self.children.forEach { node in
            if let remainingBox = self.childNode(withName: "box") {
                self.destroy(object: remainingBox)
            }
        }
    }
}

// MARK: - SKPhysicsContactDelegate

extension GameScene: SKPhysicsContactDelegate {
    func collison(between ball: SKNode, object: SKNode) {
        if object.name == "box" {
            destroy(object: object)
            return
        }

        if object.name == "good" {
            destroy(object: ball)
            score += 1
        } else if object.name == "bad" {
            destroy(object: ball)
            score -= 1
        }
        ballLimit -= 1
        self.isUserInteractionEnabled = true
    }

    func destroy(object: SKNode) {
        switch object.name {
        case "box":
            if let magicParticles = SKEmitterNode(fileNamed: "MagicParticles") {
                magicParticles.position = object.position
                addChild(magicParticles)
            }
        default:
            if let fireParticles = SKEmitterNode(fileNamed: "FireParticles") {
                fireParticles.position = object.position
                addChild(fireParticles)
            }
        }


        object.removeFromParent()
    }

    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }

        if contact.bodyA.node?.name == "ball" {
            collison(between: nodeA, object: nodeB)
        } else if contact.bodyB.node?.name == "ball" {
            collison(between: nodeB, object: nodeA)
        }
    }
}
