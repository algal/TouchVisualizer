# 3D Touch visualizer and gesture recognizers

Hello, world. What is this?

This repo contains a few components related to the wonderful world of 3D Touch on iPhones. This is the code and data behind [my talk on 3D Touch](https://realm.io/news/alexis-gallagher-3d-touch-swift/).

Useful bits are, perhaps, the force-visualization overlay window, and the gesture recognizers for detecting force.

This repo also has the data I gathered studying the force properties API, and the test app I wrote for gathering that data. 

To summarize, it looks like 3D Touch reports 400 distinct force values, which are highly accurate and map linearly to actual physical force. The maximum force value reported by the API is about 0.5 kg. (However, this is less than the actual maximum force value the device recognizes, since you can see Apple is using a higher degree of force to trigger the pop behavior.)

Here are items in the repo:

## TouchDisplayingWindow

This is like `UIWindow`, but it displays an overlay view displaying active touches with force annotations. To run it, run the `TouchVisualizer` target in the Xcode project.

You can add this class to an existing app for debugging purposes, or merely to dazzle and frighten.

There are two steps to using this: (1) configure your app to use this instead of UIWindow and (2) ensure to deactive it on devices that do not offer force properties API

To use this instead of UIWindow, override your app delegate's `window:UIWindow?` property with a computed property, where the setter's a no-op, and the getter returns a constant reference to an instance of this class.

To de-activate on non-force devices, set `forceActive=false`. Accessing force information on devices without force capability is "undefined" so this precuation is pedantically needed for defined behavior.

This class should not affect normal touch delivery at all.

This class tries to keep its own overlay subview in front but it does not take heroic measures to do so. So I'm not sure if this works in complex cases. It might fail if user code or system code does not anticipate another component modifying the existence or order of the key window's subviews.

## ALGSqueezeGestureRecognizer

This is a simple discrete gesture recognizer that detects any `UITouch.force` beyond a certain threshhold

## ALG3DTouchThreshholdGestureRecognizer

This is a more elaborate continuous gesture recognizer, which I am hoping is the last force gesture recognizer I will need.

It can be configured just to report all force changes. Or you can configure it with a set of "force threshholds" and then it will report every time the observed force reaches or crosses a threshhold. As long as one is only interested in single-touch gestures, this should meet most purposes.

This is probably a bit overengineered at the moment. I may refactor it later.

## ForceDataCollector

This is the app I built just to collect force data and export it for analysis

KNOWN GOOD: iPhone 6s (iOS 9.1), Xcode 7.1.1

Alexis Gallagher
2015-11-18T1606

