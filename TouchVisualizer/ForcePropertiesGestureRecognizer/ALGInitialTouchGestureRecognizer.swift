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
  fileprivate enum ExtendedState {
    case possible,began(UITouch),failed,changed(UITouch),ended(UITouch),canceled(UITouch)
  }

  /// contains the `UITouch` object, and will be non-nil whenever the receiver fires its action callback
  var currentTouch:UITouch? {
    switch self.extendedState {
    case .possible,.failed:    return nil
    case .began(let touch):    return touch
    case .changed(let touch):  return touch
    case .ended(let touch):    return touch
    case .canceled(let touch): return touch
    }
  }

  fileprivate var extendedState:ExtendedState = .possible { didSet {
    switch extendedState {
    case .possible:    self.state = .possible
    case .failed:      self.state = .failed
    case .began(_):    self.state = .began
    case .changed(_):  self.state = .changed
    case .ended(_):    self.state = .ended
    case .canceled(_): self.state = .cancelled
    }
    }
  }
  
  fileprivate func touchesWithAction(_ touches: Set<UITouch>, withEvent event: UIEvent, phase:UITouchPhase)
  {
    switch (self.extendedState,phase)
    {
      // assert: .Possible -> [.Began,.Failed]
    case (.possible, UITouchPhase.began):
      if touches.count == 1 {
        self.extendedState = .began(touches.first!)
      }
      else {
        // ignore multitouch sequences which begin with more than two simultaneous touches
        self.extendedState = .failed
      }
      
    case (.possible, _):
      assertionFailure("unexpected call to non-touchesBegan when UIGestureRecognizer was in .Possible state")
      self.extendedState = .failed
      break

      // assert: .Began -> [.Changed]
    case (.began(let currentTouch),_):
      self.extendedState = .changed(currentTouch)

      // assert: .Changes -> [.Changed, .Canceled, .Ended]
    case (.changed(let touch), .began):
      // if a touch began, it must not be the touch we are recognizing which already began
      for irrelevantTouch in touches.filter({ $0 != touch }) {
        self.ignore(irrelevantTouch, for: event)
      }

    case (.changed(let touch),.moved) where touches.contains(touch):
      self.extendedState = .changed(touch)
      
    case (.changed(let touch),.stationary) where touches.contains(touch):
      self.extendedState = .changed(touch)
      
    case (.changed(let touch),.ended) where touches.contains(touch):
      self.extendedState = .ended(touch)

    case (.changed(let touch),.cancelled) where touches.contains(touch):
      self.extendedState = .canceled(touch)

    case (.changed(let touch),_) where !touches.contains(touch):
      //  NSLog("touches%@ called a Changed gesture recognizer with an ignored touch. Event: %@",method.description,event)
      break

    case (.changed(_),let phase):
      assertionFailure("Should be unreachable")
      NSLog("unexpected call to touches\(phase.description) for this event \(event)")
      break

      // assert: no transition requirements from .Failed, .Ended, .Canceled
    case (.failed,_): fallthrough
    case (.ended(_),_): fallthrough
    case (.canceled(_),_):
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
    self.extendedState = .possible
  }
}

// MARK: logging

extension UITouchPhase {
  var description:String {
    switch self {
    case .began: return "Began"
    case .cancelled: return "Cancelled"
    case .ended: return "Ended"
    case .moved: return "Moved"
    case .stationary: return "Stationary"
    }
  }
}

