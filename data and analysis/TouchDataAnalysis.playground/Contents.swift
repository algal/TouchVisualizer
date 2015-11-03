//: Playground - noun: a place where people can play

import UIKit
import XCPlayground

//: Data is loaded and parsed in `ParsedData.swift`, so that it will not be reloaded every time this page of the playground is updated. It is exported from that file as `exportedItems`, an array of CGFloats representing the raw source data

let items = exportedItems

//: Basic univariate descriptive statics

//: Over 60 seconds, we have gathered _2140 data points_, ranging from `0` to `6.66`. This sampling presumably under-represenents the total range of possible values, but it is diagonstic for general conclusions

let n = items.count
let minValue = items.reduce(items[0], combine: min)
let maxValue = items.reduce(items[0], combine: max)

//: Representing _397 distinct force values_, if we assume all differences are meaningful rather than due to floating point error

let distinctItems = Set<CGFloat>(items)
let distinctItemCount = distinctItems.count

let sortedItems = items.sort()


//: Let us normalize values to 0...1000

let normalized = distinctItems.asArray.map( { 1000 * ($0 / maxValue) } )

//: How much does the total number of distinct vlaues change if we look only at variation which is greater than 1/1000th of the total allowed value?

let distinct1000 = Set<CGFloat>(normalized.map(trunc))
let distinct1000Count = distinct1000.count

//: we still see 397 distinct values, so none of the previously observed variation was due to variation of less than  1/1000th (or 0.1%). Therefore, it was probably not due to floating-point error.

//: Question: what is the smallest gap between normalized force values?

let sortedDistinct1000 = distinct1000.asArray.sort()
let gaps = (1..<(sortedDistinct1000.endIndex)).map({ sortedDistinct1000[$0] - sortedDistinct1000[$0.predecessor()] })



let minimumGap = gaps.reduce(gaps.first!, combine: min)
let maximumGap = gaps.reduce(gaps.first!, combine: max)
let meanGap = gaps.reduce(0.0,combine:+) / CGFloat(gaps.count)

//: Answer: the smallest gap between force values, normalized to 0...1000, is 2. The average gap is 2.5. So in this sample of data, _the force sensor is reporting values with a maximum resolution of about 0.2% (2 parts in 1000)_.

//: That tells us the precision of the reported values. To determine their accuracy, we will need to calibrate these values against controlled application of force to the device.






//: Minimum gap between non-normalized items

let rawDistinctItems = distinctItems.sort()
let gaps2 = (1..<(rawDistinctItems.endIndex)).map({ rawDistinctItems[$0] - rawDistinctItems[$0.predecessor()]}).sort()
let minGap2 = gaps2.reduce(gaps2.first!, combine: min)

//: Assume: the non-normalized minimum gap is probably 1/60.
let minRawgap = CGFloat(1) / CGFloat(60)

//: Assume: Maximum value is 20/3
let maxRawValue = CGFloat(20)/CGFloat(3)

//: Infer: *exact number of distinct raw force values = 400*
let distinctRawValues = maxRawValue / minRawgap

let resolution = 1.0 / 400.0

