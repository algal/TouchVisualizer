//
//  ViewController.swift
//  TouchVisualizer
//
//  Created by Alexis Gallagher on 2015-10-19.
//  Copyright © 2015 Alexis Gallagher. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  let squeezeGR = ALGSqueezeGestureRecognizer()
  let threshholdGR = ALG3DTouchThreshholdGestureRecognizer()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.

//    self.threshholdGR.normalizedForceThreshholds = [CGFloat(0.25),CGFloat(0.75)]
//    self.threshholdGR.addTarget(self, action: Selector("handleThreshhold:"))
//    self.view.addGestureRecognizer(self.threshholdGR)
    
//    self.squeezeGR.addTarget(self, action: Selector("handleSqueeze:"))
//    self.view.addGestureRecognizer(self.squeezeGR)
  }

  func handleThreshhold(sender:ALG3DTouchThreshholdGestureRecognizer) {
    NSLog("==== callback: raw force=\(sender.currentTouch!.force) ")
    if let indexCrossed = sender.indexOfLastThreshholdReachedOrCrossed {
      NSLog("==== callback: crossingIndex = \(indexCrossed) crossedIncreasing=\(sender.lastThreshholdWasdReachedByIncrease)")
    }

    func handleSqueeze(sender:AnyObject) {
      NSLog("squeeze detected")
    }
    
  }
  
  override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
    let forceCapable = self.traitCollection.forceTouchCapability == .Available
    /*
    We let the view controller tell the custom UIWindow that it's running on a force-capable
    device, because `traitCollectionDidChange(previousTraitCollection:)` is not called on
    the custom UIWindow subclass or its overlay view on iOS 9.0.
    */
    NSLog("activating force display: \(forceCapable)")
    
    if let win = UIApplication.sharedApplication().delegate?.window as? TouchDisplayingWindow {
      win.forceActive = forceCapable
    }
    else {
      NSLog("Did not find touch-displaying window")
    }
  }
}

