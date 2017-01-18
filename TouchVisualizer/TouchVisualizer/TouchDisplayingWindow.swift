//
//  TouchVisualizer.swift
//  TouchVisualizer
//
//  Created by Alexis Gallagher on 2015-10-19.
//  Copyright © 2015 Alexis Gallagher. All rights reserved.
//

//
//  TouchDisplayingWindow.swift
//  TouchRecorderSpike
//
//  Created by Alexis Gallagher on 2015-10-09.
//  Copyright © 2015 Alexis Gallagher. All rights reserved.
//

import UIKit

/**
Like UIWindow, but displays an overlay view displaying active touches with force annotations.

@discussion

You can add this to an existing app for debugging purposes, or merely to dazzle and frighten.

There are two steps to using this: (1) configure your app to use this instead of UIWindow and (2) ensure to deactive it on devices that do not offer force properties API

To use this instead of UIWindow, override your app delegate's `window:UIWindow?` property with a computed property, where the setter's a no-op, and the getter returns a constant reference to an instance of this class.

To de-activate on non-force devices, set `forceActive=false`. Accessing force information on devices without force capability is "undefined" so this precuation is pedantically needed for defined behavior.

This class should not affect normal touch delivery at all.

This class tries to keep its own overlay subview in front but it does not take heroic measures to do so. So I'm not sure if this works in complex cases. It might fail if user code or system code does not anticipate another component modifying the existence or order of the key window's subviews.

KNOWN GOOD: iPhone 5 (iOS 9.0.2), iPhone 6 (iOS 9.0), Xcode 7.0.1

*/
class TouchDisplayingWindow: UIWindow
{
  // if the view should do anything (rather than behave like UIWindow)
  var active:Bool = true { didSet { overlayView.isHidden = !active } }

  // if the view should display force information
  var forceActive:Bool  {
    get { return overlayView.shouldDisplayForce }
    set { overlayView.shouldDisplayForce = newValue }
  }

  fileprivate let overlayView = OverlayGraphicView(frame: CGRect.zero)
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }
  
  override func didAddSubview(_ subview: UIView) {
    super.didAddSubview(subview)
    self.bringSubview(toFront: overlayView)
  }
  
  fileprivate func setup() {
    overlayView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
    overlayView.frame = self.bounds
    self.addSubview(overlayView)
  }
  
  override func sendEvent(_ event: UIEvent)
  {
    if self.active && event.type == .touches {
      if let touches = event.touches(for: self) {
        let activeTouches = touches.filter({[UITouchPhase.began,.stationary,.moved].contains($0.phase)})
        overlayView.activeTouches = Set(activeTouches)
      }
      else {
        overlayView.activeTouches = Set()
      }
    }
    
    // forward events for processing as usual
    super.sendEvent(event)
  }
  
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    let forceCapable = self.traitCollection.forceTouchCapability == .available
    NSLog("window.forceCapable=\(forceCapable)")
  }

}

// view displaying info on active touches
private class OverlayGraphicView : UIView
{
  /// displays 3D Touch force as an orange circle
  var shouldDisplayForce:Bool       = true

  /// displays radius of the touch as a white circle
  var shouldDisplayRadius:Bool      = true

  /// displays annulus marking erro range around the radius
  var shouldDisplayRadiusError:Bool = true

  /// displays small legends near the touch
  var shouldDisplayLegends:Bool     = true

  /// displays large force and/or radius label on the left side, of the topleft-most touch
  var shouldDisplayBigLegends:Bool  = true
  
  var activeTouches:Set<UITouch> = Set() {
    didSet {
      setNeedsDisplay()
    }
  }
  
