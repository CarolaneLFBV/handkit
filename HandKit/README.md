
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

## How it works
At a high level:
Camera
↓
Video frames
↓
Hand pose detection
↓
Finger landmarks
↓
Gesture recognition
↓
HomeKit
↓
Light

The camera stream is captured with AVFoundation and individual video frames are passed to Vision.
Vision provides normalized coordinates for hand landmarks such as the tip of the index finger and thumb.
From there, HandKit implements its own gesture logic.
For example, a pinch is essentially:
1. Track the thumb tip.
2. Track the index fingertip.
3. Measure the distance between them.
4. Determine when that distance becomes small enough to represent a pinch.
5. Trigger an action only when the gesture changes from open to pinched.

## Dealing with noisy tracking
Hand tracking isn't perfectly stable.
Even when a finger appears completely still, its detected coordinates move slightly between frames.
HandKit therefore experiments with a few simple signal-processing techniques:
- confidence thresholds for detected landmarks;
- a sliding window of recent movement measurements;
- median filtering to reduce isolated tracking errors;
- hysteresis to prevent states from rapidly switching around a threshold.

For movement detection, the current experimental thresholds distinguish between an idle and moving state.
The same idea is reused for pinch detection, with separate thresholds for entering and leaving the pinched state.
These values are experimental and were chosen from measurements made while testing the prototype, rather than being universal constants.

## Architecture
The project is intentionally split into a few responsibilities:

### CameraManager
Owns and configures the capture session.
The camera runs through a dedicated serial executor so camera operations remain isolated from the main actor.

### VideoOutputDelegate
Receives camera frames and handles the hand-tracking pipeline.
It is responsible for turning Vision observations into higher-level events such as:
- brightness changes;
- toggle gestures.

It does not know what those events control.

### LightController
Handles HomeKit.
It discovers the selected light and its HomeKit characteristics, then translates application intents into real device actions.
This keeps gesture recognition independent from HomeKit.

### CameraViewModel
Bridges values produced by the camera pipeline back to the SwiftUI interface on the MainActor.

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

## Requirements
- iOS device with a camera
- A HomeKit home
- A HomeKit-compatible light for the smart-light features
- Camera permission
- HomeKit permission

## Disclaimer
This is an experimental project built for learning and exploration.
Gesture thresholds and tracking behavior may vary depending on the device, camera position, lighting conditions, distance from the camera, and the user's hand.

## License
TBD
