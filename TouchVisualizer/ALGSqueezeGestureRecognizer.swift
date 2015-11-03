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
    return UIScreen.mainScreen().traitCollection.forceTouchCapability == .Available
  }
  
  /// force level required to count as a squeeze. Default is 0.5
  var squeezeThreshhold:CGFloat = 0.5
  
  private func touchesWithAction(touches: Set<UITouch>, withEvent event: UIEvent, phase:UITouchPhase)
  {
    // switch on GR's current state, and on the type of touches... method that was called
    switch (self.state,phase) {
      // .Possible -> [.Recognized, .Failed, or no-op ]
    case (.Possible, UITouchPhase.Began): fallthrough
    case (.Possible, UITouchPhase.Moved): fallthrough
    case (.Possible, UITouchPhase.Stationary): fallthrough
    case (.Possible, UITouchPhase.Ended):
      if touches.count == 1 && ALGSqueezeGestureRecognizer.mainScreenSupportsForce {
        let normalizedForce = touches.first!.force / touches.first!.maximumPossibleForce
        if normalizedForce >= self.squeezeThreshhold {
          self.state = .Recognized
        }
      }
      else {
        self.state = .Failed
      }
      
    case (.Possible, UITouchPhase.Cancelled):
      self.state = .Failed

      // iOS handles evolving the GR from these states
    case (.Failed,_): fallthrough
    case (.Recognized(_),_):
      break
      
    case (.Changed,_): fallthrough
    case (.Began,_): fallthrough
    case (.Cancelled,_):
      assertionFailure("unreachable: this is a discrete not a continuous gesture recognizer")
      
    default:
      assertionFailure("unreachable")
      break
    }
  }
  
  //
  // MARK: overrides
  //
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent) {
    super.touchesBegan(touches, withEvent: event)
    self.touchesWithAction(touches, withEvent: event, phase: .Began)
  }
  
  override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
    super.touchesMoved(touches, withEvent: event)
    self.touchesWithAction(touches, withEvent: event, phase: .Moved)
  }
  
  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
    super.touchesEnded(touches, withEvent: event)
    self.touchesWithAction(touches, withEvent: event, phase: .Ended)
  }
  
  override func touchesCancelled(touches: Set<UITouch>, withEvent event: UIEvent) {
    super.touchesCancelled(touches, withEvent: event)
    self.touchesWithAction(touches, withEvent: event, phase: .Cancelled)
  }
  
  override func reset() {
    super.reset()
  }
}
