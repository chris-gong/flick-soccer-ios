//
//  GameViewController.swift
//  FlickSoccer
//
//  Created by Chris Gong on 4/4/19.
//  Copyright © 2019 Chris Gong. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    // category bitmasks
    // ball - 1
    // floor - 2
    // goal post - 4
    // out of bounds - 8
    // score zone - 16
    // goal keeper - 32
    
    var sceneView: SCNView!
    var scene: SCNScene!
    var hud: SKScene!
    var scoreLabel: SKLabelNode!
    
    var ballNode: SCNNode!
    var cameraNode: SCNNode!
    var goalKeeperNode: SCNNode!
    
    var fingerStartingPosition: CGPoint!
    
    var screenSize: CGSize!
    
    var score: Int!
    
    var respawning: Bool! // variable is used to prevent double scoring due to fast contact/collisions being made
    
    var bouncedOffPostOrKeeper: Bool! // variable is used to check if the ball bounced forward after hitting the goal post
    
    var ballMoving: Bool! // variable is used to decide whether to move the camera or not
    
    // variable is used to prevent swiping more than twice
    var swipeCount: Int! // first swipe is for swiping it up off the ground, second swipe is for curving it up, down, left, or right
    
    var goalKeeperSpeed: Float!
    
    var goalKeeperJumping: Bool! // variable is used to decide whether goal keeper is jumping or not
    var goalKeeperFalling: Bool! // variable is used to decide whether goal keeper is falling or not
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        score = 0
        respawning = false
        bouncedOffPostOrKeeper = false
        ballMoving = false
        swipeCount = 0
        goalKeeperSpeed = 0
        goalKeeperJumping = false
        goalKeeperFalling = false
        
        // retrieving scnview and scnscene instances
        sceneView = self.view as? SCNView
        sceneView.delegate = self
        scene = SCNScene(named: "art.scnassets/MainScene.scn")
        scene.physicsWorld.contactDelegate = self
        sceneView.scene = scene
        sceneView.debugOptions = SCNDebugOptions.showPhysicsShapes
        //sceneView.allowsCameraControl = true
        
        screenSize = sceneView.frame.size
        
        // positioning hud and its elements
        hud = SKScene(fileNamed: "art.scnassets/ScoreDisplay")
        hud.scaleMode = .aspectFill
        hud.position = CGPoint(x: 0, y: 0)
        hud.size = CGSize(width: screenSize.width, height: screenSize.height)
        hud.anchorPoint = CGPoint(x: 0.5, y: 0) //set the origin of the hud, values here go from 0 to 1 for both x and y
        
        scoreLabel = hud.childNode(withName: "scoreLabel") as? SKLabelNode
        scoreLabel.position = CGPoint(x: 0, y: screenSize.height/15 * 13)
        sceneView.overlaySKScene = hud
        
        // retrieving scnnode instances
        ballNode = scene.rootNode.childNode(withName: "ball", recursively: true)
        cameraNode = scene.rootNode.childNode(withName: "camera", recursively: true)
        goalKeeperNode = scene.rootNode.childNode(withName: "goalKeeper", recursively: true)
        
        // adding pan gesture
        fingerStartingPosition = CGPoint(x: 0, y: 0)
        let panGestureReocgnizer = UIPanGestureRecognizer(target: self, action: #selector(kickBall(_:)))
        sceneView.addGestureRecognizer(panGestureReocgnizer)
    }

    @objc func kickBall(_ gesture: UIPanGestureRecognizer) {
        guard gesture.view != nil else {return} // pan gesture needs to occur on an actual view
        //print("pan gesture recognized")
        if gesture.state == .began {
            // save the original position of the user's finger
            print("pan gesture started")
            fingerStartingPosition = gesture.location(in: sceneView)
        }
        else if gesture.state == .ended {
            // get the position of the release of the user's finger
            // decide whether the ball should be kicked by either
            // checking the amount of time passed between finger on and finger off and see if the swipe was fast enough
            // checking if the swipe was long enough (in y direction) for the first swipe
            // check if the ball has already been kicked (first swipe made)
            // use different forces for different swipes (first swipehas a z force, second swipe does not have a z force)
            // and checking if the swipe goes forwards (in y direction) for the first swipe
            print("pan gesture ended")
            let fingerEndingPosition = gesture.location(in: sceneView)
            let screenWidth = screenSize.width
            let screenHeight = screenSize.height
            if swipeCount == 0 { // first swipe
                // finger has to go forward up the screen and at least a certain distance
                if fingerStartingPosition.y > fingerEndingPosition.y && (fingerStartingPosition.y - fingerEndingPosition.y)/screenHeight > 0.2 {
                    // calculate force
                    let xForce = Float((fingerEndingPosition.x - fingerStartingPosition.x)/screenWidth * 5)
                    let yForce = 1 + Float((fingerStartingPosition.y - fingerEndingPosition.y)/screenHeight * 1.5)
                    let zForce = Float(-12 + ((1 - ((fingerStartingPosition.y - fingerEndingPosition.y)/screenHeight))) * 3)
                    let forceVector = SCNVector3(x: xForce, y: yForce, z: zForce)
                    ballNode.physicsBody?.applyForce(forceVector, asImpulse: true)
                    //fingerStartingPosition = CGPoint(x: 0, y: 0) // reset starting position (probably not necessary)
                    ballMoving = true
                    swipeCount += 1 // swipe count can only be incremented when a force has been applied
                }
            }
            else if swipeCount == 1 { // second swipe
                let xForce = Float((fingerEndingPosition.x - fingerStartingPosition.x)/screenWidth * 5)
                let yForce = Float((fingerStartingPosition.y - fingerEndingPosition.y)/screenHeight * 2.5)
                let zForce = Float(0)
                let forceVector = SCNVector3(x: xForce, y: yForce, z: zForce)
                ballNode.physicsBody?.applyForce(forceVector, asImpulse: true)
                swipeCount += 1 // swipe count can only be incremented when a force has been applied
            }
            
        }
        
    }
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension GameViewController: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        var contactNode: SCNNode!
        var otherNode: SCNNode!
        
        guard contact.nodeA.name == "ball" || contact.nodeB.name == "ball" else {return}
        
        if contact.nodeA.name == "ball" {
            contactNode = contact.nodeA
            otherNode = contact.nodeB
        }
        else {
            contactNode = contact.nodeB
            otherNode = contact.nodeA
        }
        
        print(otherNode.name)
        if otherNode.name == "scoreZone" {
            if !respawning {
                runUpdateScoreAndRespawnSequence(contactNode: contactNode, score: score + 1)
            }
        }
        
        if otherNode.name == "outOfBounds" {
            if !respawning {
                runUpdateScoreAndRespawnSequence(contactNode: contactNode, score: 0)
            }
        }
        
        if otherNode.name == "topPost" || otherNode.name == "leftPost" || otherNode.name == "rightPost" || otherNode.name == "goalKeeper" {
            if !bouncedOffPostOrKeeper && !respawning {
                runBouncedOffGoalPostOrKeeperSequence(contactNode: contactNode, score: 0)
            }
        }
        
    }
    
    func runUpdateScoreAndRespawnSequence(contactNode: SCNNode, score: Int) {
        respawning = true
        bouncedOffPostOrKeeper = false
        let waitAction = SCNAction.wait(duration: 1)
        let respawnAction = SCNAction.run { (node) in
            // reset the score back to zero if the ball missed the goal post
            self.score = score
            self.scoreLabel.text = String(self.score)
            // reset the location and velocity of the ball
            contactNode.physicsBody?.clearAllForces()
            contactNode.physicsBody?.velocity = SCNVector3(x: 0, y: 0, z: 0)
            contactNode.worldPosition = SCNVector3(x: 0, y: 0.22, z: 20)
            self.cameraNode.worldPosition = SCNVector3(x: 0, y: 0.75, z: 22)
            self.goalKeeperNode.worldPosition = SCNVector3(x: 0, y: 0.925, z: 4.5)
            
            self.respawning = false
            self.ballMoving = false
            self.swipeCount = 0
            self.goalKeeperJumping = false
            self.goalKeeperFalling = false
            
            if self.score > 0 {
                self.goalKeeperSpeed += 0.1 // make the goal keeper faster if a goal was made
            }
            else {
                self.goalKeeperSpeed = 0 // reset the goal keeper's speed once a score streak ends
            }
        }
        
        let actionSequence = SCNAction.sequence([waitAction, respawnAction])
        contactNode.runAction(actionSequence)
    }
    
    func runBouncedOffGoalPostOrKeeperSequence(contactNode: SCNNode, score: Int) {
        bouncedOffPostOrKeeper = true
        let waitAction = SCNAction.wait(duration: 1)
        let respawnAction = SCNAction.run { (node) in
            // the only way that bouncedoffpostorkeeper could be set to false is from being scored in the goal or reaching out of bounds in this one second time span
            if self.bouncedOffPostOrKeeper {
                // reset the score back to zero if the ball missed the goal post
                self.score = score
                self.scoreLabel.text = String(self.score)
                // reset the location and velocity of the ball
                contactNode.physicsBody?.clearAllForces()
                contactNode.physicsBody?.velocity = SCNVector3(x: 0, y: 0, z: 0)
                contactNode.worldPosition = SCNVector3(x: 0, y: 0.22, z: 20)
                self.cameraNode.worldPosition = SCNVector3(x: 0, y: 0.75, z: 22)
                self.goalKeeperNode.worldPosition = SCNVector3(x: 0, y: 0.925, z: 4.5)
                
                self.bouncedOffPostOrKeeper = false
                self.ballMoving = false
                self.swipeCount = 0
                self.goalKeeperJumping = false
                self.goalKeeperFalling = false
                
                if self.score > 0 {
                    self.goalKeeperSpeed += 0.1 // make the goal keeper faster if a goal was made
                }
                else {
                    self.goalKeeperSpeed = 0 // reset the goal keeper's speed once a score streak ends
                }
            }
        }
        
        let actionSequence = SCNAction.sequence([waitAction, respawnAction])
        contactNode.runAction(actionSequence)
    }
}

