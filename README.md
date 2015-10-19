# Touch Visualizer

Like UIWindow, but displays an overlay view displaying active touches with force annotations.

## discussion

You can add this to an existing app for debugging purposes, or merely to dazzle and frighten.

There are two steps to using this: (1) configure your app to use this instead of UIWindow and (2) ensure to deactive it on devices that do not offer force properties API

To use this instead of UIWindow, override your app delegate's `window:UIWindow?` property with a computed property, where the setter's a no-op, and the getter returns a constant reference to an instance of this class.

To de-activate on non-force devices, set `forceActive=false`. Accessing force information on devices without force capability is "undefined" so this precuation is pedantically needed for defined behavior.

This class should not affect normal touch delivery at all.

This class tries to keep its own overlay subview in front but it does not take heroic measures to do so. So I'm not sure if this works in complex cases. It might fail if user code or system code does not anticipate another component modifying the existence or order of the key window's subviews.

KNOWN GOOD: iPhone 5 (iOS 9.0.2), iPhone 6 (iOS 9.0), Xcode 7.0.1

Alexis Gallagher
2015-10-19T1611


