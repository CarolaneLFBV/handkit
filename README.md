
# HandKit
Control your lights with your hands.
HandKit is a small iOS experiment I started with a simple question:
> Could I use my iPhone's camera to control the lights in my room with hand gestures?
Turns out, yes.
The project uses the iPhone's front camera to track hand movements in real time, recognize simple gestures, and translate them into HomeKit actions.

## What it can do
HandKit currently supports two interactions:

### Pinch to toggle a light
Bring your thumb and index finger together to toggle a HomeKit light on or off.
Instead of treating every frame as a new gesture, HandKit tracks the distance between both fingertips and uses a small state machine to detect the transition from an open hand to a pinch.
This prevents a sustained pinch from repeatedly toggling the light.

### Slide to adjust brightness
Move your index finger horizontally to control a brightness value from 0 to 100%.
The movement is tracked continuously, filtered to reduce tracking noise, and mapped to a brightness value.
The HomeKit brightness integration is still a work in progress.

## Requirements
- iOS device with a camera
- A HomeKit home
- A HomeKit-compatible light for the smart-light features
- Camera permission
- HomeKit permission

## Disclaimer
This is an experimental project built for learning and exploration.
Gesture thresholds and tracking behavior may vary depending on the device, camera position, lighting conditions, distance from the camera, and the user's hand.

## Frameworks
HandKit is primarily an exploration of Apple's native frameworks:
- SwiftUI
- AVFoundation
- Vision
- Core Media
- HomeKit
- Swift Concurrency

## Why I built this
Mostly curiosity.
I wanted to use this project as an excuse to explore parts of Apple's ecosystem I had barely touched before.
Along the way, that meant learning about video capture pipelines, pixel buffers, hand landmarks, coordinate systems, noisy measurements, deltas, the Pythagorean theorem, median filtering, hysteresis, actor isolation, custom executors, and HomeKit characteristics.
The goal wasn't to have AI generate the project for me.
I used AI as a mentor while building it: to help me understand unfamiliar concepts, point me toward documentation, challenge my reasoning, and debug things I didn't understand.
The gesture algorithms and thresholds were developed experimentally by observing real tracking data and iterating on the results.

## Status
HandKit is an experiment and a work in progress.
Currently:
- [x] Front-camera capture
- [x] Real-time hand pose detection
- [x] Index finger tracking
- [x] Tracking noise filtering
- [x] Continuous horizontal gesture tracking
- [x] Visual brightness feedback
- [x] Thumb/index pinch detection
- [x] HomeKit accessory discovery
- [x] Pinch → toggle a real HomeKit light
- [ ] Gesture → real HomeKit brightness control
- [ ] More robust gesture calibration
- [ ] macOS camera support

## License
TBD
