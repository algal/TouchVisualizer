import UIKit

// 60 seconds of data produced by gradually varying force applied by my thumb.
let datafilename = "04317CA4-3AD0-4776-861E-78040D8BC3E2.json"

let filename = datafilename

let path = NSBundle.mainBundle().URLForResource(filename, withExtension: nil)!
let data = NSData(contentsOfURL: path)!
let array = try! NSJSONSerialization.JSONObjectWithData(data, options: []) as! NSArray

public let exportedItems:[CGFloat] = array.map({ ($0 as! NSNumber).floatValue }).map({ CGFloat($0) } )
