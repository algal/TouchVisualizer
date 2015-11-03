//
//  AppDelegate.swift
//  ForcePropertiesGestureRecognizer
//
//  Created by Alexis Gallagher on 2015-10-30.
//  Copyright © 2015 Alexis Gallagher. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var touchWindow: TouchDisplayingWindow?
  
  var window: UIWindow?
    {
    get {
      if let touchWindow = self.touchWindow {
        return touchWindow
      }
      else {
        self.touchWindow = TouchDisplayingWindow(frame: UIScreen.mainScreen().bounds)
        // initialize presuming we are not on a force-capable device, and then
        // activate later after checking the trait collection property
        self.touchWindow?.forceActive = false
        return touchWindow
      }
    }
    set { }
  }
}