  let forceOverlayColor = UIColor.orange
  let radiusOverlayColor = UIColor.white
  let radiusErrorColor = UIColor.lightGray
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }
  
  fileprivate func setup() {
    backgroundColor = .clear
    isUserInteractionEnabled = false
  }
  
  override func draw(_ rect: CGRect)
  {
    // draw force bubble
    let minimumRadius:CGFloat = 50
    let maximumRadius:CGFloat = 175
    
    for touch:UITouch in activeTouches {
      let centerPoint = touch.location(in: self)
      let rawForce:Float = shouldDisplayForce ? Float(touch.force) : 0
      let fractionalForce:CGFloat = shouldDisplayForce ? (touch.force / touch.maximumPossibleForce)  : 0
      
      let majorRadius = touch.majorRadius
      let majorRadiusTolerance = touch.majorRadiusTolerance
      
      forceOverlayColor.setStroke()
      forceOverlayColor.withAlphaComponent(0.2).setFill()
      let radius:CGFloat = fractionalForce * (maximumRadius - minimumRadius) + minimumRadius
      let circlePath = UIBezierPath(arcCenter: centerPoint, radius: radius, startAngle: CGFloat(0), endAngle: CGFloat(M_PI * 2.0), clockwise: true)
      circlePath.lineWidth = CGFloat(2)
      circlePath.stroke()
      circlePath.fill()
      
      if shouldDisplayRadius {
        radiusOverlayColor.setStroke()
        radiusOverlayColor.withAlphaComponent(0.2).setFill()
        let circlePath = UIBezierPath(arcCenter: centerPoint, radius: majorRadius, startAngle: CGFloat(0), endAngle: CGFloat(M_PI * 2.0), clockwise: true)
        circlePath.lineWidth = CGFloat(2)
        circlePath.stroke()
        circlePath.fill()
      }
      
      if shouldDisplayRadiusError {
        let fingerRadiusPlusError = majorRadius + majorRadiusTolerance
        let fingerRadiusMinusError = majorRadius - majorRadiusTolerance
        radiusErrorColor.withAlphaComponent(0.2).setFill()
        let outerFingerCirclePath = UIBezierPath(arcCenter: centerPoint, radius: fingerRadiusPlusError, startAngle: CGFloat(0), endAngle: CGFloat(M_PI * 2.0), clockwise: true)
        let innerFingerCirclePath = UIBezierPath(arcCenter: centerPoint, radius: fingerRadiusMinusError, startAngle: CGFloat(0), endAngle: CGFloat(M_PI * 2.0), clockwise: false)
        outerFingerCirclePath.append(innerFingerCirclePath)
        outerFingerCirclePath.usesEvenOddFillRule = false
        outerFingerCirclePath.fill()
      }
      
      // labels
      
      if shouldDisplayForce && shouldDisplayLegends {
        // draw force string
        let percentString = String(format:"f: %4.3f\u{2007}%2.0f%%",rawForce,Float(fractionalForce * 100)) as NSString
        let textAttributes = numericalTextAttributesWithSize(16, color: forceOverlayColor)
        let textOrigin = CGPoint(x: centerPoint.x + 40, y: centerPoint.y - 70)
        percentString.draw(at: textOrigin, withAttributes: textAttributes)
      }
      
      if shouldDisplayRadius && shouldDisplayLegends {
        // draw force string
        let percentString = String(format:"r: %2.1f",Float(majorRadius)) as NSString
        let textAttributes = numericalTextAttributesWithSize(16, color: radiusOverlayColor)
        let textOrigin = CGPoint(x: centerPoint.x + 40, y: centerPoint.y + 70)
        percentString.draw(at: textOrigin, withAttributes: textAttributes)
      }

      // show only one touch's info in the big legend
      
      func dist(_ a:UITouch) -> CGFloat {
        return ((a.location(in: self).x * a.location(in: self).x) +
          (a.location(in: self).y * a.location(in: self).y))
      }
      
      let isTopLeftMostTouch:Bool = touch == Array(activeTouches).sorted(by: { dist($0) <= dist($1) }).first!
      
      if shouldDisplayForce && shouldDisplayBigLegends && isTopLeftMostTouch {
        // draw force string
        let percentString = String(format:"f: %5.4f\u{2007}%2.0f%%",rawForce,Float(fractionalForce * 100)) as NSString
        let textAttributes = numericalTextAttributesWithSize(46, color: forceOverlayColor)
        let textSize = percentString.size(attributes: textAttributes)
        let textOrigin = CGPoint(x: rect.maxX - textSize.width, y: rect.minY)
        percentString.draw(at: textOrigin, withAttributes: textAttributes)
      }
      
      if shouldDisplayRadius && shouldDisplayBigLegends && isTopLeftMostTouch {
        // draw force string
        let percentString = String(format:"r: %3.2f",Float(majorRadius)) as NSString
        let textAttributes = numericalTextAttributesWithSize(46, color: radiusOverlayColor)
        let textSize = percentString.size(attributes: textAttributes)
        let textOrigin = CGPoint(x: rect.maxX - textSize.width, y: rect.maxY - textSize.height)
        percentString.draw(at: textOrigin, withAttributes: textAttributes)
      }
    }
  }
}

private func numericalTextAttributesWithSize(_ size:CGFloat,color:UIColor) -> [String:AnyObject] {
  let attributes = [
    NSFontAttributeName:UIFont.monospacedDigitSystemFont(ofSize: size, weight: UIFontWeightMedium),
    NSForegroundColorAttributeName:color,
  ]
  return attributes
}

