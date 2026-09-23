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

    private var startPosition: CGPoint?
    private var startBrightness: CGFloat?

    private var currentBrightness: CGFloat = 0

    // MARK: - Pinch

    private var pinchState: PinchState = .open

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

    // MARK: - External synchronization

    func updateCurrentBrightness(_ brightness: CGFloat) {
        currentBrightness = min(max(brightness, 0), 100)
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

        let isPinching = processPinch(
            indexPosition: indexTip.location,
            thumbPosition: thumbTip.location
        )

        if isPinching {
            cancelMovement()
            return
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
                startPosition = currentPosition
                startBrightness = currentBrightness

                movementState = .moving
            }

        case .moving:
            guard
                let startPosition,
                let startBrightness
            else {
                return
            }

            let deltaX =
                currentPosition.x - startPosition.x

            let sensitivity: CGFloat = 100

            let brightnessDelta =
                deltaX * sensitivity

            let newBrightness =
                startBrightness + brightnessDelta

            let clampedBrightness =
                min(max(newBrightness, 0), 100)

            currentBrightness = clampedBrightness

            onBrightnessChanged(clampedBrightness)

            if medianMovement < 0.005 {
                movementState = .idle

                self.startPosition = nil
                self.startBrightness = nil
            }
        }
    }
    
    private func cancelMovement() {
        movementState = .idle
        startPosition = nil
        startBrightness = nil

        recentMovementDistances.removeAll()
        previousPosition = nil
    }

    // MARK: - Pinch

    private func processPinch(
        indexPosition: CGPoint,
        thumbPosition: CGPoint
    ) -> Bool {
        let deltaX = indexPosition.x - thumbPosition.x
        let deltaY = indexPosition.y - thumbPosition.y
        let distance = hypot(deltaX, deltaY)

        handlePinch(distance: distance)
        switch pinchState {
        case .open:
            return false

        case .pinched:
            return true
        }
    }

    private func handlePinch(
        distance: CGFloat
    ) {
        switch pinchState {
        case .open:
            if distance < 0.015 {
                pinchState = .pinched

                // Only toggle when entering the pinched state.
                onToggle()
            }

        case .pinched:
            if distance > 0.03 {
                // Rearm without triggering another toggle.
                pinchState = .open
            }
        }
    }
}
