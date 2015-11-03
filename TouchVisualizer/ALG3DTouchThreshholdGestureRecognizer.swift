//
//  ALG3DTouchThreshholdGestureRecognizer.swift
//  TouchVisualizer
//
//  Created by Alexis Gallagher on 2015-11-03.
//  Copyright © 2015 Alexis Gallagher. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

/**
 
 A continuous gesture recognizer for changes in the `UITouch.force` property of the initial touch (i.e., first finger) of any multitouch sequence that begins with a single touch.
 
 This recognizer will "recognize" (i.e., call its action method) whenever the force changes. You can access the `UITouch` being tracked via the `currentTouch` property.
 
 In addition, this recognizer can track whenever the force touches or crosses one or more force threshholds. A force threshholds is a normalized force value (in the range of `0...1`, instead of `0...maximumPossibleForce`). To define a set of force threshhold, just set the property `normalizedForceThreshholds` with a sorted array of `CGFloat` values within `0...1`. Whenever the touch's normalized force reaches or crosses one of these values, then in addition to calling its action method the class will:
 
    1. set `indexOfLastThreshholdReachedOrCrossed`
    2. set `lastThreshholdWasdReachedByIncrease`
    3. call `threshholdWasReachedOrCrossed` if it is non-nil
 
- note: Overengineered? Afraid so. Some refactoring could simplify this.
 
*/
class ALG3DTouchThreshholdGestureRecognizer: UIGestureRecognizer
{
  //
  // configuration properties
  //
  
  /**
   Normalized force threshholds.
  
   This array must either be empty, or else it must contain a sorted array of distinct `CGFloat` values in the closed-closed interval `0...1`. These represent normalized force values. Whenever the `UITouch`'s normalized force value changes so that it equals or crosses one of the these threshholds, the receiver will update `indexOfLastThreshholdReachedOrCrossed`, `lastThreshholdWasdReachedByIncrease`, and call `threshholdWasReachedOrCrossed` if it is non-nil.
   */
  var normalizedForceThreshholds:[CGFloat] = []
    {
    didSet {
      if normalizedForceThreshholds.isEmpty == false
      {
        let isSorted = (normalizedForceThreshholds.sort() == normalizedForceThreshholds)
        assert(isSorted, "ERROR: normalizedForceThreshholds must be a sorted array of numbers")
        let isBounded = normalizedForceThreshholds
          .map({ ClosedInterval<CGFloat>(0,1).contains($0) })
          .reduce(true, combine: { $0 && $1 })
        assert(isBounded, "ERROR: all numbers in normalizedForceThreshholds must be greater than or equal to 0 and less than or equal to 1")
        
        let (zones,indexes) = zonesAndThreshholdIndexesForThreshholds(normalizedForceThreshholds)
        self.zones = zones
        self.indexesOfThreshholdZones = indexes
      }
      else {
        self.zones = nil
        self.indexesOfThreshholdZones = []
      }
    }
  }

  // called when the tracked touch's normalized force reaches or crosses a threshhold. (This is just a convenience, you could get the same information by just checking `indexOfLastThreshholdReachedOrCrossed` every time the action method is called.)
  var threshholdWasReachedOrCrossed:(()->Void)? = nil
  
  //
  // output properties, to expose information to the class's users
  //
  
  /// contains the `UITouch` object being tracked by the receiver, and will be non-nil whenever the receiver recognizes and fires its action method
  var currentTouch:UITouch? {
    switch self.extendedState {
    case .Possible,.Failed:      return nil
    case .Began(let touch,_):    return touch
    case .Changed(let touch,_):  return touch
    case .Ended(let touch,_):    return touch
    case .Canceled(let touch):   return touch
    }
  }
  
  private(set) var indexOfLastThreshholdReachedOrCrossed:Int? = nil
  private(set) var lastThreshholdWasdReachedByIncrease:Bool = false

  //
  // private state properties
  //
  
  /// array of `Interval<CGFloat>`s, generated from the `normalizedForceThreshholds`
  private var zones:[Interval<CGFloat>]? = nil
  /// indexes of threshhold zones, generated from the `normalizedForceThreshholds`
  private var indexesOfThreshholdZones:[Int] = []
  
