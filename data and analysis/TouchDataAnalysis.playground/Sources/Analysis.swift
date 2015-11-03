import UIKit


extension SequenceType {
  public var asArray:[Self.Generator.Element] {
    return Array(self)
  }
}

//extension SequenceType {
//  public var asSet:Set<Self.Generator.Element> {
//    return Set(self)
//  }
//}

func descriptiveStats(items:[Float]) -> Void
{
  guard items.isEmpty == false else { return }
  let n = items.count
  let minimum = items.reduce(items.first!, combine: min)
  let maximum = items.reduce(items.first!, combine: max)
  let distinctItemsCount = Set(items).count
}

/// Compute frequenceis of values in an arrray
public func frequencies<T:Hashable>(items:[T]) -> [T:Int] {
  return items.reduce([T:Int](), combine: { (var d,item) in
    d[item] = 1 + (d[item] ?? 0)
    return d
  })
}

extension Dictionary {
  public func mapKeys<T>(transform:(Key -> T)) -> Dictionary<T,Value> {
    var result:[T:Value] = [:]
    for (k,v) in self {
      result[transform(k)] = v
    }
    return result
  }
}

/// Super primitive column chart histogram
public class Histogram : UIView
{
  public var data:[String:Int] = [:] { didSet { self.setNeedsDisplay() } }
  var maxCount:Int = 500
  
  public override func drawRect(rect: CGRect)
  {
    let keys = data.keys.asArray.sort()
    let columnsCount = keys.count
    let columnGap = rect.size.width / CGFloat(columnsCount + 1)
    let columnXs = Array(columnGap.stride(to: CGRectGetMaxX(rect), by: columnGap))
    let columnYs = keys.map({ (CGFloat(self.data[$0]!) / CGFloat(maxCount)) * rect.size.height  })

    self.tintColor.setStroke()

    for (x,y) in zip(columnXs, columnYs) {
      let columnPath = UIBezierPath()
      columnPath.lineWidth = 4
      columnPath.moveToPoint(CGPoint(x: x, y: 0))
      columnPath.addLineToPoint(CGPoint(x: x, y: y))
      columnPath.stroke()
    }
  }
}