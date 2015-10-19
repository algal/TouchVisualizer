//
//  ViewController.swift
//  TouchVisualizer
//
//  Created by Alexis Gallagher on 2015-10-19.
//  Copyright © 2015 Alexis Gallagher. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
    let forceCapable = self.traitCollection.forceTouchCapability == .Available
    /*
    We let the view controller tell the custom UIWindow that it's running on a force-capable
    device, because `traitCollectionDidChange(previousTraitCollection:)` is not called on
    the custom UIWindow subclass or its overlay view on iOS 9.0.
    */
    NSLog("activating foce display: \(forceCapable)")
    let w:TouchDisplayingWindow? = (UIApplication.sharedApplication().delegate as? AppDelegate)?.touchWindow
    if w == nil {
      NSLog("w == nil")
    }
    w?.forceActive = forceCapable
  }
}

