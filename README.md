
# HandKit
Control your lights with your hands.
HandKit started as a small iOS experiment with a simple question:
> Could I use my iPhone's camera to control the lights in my room with hand gestures?
Turns out, yes.
The project uses the iPhone's front camera or a local camera on Mac to track hand movements in real time, recognize simple gestures, and translate them into HomeKit actions.
It now runs on iOS and on Mac through Mac Catalyst, with an interface for selecting one or more lights.

## What it can do
HandKit currently supports two interactions:

### Pinch to toggle selected lights
Bring your thumb and index finger together to toggle the selected HomeKit lights as a group.
If all selected lights with a power characteristic are on, the gesture turns them off. Otherwise, it turns them all on. An empty selection sends no commands.
Instead of treating every frame as a new gesture, HandKit tracks the distance between both fingertips and uses a small state machine to detect the transition from an open hand to a pinch.
This prevents a sustained pinch from repeatedly toggling the light.

### Slide to adjust brightness
Move your index finger horizontally to control a brightness value from 0 to 100%.
Movement detection is filtered to reduce noisy transitions, and the index finger's horizontal position is mapped to a brightness value.
The value is sent to all selected lights that support brightness control. Tracking and gesture calibration are still experimental.

## Requirements
- An iOS device with a camera, or a Mac with a camera running the Mac Catalyst app
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

Implemented:
- [x] iOS front-camera capture
- [x] Mac camera capture through Mac Catalyst
- [x] Mac camera selection excluding iPhone Continuity Camera devices
- [x] Real-time Vision hand pose detection
- [x] Index finger and thumb tracking
- [x] Movement-distance median filtering and hysteresis
- [x] Continuous horizontal gesture tracking
- [x] Thumb/index pinch detection with recovery after release
- [x] HomeKit light discovery with stable device identifiers
- [x] SwiftUI selection of one or more lights
- [x] Pinch → shared power state for selected HomeKit lights
- [x] Gesture → brightness control for selected compatible lights
- [x] Observable ViewModel separating the interface from HomeKit
- [x] Camera and light commands tested on iOS and Mac Catalyst

Next steps:
- [ ] More reliable hand tracking and gesture calibration
- [ ] On-screen tracking points and gesture-state diagnostics
- [ ] Core ML hand pose/action classification experiment
- [ ] Visual brightness feedback with a 3D slider
- [ ] Color control for compatible HomeKit lights
- [ ] 3D color wheel

## License
TBD
