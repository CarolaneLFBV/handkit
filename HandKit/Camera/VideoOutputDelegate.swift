//
//  VideoOutputDelegate.swift
//  HandKit
//
//  Created by Carolane Lefebvre on 19/09/2026.
//

import AVFoundation
import CoreMedia
import Vision

/// Receives video frames captured by AVFoundation
/// and forwards their image data for hand-pose analysis.
nonisolated final class VideoOutputDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private let handPoseRequest: VNDetectHumanHandPoseRequest = {
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1
        return request
    }() // () -> immediate execution to onbtain property's value
    
    private var previousPosition: CGPoint? = nil
    private var recentMovementDistances: [CGFloat] = []
    
    // movement state properties
    private var startPosition: CGPoint? = nil
    private let clock = ContinuousClock()
    private var startTime: ContinuousClock.Instant? = nil
    
    // brightness
    private var brightness: CGFloat = 50
    private var startBrightness: CGFloat?
    
    // slider in SwiftUI
    private let onBrightnessChanged: @Sendable (CGFloat) -> Void
    private let onToggle: @Sendable () -> Void
    
    init(
        onBrightnessChanged: @escaping @Sendable (CGFloat) -> Void,
        onToggle: @escaping @Sendable () -> Void
    ) {
        self.onBrightnessChanged = onBrightnessChanged
        self.onToggle = onToggle

        super.init()
    }
    //MARK: - movement state
    private var movementState: MovementState = .idle
    
    enum MovementState {
        case idle
        case moving
    }
    
    private var pinchState: PinchState = .open
    
    enum PinchState {
        case open
        case pinched
    }
    
    //MARK: - methods
    
    /// Called by AVFoundation whenever a new video frame is captured.
    /// Extracts the image buffer that will be analyzed by Vision.
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        do {
            guard let detectedHand = try detectHand(in: pixelBuffer) else {
                return
            }

            try processHand(detectedHand)
        } catch {
            print("Hand pose processing failed:", error)
        }
    }
    
    //MARK: - private methods
    private func detectHand(
        in pixelBuffer: CVPixelBuffer
    ) throws -> VNHumanHandPoseObservation? {
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .right,
            options: [:]
        )

        try handler.perform([handPoseRequest])

        return handPoseRequest.results?.first
    }
    
    private func processHand(
        _ hand: VNHumanHandPoseObservation
    ) throws {
        let indexTip = try hand.recognizedPoint(.indexTip)
        let thumbTip = try hand.recognizedPoint(.thumbTip)

        guard indexTip.confidence >= 0.7,
              thumbTip.confidence >= 0.7 else {
            return
        }

        processMovement(at: indexTip.location)
        processPinch(indexPosition: indexTip.location, thumbPosition: thumbTip.location)
    }
    
    private func processPinch(
        indexPosition: CGPoint,
        thumbPosition: CGPoint
    ) {
        let deltaX = indexPosition.x - thumbPosition.x
        let deltaY = indexPosition.y - thumbPosition.y
        let distance = hypot(deltaX, deltaY)
        handlePinch(distance: distance)
    }
    
    private func processMovement(at currentPosition: CGPoint) {
        guard let previous = previousPosition else {
            previousPosition = currentPosition
            return
        }

        let deltaX = currentPosition.x - previous.x
        let deltaY = currentPosition.y - previous.y

        // Distance traveled by the index between two consecutive frames
        let movementDistance = hypot(deltaX, deltaY)

        // Sliding window containing the five most recent movement distances
        recentMovementDistances.append(movementDistance)

        if recentMovementDistances.count > 5 {
            recentMovementDistances.removeFirst()
        }

        previousPosition = currentPosition

        guard recentMovementDistances.count == 5 else {
            return
        }

        // Median reduces the influence of isolated tracking errors
        let sortedDistances = recentMovementDistances.sorted()
        let medianMovement = sortedDistances[2]

        handleMovement(
            currentPosition: currentPosition,
            medianMovement: medianMovement
        )
    }

    private func handleMovement(
        currentPosition: CGPoint,
        medianMovement: CGFloat
    ) {
        switch movementState {
        case .idle:
            if medianMovement > 0.01 {
                startPosition = currentPosition
                startBrightness = brightness
                startTime = clock.now

                movementState = .moving
            }

        case .moving:
            guard let startPosition,
                  let startBrightness else {
                return
            }

            // Horizontal movement since the beginning of the gesture
            let deltaX = currentPosition.x - startPosition.x

            // Convert normalized movement into brightness percentage
            let sensitivity: CGFloat = 200
            let brightnessDelta = deltaX * sensitivity

            let newBrightness = startBrightness + brightnessDelta
            brightness = min(max(newBrightness, 0), 100)
            
            onBrightnessChanged(brightness)

            // End the gesture once the finger becomes stable again
            if medianMovement < 0.005 {
                movementState = .idle
                self.startPosition = nil
                self.startBrightness = nil
                self.startTime = nil
            }
        }
    }
    
    private func handlePinch(
        distance: CGFloat
    ) {
        switch pinchState {
        case .open:
            if distance < 0.015 {
                pinchState = .pinched
                onToggle()
            }
        case .pinched:
            if distance > 0.03 {
                pinchState = .open
                onToggle()
            }
        }
    }
}
