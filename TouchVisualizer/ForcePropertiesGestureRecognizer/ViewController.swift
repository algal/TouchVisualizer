//
//  ViewController.swift
//  ForcePropertiesGestureRecognizer
//
//  Created by Alexis Gallagher on 2015-10-30.
//  Copyright © 2015 Alexis Gallagher. All rights reserved.
//

import UIKit

class TouchLoggingViewController: UIViewController
{
  @IBOutlet weak var textView: UITextView!
  @IBOutlet weak var touchableView: UIView!
  
  let history = NSMutableArray()
  let monoTouchGR = ALGInitialTouchSequenceGestureRecognizer()

  override func viewDidLoad() {
    super.viewDidLoad()

    monoTouchGR.addTarget(self, action: Selector("handleMonoTouchAction:"))
    self.touchableView.addGestureRecognizer(monoTouchGR)
    self.textView.text = ""
  }

  func handleMonoTouchAction(sender:ALGInitialTouchSequenceGestureRecognizer) {
    history.addObject(NSNumber(float: Float(sender.currentTouch!.force)))
    let forceString = "force=\(sender.currentTouch!.force)\n"
    self.textView.text = self.textView.text + forceString
  }
  
  override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
    let forceCapable = self.traitCollection.forceTouchCapability == .Available
    if let touchWindow = UIApplication.sharedApplication().delegate?.window as? TouchDisplayingWindow {
      touchWindow.forceActive = forceCapable
    }
  }

  @IBAction func log(sender:AnyObject) {
    self.saveArray()
  }
  
  // MARK: shake actions
  
  override func canBecomeFirstResponder() -> Bool {
    return true
  }
  
  override func motionBegan(motion: UIEventSubtype, withEvent event: UIEvent?) {
    self.saveArray()
  }
  
  // MARK: logging
  
  func saveArray() {
    let array = NSArray(array: self.history)
    let data = try! NSJSONSerialization.dataWithJSONObject(array, options: NSJSONWritingOptions.PrettyPrinted)
    let fileURL = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).last!.URLByAppendingPathComponent(NSUUID().UUIDString).URLByAppendingPathExtension("json")
    data.writeToURL(fileURL, atomically: true)
    
    NSLog("wrote file to \(fileURL.absoluteString)")
  }
}

