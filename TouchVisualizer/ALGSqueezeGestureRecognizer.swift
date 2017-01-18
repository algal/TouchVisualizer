//
//  ALGSqueezeGestureRecognizer.swift
//  TouchVisualizer
//
//  Created by Alexis Gallagher on 2015-11-03.
//  Copyright © 2015 Alexis Gallagher. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass


/**
 A discrete gesture recognizer which recognizes a 3D Touch foce beyond `squeezeThreshhold`
 */
class ALGSqueezeGestureRecognizer: UIGestureRecognizer
{
  class var mainScreenSupportsForce:Bool {
    return UIScreen.main.traitCollection.forceTouchCapability == .available
  }
  
  /// force level required to count as a squeeze. Default is 0.5
  var squeezeThreshhold:CGFloat = 0.5
  
  fileprivate func touchesWithAction(_ touches: Set<UITouch>, withEvent event: UIEvent, phase:UITouchPhase)
  {
    // switch on GR's current state, and on the type of touches... method that was called
    switch (self.state,phase) {
      // .Possible -> [.Recognized, .Failed, or no-op ]
    case (.possible, UITouchPhase.began): fallthrough
    case (.possible, UITouchPhase.moved): fallthrough
    case (.possible, UITouchPhase.stationary): fallthrough
    case (.possible, UITouchPhase.ended):
      if touches.count == 1 && ALGSqueezeGestureRecognizer.mainScreenSupportsForce {
        let normalizedForce = touches.first!.force / touches.first!.maximumPossibleForce
        if normalizedForce >= self.squeezeThreshhold {
          self.state = .recognized
        }
      }
      else {
        self.state = .failed
      }
      
    case (.possible, UITouchPhase.cancelled):
      self.state = .failed

      // iOS handles evolving the GR from these states
    case (.failed,_): fallthrough
    case (.ended(_),_):
      break
      
    case (.changed,_): fallthrough
    case (.began,_): fallthrough
    case (.cancelled,_):
      assertionFailure("unreachable: this is a discrete not a continuous gesture recognizer")
      
    default:
      assertionFailure("unreachable")
      break
    }
  }
  
  //
  // MARK: overrides
  //
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesBegan(touches, with: event)
    self.touchesWithAction(touches, withEvent: event, phase: .began)
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesMoved(touches, with: event)
    self.touchesWithAction(touches, withEvent: event, phase: .moved)
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesEnded(touches, with: event)
    self.touchesWithAction(touches, withEvent: event, phase: .ended)
  }
  
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesCancelled(touches, with: event)
    self.touchesWithAction(touches, withEvent: event, phase: .cancelled)
  }
  
  override func reset() {
    super.reset()
  }
}
