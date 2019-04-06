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

class GameViewController: UIViewController {

    // category bitmasks
    // ball - 1
    // floor - 2
    // goal post - 4
    
    var sceneView: SCNView!
    var scene: SCNScene!
    
    var ballNode: SCNNode!
    var cameraNode: SCNNode!
    
    var fingerStartingPosition: CGPoint!
    
    var screenSize: CGSize!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView = self.view as? SCNView
        scene = SCNScene(named: "art.scnassets/MainScene.scn")
        sceneView.scene = scene
        
        screenSize = sceneView.frame.size
        
        ballNode = scene.rootNode.childNode(withName: "ball", recursively: true)
        cameraNode = scene.rootNode.childNode(withName: "camera", recursively: true)
        
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
            if fingerStartingPosition.y > fingerEndingPosition.y {
                // calculate force
                let screenWidth = screenSize.width
                let screenHeight = screenSize.height
                
                let forceVector = SCNVector3(x: Float((fingerEndingPosition.x - fingerStartingPosition.x)/screenWidth * 5), y: Float((fingerStartingPosition.y - fingerEndingPosition.y)/screenHeight * 5), z: -5 + Float((fingerStartingPosition.y - fingerEndingPosition.y)/screenHeight))
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
