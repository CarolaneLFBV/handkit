import AVFoundation
import CoreMedia
import Vision

nonisolated final class VideoOutputDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    // MARK: - Vision

    private let handPoseRequest: VNDetectHumanHandPoseRequest = {
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1
        return request
    }()

    // MARK: - Movement

    private var previousPosition: CGPoint?
    private var recentMovementDistances: [CGFloat] = []

    private var movementState: MovementState = .idle

    // MARK: - Pinch

    private var pinchState: PinchState = .open
    
    // MARK: - Recovering
    
    private var recoveryPreviousPosition: CGPoint?
    private var stableRecoveryFrameCount = 0
    
    // MARK: - Brightness
    
    private var lastSentBrightness: CGFloat?

    // MARK: - Outputs

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

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer =
            CMSampleBufferGetImageBuffer(sampleBuffer)
        else {
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

    // MARK: - Vision

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

        guard
            indexTip.confidence >= 0.7,
            thumbTip.confidence >= 0.7
        else {
            return
        }

        processPinch(
            indexPosition: indexTip.location,
            thumbPosition: thumbTip.location
        )

        switch pinchState {
        case .pinched:
            // Pinch currently active:
            // brightness gesture must not run.
            cancelMovement()
            return
            
        case .recovering:
            // Fingers were just released.
            // Wait until the hand becomes stable before allowing slides again.
            cancelMovement()
            processRecovery(at: indexTip.location)
            return
            
        case .open:
            // No pinch interaction is active.
            // Movement recognition is allowed.
            break
        }

        processMovement(at: indexTip.location)
    }

    // MARK: - Movement

    private func processMovement(
        at currentPosition: CGPoint
    ) {
        guard let previous = previousPosition else {
            previousPosition = currentPosition
            return
        }

        let deltaX = currentPosition.x - previous.x
        let deltaY = currentPosition.y - previous.y

        let movementDistance = hypot(deltaX, deltaY)

        recentMovementDistances.append(movementDistance)

        if recentMovementDistances.count > 5 {
            recentMovementDistances.removeFirst()
        }

        previousPosition = currentPosition

        guard recentMovementDistances.count == 5 else {
            return
        }

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
                movementState = .moving
            }

        case .moving:
            // Vision's X coordinate is mirrored compared with
            // what we see in the front-camera preview.
            //
            // Visual left  -> 0%
            // Visual right -> 100%
            let brightness = (1 - currentPosition.x) * 100
            let clampedBrightness = min(max(brightness, 0),100)
            let roundedBrightness = clampedBrightness.rounded() // rounded to limit writing in HomeKit's data
            
            guard roundedBrightness != lastSentBrightness else {
                return
            }
            
            lastSentBrightness = roundedBrightness
            onBrightnessChanged(roundedBrightness)

            if medianMovement < 0.005 {
                movementState = .idle
            }
        }
    }
    
    private func cancelMovement() {
        movementState = .idle
        recentMovementDistances.removeAll()
        previousPosition = nil
    }

    // MARK: - Pinch

    private func processPinch(
        indexPosition: CGPoint,
        thumbPosition: CGPoint
    ) {
        let deltaX = indexPosition.x - thumbPosition.x
        let deltaY = indexPosition.y - thumbPosition.y
        let distance = hypot(deltaX, deltaY)

        handlePinch(distance: distance)
    }

    private func handlePinch(
        distance: CGFloat
    ) {
        switch pinchState {
        case .open:
            if distance < 0.015 {
                pinchState = .pinched
                onToggle() // Only toggle when entering the pinched state.
            }

        case .pinched:
            if distance > 0.03 {
                pinchState = .recovering
                recoveryPreviousPosition = nil
                stableRecoveryFrameCount = 0
            }
            
        case .recovering:
            break
        }
    }
    
    // MARK: - Recovering
    private func processRecovery(at currentPosition: CGPoint) {
        guard let previous = recoveryPreviousPosition else {
            recoveryPreviousPosition = currentPosition
            return
        }
        
        let deltaX = currentPosition.x - previous.x
        let deltaY = currentPosition.y - previous.y
        let distance = hypot(deltaX, deltaY)
        
        recoveryPreviousPosition = currentPosition
        
        if distance < 0.005 {
            stableRecoveryFrameCount += 1
        } else {
            stableRecoveryFrameCount = 0
        }
        
        if stableRecoveryFrameCount >= 5 {
            pinchState = .open
            recoveryPreviousPosition = nil
            stableRecoveryFrameCount = 0
        }
    }
    
}
