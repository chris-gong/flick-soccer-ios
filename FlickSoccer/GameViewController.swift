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

class GameViewController: UIViewController {

    // category bitmasks
    // ball - 1
    // floor - 2
    // goal post - 4
    // out of bounds - 8
    
    var sceneView: SCNView!
    var scene: SCNScene!
    var hud: SKScene!
    var scoreLabel: SKLabelNode!
    
    var ballNode: SCNNode!
    var cameraNode: SCNNode!
    
    var fingerStartingPosition: CGPoint!
    
    var screenSize: CGSize!
    
    var score: Int!
    
    var respawning: Bool! // variable is used to prevent double scoring due to fast contact/collisions being made
    
    var bouncedOffPost: Bool! // variable is used to check if the ball bounced forward after hitting the goal post
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        score = 0
        respawning = false
        bouncedOffPost = false
        // retrieving scnview and scnscene instances
        sceneView = self.view as? SCNView
        scene = SCNScene(named: "art.scnassets/MainScene.scn")
        scene.physicsWorld.contactDelegate = self
        sceneView.scene = scene
        //sceneView.debugOptions = SCNDebugOptions.showPhysicsShapes
        //sceneView.allowsCameraControl = true
        
        screenSize = sceneView.frame.size
        
        // positioning hud and its elements
        hud = SKScene(fileNamed: "ScoreDisplay")
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
            // checking the amount of time passed between finger on and finger off
            // checking if the swipe was long enough
            // check if the swipe made contact with the ball
            // check if the ball has already been kicked (not touching the ground)
            // and checking if the swipe goes forwards
            print("pan gesture ended")
            let fingerEndingPosition = gesture.location(in: sceneView)
            let screenWidth = screenSize.width
            let screenHeight = screenSize.height
            
            // finger has to go forward up the screen and at least a certain distance
            if fingerStartingPosition.y > fingerEndingPosition.y && (fingerStartingPosition.y - fingerEndingPosition.y)/screenHeight > 0.2 {
                // calculate force
                let xForce = Float((fingerEndingPosition.x - fingerStartingPosition.x)/screenWidth * 5)
                let yForce = 1 + Float((fingerStartingPosition.y - fingerEndingPosition.y)/screenHeight * 1.5)
                let zForce = Float(-12 + ((1 - ((fingerStartingPosition.y - fingerEndingPosition.y)/screenHeight))) * 3)
                let forceVector = SCNVector3(x: xForce, y: yForce, z: zForce)
                ballNode.physicsBody?.applyForce(forceVector, asImpulse: true)
                fingerStartingPosition = CGPoint(x: 0, y: 0) // reset starting position (probably not necessary)
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
        print("contact was made")
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
        
        if otherNode.name == "topPost" || otherNode.name == "leftPost" || otherNode.name == "rightPost" {
            if !bouncedOffPost && !respawning {
                runBouncedOffGoalPostSequence(contactNode: contactNode, score: 0)
            }
        }
        
    }
    
    func runUpdateScoreAndRespawnSequence(contactNode: SCNNode, score: Int) {
        respawning = true
        bouncedOffPost = false
        let waitAction = SCNAction.wait(duration: 1)
        let respawnAction = SCNAction.run { (node) in
            // reset the score back to zero if the ball missed the goal post
            self.score = score
            self.scoreLabel.text = String(self.score)
            // reset the location and velocity of the ball
            contactNode.physicsBody?.clearAllForces()
            contactNode.physicsBody?.velocity = SCNVector3(x: 0, y: 0, z: 0)
            contactNode.worldPosition = SCNVector3(x: 0, y: 0.22, z: 20)

            self.respawning = false
        }
        
        let actionSequence = SCNAction.sequence([waitAction, respawnAction])
        contactNode.runAction(actionSequence)
    }
    
    func runBouncedOffGoalPostSequence(contactNode: SCNNode, score: Int) {
        bouncedOffPost = true
        let waitAction = SCNAction.wait(duration: 1)
        let respawnAction = SCNAction.run { (node) in
            // the only way that bouncedoffpost could be set to false is from being scored in the goal or reaching out of bounds in this one second time span
            if self.bouncedOffPost {
                // reset the score back to zero if the ball missed the goal post
                self.score = score
                self.scoreLabel.text = String(self.score)
                // reset the location and velocity of the ball
                contactNode.physicsBody?.clearAllForces()
                contactNode.physicsBody?.velocity = SCNVector3(x: 0, y: 0, z: 0)
                contactNode.worldPosition = SCNVector3(x: 0, y: 0.22, z: 20)
                
                self.bouncedOffPost = false
            }
        }
        
        let actionSequence = SCNAction.sequence([waitAction, respawnAction])
        contactNode.runAction(actionSequence)
    }
}