extension GameViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if ballMoving {
            let ball = ballNode.presentation
            let ballPosition = ball.position
            var cameraPosition = cameraNode.position
            
            let targetPosition = SCNVector3(x: ballPosition.x, y: cameraPosition.y + 0.5, z: cameraPosition.z - 1)
            
            let cameraDamping: Float = 0.1
            
            let xComponent = cameraPosition.x * (1 - cameraDamping) + targetPosition.x * cameraDamping
            let yComponent = cameraPosition.y * (1 - cameraDamping) + targetPosition.y * cameraDamping
            let zComponent = cameraPosition.z * (1 - cameraDamping) + targetPosition.z * cameraDamping
            
            cameraPosition = SCNVector3(x: xComponent, y: yComponent, z: zComponent)
            cameraNode.position = cameraPosition
        }
        
        var ballPosition = ballNode.presentation.position
        var goalKeeperPosition = goalKeeperNode.presentation.position
 
        if ballPosition.x > 3.2 {
            ballPosition.x = 3.2
        }
        else if ballPosition.x < -3.2 {
            ballPosition.x = -3.2
        }
        
        if ballPosition.y > 1.5 && !goalKeeperJumping && !goalKeeperFalling {
            goalKeeperJumping = true
        }
        if goalKeeperJumping && !goalKeeperFalling {
            if goalKeeperPosition.y < 0.5 {
                goalKeeperPosition.y = goalKeeperPosition.y + 0.1
            }
            else {
                goalKeeperJumping = false
                goalKeeperFalling = true
            }
        }
        else if !goalKeeperJumping && goalKeeperFalling {
            if goalKeeperPosition.y > 0 {
                goalKeeperPosition.y = goalKeeperPosition.y - 0.1
            }
            else {
                goalKeeperJumping = false
                goalKeeperFalling = false
            }
        }
        goalKeeperNode.position = SCNVector3(goalKeeperPosition.x * (1 - goalKeeperSpeed) + ballPosition.x * goalKeeperSpeed, goalKeeperPosition.y, goalKeeperPosition.z)
    }
}
