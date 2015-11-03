//
//  MonotouchGestureRecognizer.swift
//  TouchVisualizer
//
//  Created by Alexis Gallagher on 2015-10-30.
//  Copyright © 2015 Alexis Gallagher. All rights reserved.
//

import UIKit.UIGestureRecognizerSubclass

/**
 
 This recognizes an "initial touch sequence", which is essentially the part of a multitouch sequence that concerns only the single finger which initiated it.
 
Given a valid multitouch sequence, that multitouch sequence contains an initial touch sequence if and only if it begins with a single-finger touch. The initial touch sequence then consists only of `UITouch`s instance values representing that finger. It ends when that finger leaves the screen or when the entire multitouch sequence is cancelled.
 
 Some valid multitouch sequences do not contain initial touch sequences -- for instance, if the multitouch sequence begins with 2 or more simultaneous touches.
 
 Some multitouch sequences outlast their initial touch sequence, for instance, if the multitouch sequence begins with one finger, adds a second finger, removes the first finger, and then moves the second finger, then only the first three actions constitute an initial touch sequence.
 
 When it calls its action method, the property `currentTouch` will be populated with the `UITouch` object of the initial touch sequence
 */
class ALGInitialTouchSequenceGestureRecognizer: UIGestureRecognizer
{
  private enum ExtendedState {
    case Possible,Began(UITouch),Failed,Changed(UITouch),Ended(UITouch),Canceled(UITouch)
  }

  /// contains the `UITouch` object, and will be non-nil whenever the receiver fires its action callback
  var currentTouch:UITouch? {
    switch self.extendedState {
    case .Possible,.Failed:    return nil
    case .Began(let touch):    return touch
    case .Changed(let touch):  return touch
    case .Ended(let touch):    return touch
    case .Canceled(let touch): return touch
    }
  }

  private var extendedState:ExtendedState = .Possible { didSet {
    switch extendedState {
    case .Possible:    self.state = .Possible
    case .Failed:      self.state = .Failed
    case .Began(_):    self.state = .Began
    case .Changed(_):  self.state = .Changed
    case .Ended(_):    self.state = .Ended
    case .Canceled(_): self.state = .Cancelled
    }
    }
  }
  
  private func touchesWithAction(touches: Set<UITouch>, withEvent event: UIEvent, phase:UITouchPhase)
  {
    switch (self.extendedState,phase)
    {
      // assert: .Possible -> [.Began,.Failed]
    case (.Possible, UITouchPhase.Began):
      if touches.count == 1 {
        self.extendedState = .Began(touches.first!)
      }
      else {
        // ignore multitouch sequences which begin with more than two simultaneous touches
        self.extendedState = .Failed
      }
      
    case (.Possible, _):
      assertionFailure("unexpected call to non-touchesBegan when UIGestureRecognizer was in .Possible state")
      self.extendedState = .Failed
      break

      // assert: .Began -> [.Changed]
    case (.Began(let currentTouch),_):
      self.extendedState = .Changed(currentTouch)

      // assert: .Changes -> [.Changed, .Canceled, .Ended]
    case (.Changed(let touch), .Began):
      // if a touch began, it must not be the touch we are recognizing which already began
      for irrelevantTouch in touches.filter({ $0 != touch }) {
        self.ignoreTouch(irrelevantTouch, forEvent: event)
      }

    case (.Changed(let touch),.Moved) where touches.contains(touch):
      self.extendedState = .Changed(touch)
      
    case (.Changed(let touch),.Stationary) where touches.contains(touch):
      self.extendedState = .Changed(touch)
      
    case (.Changed(let touch),.Ended) where touches.contains(touch):
      self.extendedState = .Ended(touch)

    case (.Changed(let touch),.Cancelled) where touches.contains(touch):
      self.extendedState = .Canceled(touch)

    case (.Changed(let touch),_) where !touches.contains(touch):
      //  NSLog("touches%@ called a Changed gesture recognizer with an ignored touch. Event: %@",method.description,event)
      break

    case (.Changed(_),let phase):
      assertionFailure("Should be unreachable")
      NSLog("unexpected call to touches\(phase.description) for this event \(event)")
      break

      // assert: no transition requirements from .Failed, .Ended, .Canceled
    case (.Failed,_): fallthrough
    case (.Ended(_),_): fallthrough
    case (.Canceled(_),_):
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
    self.extendedState = .Possible
  }
}

// MARK: logging

extension UITouchPhase {
  var description:String {
    switch self {
    case .Began: return "Began"
    case .Cancelled: return "Cancelled"
    case .Ended: return "Ended"
    case .Moved: return "Moved"
    case .Stationary: return "Stationary"
    }
  }
}