  /* Represents all the GR's internal state.
  
  The associated UITouch value is the touch being tracked for the gesture. The associated CGFloat is the normalized force from the last call to one of the `touches...` methods.

  */
  private enum ExtendedState {
    case Possible
    case Failed
    case Began(UITouch,CGFloat)
    case Changed(UITouch,CGFloat)
    case Ended(UITouch,CGFloat)
    case Canceled(UITouch)
  }
  
  
  private var extendedState:ExtendedState = .Possible {
    didSet(newValue) {
      switch extendedState {
    case .Possible:      self.state = .Possible
    case .Failed:        self.state = .Failed
    case .Began(_,_):    self.state = .Began
    case .Changed(_,_):  self.state = .Changed
    case .Ended(_,_):    self.state = .Ended
    case .Canceled(_):   self.state = .Cancelled
    }
    }
  }
  
  private func touchesWithAction(touches: Set<UITouch>, withEvent event: UIEvent, phase:UITouchPhase)
  {
    switch (self.extendedState,phase)
    {
      // assert: .Possible -> [.Began,.Failed]
    case (.Possible, UITouchPhase.Began):
      if let theTouch = touches.first where touches.count == 1 {
        let wasReached = self.shouldReportThreshholdCrossingForInitialForce(theTouch.normalizedForce)
        self.extendedState = .Began(theTouch,theTouch.normalizedForce)
        if  wasReached {  self.threshholdWasReachedOrCrossed?()  }
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
    case (.Began(let touch, let lastNormalizedForce),let touchPhase):
      let wasReached = shouldReportThreshholdCrossingForForceChanged(lastNormalizedForce, currentNormalizedForce: touch.normalizedForce)
      if touchPhase == UITouchPhase.Ended {
        self.extendedState = .Ended(touch,touch.normalizedForce)
      }
      else if touchPhase == UITouchPhase.Cancelled {
        self.extendedState = .Canceled(touch)
      }
      else {
        self.extendedState = .Changed(touch,touch.normalizedForce)
      }
      if wasReached { self.threshholdWasReachedOrCrossed?() }
      
      // assert: .Changes -> [.Changed, .Canceled, .Ended]
    case (.Changed(let touch, _), .Began):
      // if a touch began, it must not be the touch we are recognizing which has already begun
      for irrelevantTouch in touches.filter({ $0 != touch }) {
        self.ignoreTouch(irrelevantTouch, forEvent: event)
      }
      
    case (.Changed(let touch, let lastNormalizedForce),.Moved) where touches.contains(touch):
      // if the touch merely moved, maybe report force changes
      let wasReached = shouldReportThreshholdCrossingForForceChanged(lastNormalizedForce, currentNormalizedForce: touch.normalizedForce)
      self.extendedState = .Changed(touch,touch.normalizedForce)
      if wasReached { self.threshholdWasReachedOrCrossed?() }
      
    case (.Changed(let touch, let lastNormalizedForce),.Stationary) where touches.contains(touch):
      // if the touch did not move, maybe report force changes
      let wasReached = shouldReportThreshholdCrossingForForceChanged(lastNormalizedForce, currentNormalizedForce: touch.normalizedForce)
      // TODO: reconsider this. Do we even want to check .Stationary events. Or does the
      // API report all force-only changes as touches Moved?
      self.extendedState = .Changed(touch,touch.normalizedForce)
      if wasReached { self.threshholdWasReachedOrCrossed?() }
      
    case (.Changed(let touch, let lastNormalizedForce),.Ended) where touches.contains(touch):
      // if the tracked touch ended, always report its final force
      let wasReached = self.shouldReportThreshholdCrossingForForceChanged(lastNormalizedForce, currentNormalizedForce: touch.normalizedForce)
      self.extendedState = .Ended(touch,touch.normalizedForce)
      if wasReached { self.threshholdWasReachedOrCrossed?() }
      
      
    case (.Changed(let touch,_),.Cancelled) where touches.contains(touch):
      // if the entire multitouch sequence was cancelled, cancel the gesture as well
      self.extendedState = .Canceled(touch)
      
    case (.Changed(let touch,_),_) where !touches.contains(touch):
      // we were just passed a touch that we said we were ignoring. UIKit, why???
      NSLog("touches%@ called a Changed gesture recognizer with an ignored touch. Event: %@",phase.description,event)
      break
      
    case (.Changed(_),let phase):
      assertionFailure("Should be unreachable")
      NSLog("unexpected call to touches\(phase.description) for this event \(event)")
      break
      
      // assert: no transition requirements from .Failed, .Ended, .Canceled. 
      // UIKit is responsible for transitioning from these states by calling `reset()`
    case (.Failed,_): fallthrough
    case (.Ended(_,_),_): fallthrough
    case (.Canceled(_),_):
      break
    }
  }
  
  /**
   
   Returns true if the force change represents triggers a threshhold, and also updates the output properties `indexOfLastThreshholdReachedOrCrossed` and `lastThreshholdWasdReachedByIncrease`
   
   - parameter currentNormalizedForce: the current `UITouch.force`, normalized to 0...1
   - parameter lastNormalizedForce: the last `UITouch.force`, normalized to 0...1
   - returns: returns true for any of these conditions:
   
     1. the normalized force is now exactly equal to one of the defined threshholds, or
     2. to reach the current normalized force through a continuous change must have required the value to to cross one or more of the threshholds.

   */
  private func shouldReportThreshholdCrossingForForceChanged(lastNormalizedForce:CGFloat,currentNormalizedForce:CGFloat) -> Bool
  {
    if currentNormalizedForce == lastNormalizedForce { return false }

    guard let theZones = self.zones where !theZones.isEmpty else {
        // GR was configured with no threshholds, so this is not a threshhold event
        return false
    }

    let result = evaluateForceChangeWithZones(lastNormalizedForce, currentNormalizedForce: currentNormalizedForce, zones: theZones, indexesOfThreshholdZones: self.indexesOfThreshholdZones)

    switch result {
    case .Ignore:
      return false

    case .ForceChanged(
        indexOfLastThreshholdReachedOrCrossed: let indexOfLastThreshholdReachedOrCrossed,
        threshholdReachedByIncreased: let threshholdReachedByIncreased):
      
      self.indexOfLastThreshholdReachedOrCrossed = indexOfLastThreshholdReachedOrCrossed
      self.lastThreshholdWasdReachedByIncrease = threshholdReachedByIncreased

      return true
    }
  }

  /**
  Returns whether the initial foce of a touchesBegan touch should be recognized, and updates output parameters if needed.
  */
  private func shouldReportThreshholdCrossingForInitialForce(normalizedForce:CGFloat) -> Bool
  {
    /*
    
    We usually compute whether to recognize a force change with `shouldReportForceChanged`.
    
    But a Began touch is a special case, since there is no prior force with respect to which we can define a change. In particular, just computing change versus an imputed previous touch of force=0 would incorrectly fail to recognize the case when there's a touch with exactly force=0 and also a threshhold of zero, as this would would show up as "no change" from 0 to 0.

    So we cover this special cases manually and then delegate to the method `shouldReportForceChanged` for all other cases.
    
    */
    
    
    if self.normalizedForceThreshholds.isEmpty {
      return false
    }
    else {
      if normalizedForce == 0
      {
        if self.normalizedForceThreshholds.first! == CGFloat(0) {
          // first touch is exactly on a force==0 threshhold
          self.indexOfLastThreshholdReachedOrCrossed = 0
          self.lastThreshholdWasdReachedByIncrease = false
          return true
        }
        else {
          return false
        }
      }
      else {
        return self.shouldReportThreshholdCrossingForForceChanged(CGFloat(0), currentNormalizedForce: normalizedForce)
      }
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
  
  override func reset()
  {
    super.reset()
    self.indexOfLastThreshholdReachedOrCrossed = nil
    self.lastThreshholdWasdReachedByIncrease = false
    self.extendedState = .Possible
  }
}

// MARK: helpers

private extension UITouch
{
  var normalizedForce:CGFloat {
    return self.force / self.maximumPossibleForce
  }
}


private enum ForceChangeResult {
  case Ignore
  case ForceChanged(indexOfLastThreshholdReachedOrCrossed:Int,threshholdReachedByIncreased:Bool)
}

/**
 
 - parameter currentNormalizedForce:
 - parameter lastNormalizedForce:
 - parameter zones: an array of `Interval<CGFloat>`s, covering 0...1, where `threshholdZoneIndexes` are the indexes of elements representing threshhold values
 - parameter indexesOfThreshholdZones: sorted indexes of elements in `zones` which represent threshhold values.
 - returns: a `ForeceChangeResult.ForceChanged` if the force entered a threshhold zone or crossed one or more threshhold zones; otherwise, `ForceChangeResult.Ignore`
 
 - precondition: `zones` must be a sorted array of non-overlapping `Interval<CGFloat>`s which collectively contain all of `0...1`
 - note: pure.
 
 */
private func evaluateForceChangeWithZones(lastNormalizedForce:CGFloat, currentNormalizedForce:CGFloat, zones:[Interval<CGFloat>], indexesOfThreshholdZones:[Int]) -> ForceChangeResult
{
  guard currentNormalizedForce != lastNormalizedForce else { return .Ignore }
  
  guard
    let indexOfLastForce = zones.indexOf({ $0.contains(lastNormalizedForce) }),
    let indexOfCurrentForce = zones.indexOf({ $0.contains(currentNormalizedForce) })
    else {
      NSLog("\(__FUNCTION__): ERROR: zones should cover all the 0...1 interval, but I was unable to fine the index for the zone which contained either the currentNormalizedForce or the lastNormalizedForce")
      return .Ignore
  }

  func threshholdIndexForThreshholdZoneIndex(zoneIndex:Int) -> Int {
    if let threshholdPosition = indexesOfThreshholdZones.indexOf(zoneIndex) {
      return threshholdPosition
    }
    else {
      NSLog("Error: could not find zone index for this threshhold")
      return 0
    }
  }

  let currentForceIsOnThreshhold = indexesOfThreshholdZones.contains(indexOfCurrentForce)
  let indexDelta = indexOfCurrentForce - indexOfLastForce
  
  if indexDelta == 0 {
    // no movement from one zone to another, so nothing to report
    return .Ignore
  }
  else if currentForceIsOnThreshhold {
    // landed directly on a threshhold zone, so report this change
    
    let didIncrease = indexDelta > 0
    let lastThreshholdZoneReachedIndex = indexOfCurrentForce
    let lastThresholdReachedIndex = threshholdIndexForThreshholdZoneIndex(lastThreshholdZoneReachedIndex)
    return .ForceChanged(indexOfLastThreshholdReachedOrCrossed:lastThresholdReachedIndex,threshholdReachedByIncreased:didIncrease)
  }
  else
  {
    // landed in an area zone. Which threshholds if any did we cross to get here?
    let interveningIndexesStartItem = min(indexOfCurrentForce, indexOfLastForce).successor()
    let interveningIndexesEndItem = max(indexOfCurrentForce, indexOfLastForce)
    let interveningZoneIndexes = Range(start: interveningIndexesStartItem , end: interveningIndexesEndItem)
    let crossedThreshholdIndexes = interveningZoneIndexes.filter({ indexesOfThreshholdZones.contains($0) }).sort()
    
    if crossedThreshholdIndexes.isEmpty {
      return .Ignore
    }
    else {
      // this exit means we report ONCE even if the change in force means that we crossed two threshholds
      // maybe change this behavior later to generate one report event per crossing?
      let didIncrease  = indexDelta > 0
      let lastThreshholdZoneCrossedIndex = didIncrease ? crossedThreshholdIndexes.last! : crossedThreshholdIndexes.first!
      let threshholdIndexForZoneIndex = threshholdIndexForThreshholdZoneIndex(lastThreshholdZoneCrossedIndex)
      
      return .ForceChanged(indexOfLastThreshholdReachedOrCrossed:threshholdIndexForZoneIndex,threshholdReachedByIncreased:didIncrease)
    }
  }
  
}

/**
 Takes `threshholds`, an array of sorted distinct `CGFloat` values in the closed-closed interval 0...1, and returns an array of `Interval<CGFloat>`s representing the threshholds and the spaces around them, as well as indexes for only the threshholds.

 - returns: a tuple with two components. The first components is an array of "zones", that is, `Interval<CGFloat>` values which collectively contain all values in 0...1, representing either threshholds or the spaces around them. The second component is the indexes of the intervals that represent threshholds, as opposed to spaces.

 - note: Pure. This helper essentially lets us think about force changes in terms of discrete movements through a finite set of zones, rather than as float moving around a continuum.
 
*/
private func zonesAndThreshholdIndexesForThreshholds(threshholds:[CGFloat]) -> ([Interval<CGFloat>],[Int])
{
  guard threshholds.isEmpty == false else { return ([],[]) }
  
  let threshholdZones = threshholds.map({ Interval.ClosedClosed(ClosedInterval($0,$0)) })
  let gapZones = Array(zip(threshholds, threshholds.dropFirst())).map({Interval.OpenOpen(OpenOpenInterval($0.0,$0.1))})
  let threshholdsAndInterveningGaps:[Interval<CGFloat>] = Array(zip(threshholdZones,gapZones)).flatMap({ [$0.0,$0.1] }) + [threshholdZones.last!]

  // add initial and terminal gap zones, if needed
  var allZones = threshholdsAndInterveningGaps
  if threshholds.first! != CGFloat(0) {
    allZones.insert(Interval.ClosedOpen(HalfOpenInterval(CGFloat(0),threshholds.first!)), atIndex: 0)
  }
  if threshholds.last! != CGFloat(1) {
    allZones.append(Interval.OpenClosed(OpenClosedInterval(threshholds.last!,CGFloat(1))))
  }
 
  // collect the indexes of zones representing threshholds
  let indexesOfThreshholdZones = Array(allZones.enumerate()).filter({
    switch $1 { case .ClosedClosed(_): return true
    default: return false
    }}).map({$0.index})
  
  return (allZones,indexesOfThreshholdZones)
}


// MARK: Interval

// poor man's subtype polymorphism
private enum Interval<T:Comparable> {
  case OpenOpen(OpenOpenInterval<T>)
  case ClosedClosed(ClosedInterval<T>)
  case ClosedOpen(HalfOpenInterval<T>)
  case OpenClosed(OpenClosedInterval<T>)
  
  func contains(value:T) -> Bool {
    switch self {
    case .OpenOpen(let x): return x.contains(value)
    case .ClosedClosed(let x): return x.contains(value)
    case .ClosedOpen(let x): return x.contains(value)
    case .OpenClosed(let x): return x.contains(value)
    }
  }
}

// MARK: OpenOpenInterval

/// Swift's missing OpenOpenInterval type
private struct OpenOpenInterval<T:Comparable> {
  let start:T
  let end:T
  
  init(_ start:T,_ end:T) {
    self.start = start
    self.end = end
  }
}

extension OpenOpenInterval : IntervalType {
  typealias Bound = T
  var isEmpty:Bool {
    return !(start < end)
  }
  
  func contains(value: OpenOpenInterval.Bound) -> Bool {
    return start < value && value < end
  }
  
  func clamp(intervalToClamp: OpenOpenInterval) -> OpenOpenInterval {
    let maxStart = max(self.start,intervalToClamp.start)
    let minEnd = max(self.end,intervalToClamp.end)
    return OpenOpenInterval(maxStart, minEnd)
  }
}

private func ==<T>(lhs:OpenOpenInterval<T>,rhs:OpenOpenInterval<T>) -> Bool {
  return lhs.start == rhs.start && lhs.end == rhs.end
}

extension OpenOpenInterval : Equatable { }

// MARK: OpenClosedInterval

/// Swift's missing OpenOpenInterval type
private struct OpenClosedInterval<T:Comparable> {
  let start:T
  let end:T
  
  init(_ start:T,_ end:T) {
    self.start = start
    self.end = end
  }
}

extension OpenClosedInterval : IntervalType {
  typealias Bound = T
  var isEmpty:Bool {
    return false
  }
  
  func contains(value: OpenClosedInterval.Bound) -> Bool {
    return start < value && value <= end
  }
  
  func clamp(intervalToClamp: OpenClosedInterval) -> OpenClosedInterval {
    let maxStart = max(self.start,intervalToClamp.start)
    let minEnd = max(self.end,intervalToClamp.end)
    return OpenClosedInterval(maxStart, minEnd)
  }
}

private func ==<T>(lhs:OpenClosedInterval<T>,rhs:OpenClosedInterval<T>) -> Bool {
  return lhs.start == rhs.start && lhs.end == rhs.end
}

extension OpenClosedInterval : Equatable { }

