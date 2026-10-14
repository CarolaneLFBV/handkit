import AVFoundation

actor CameraManager {
    // MARK: - Capture
    
    let session = AVCaptureSession()
    
    private let sessionQueue = DispatchSerialQueue(label: "camera.session")
    
    private let frameQueue = DispatchSerialQueue(label: "frame.session")
    
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    private let videoOutputDelegate: VideoOutputDelegate
    
    private var isConfigured = false
    
    // MARK: - Executor
    
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        sessionQueue.asUnownedSerialExecutor()
    }
    
    // MARK: - Init
    
    init(
        onBrightnessChanged: @escaping @Sendable (CGFloat) -> Void,
        onToggle: @escaping @Sendable () -> Void
    ) {
        videoOutputDelegate = VideoOutputDelegate(
            onBrightnessChanged: onBrightnessChanged,
            onToggle: onToggle
        )
    }
    
    // MARK: - Configuration
    
    private func configure() -> Bool {
        session.beginConfiguration()
        
        defer {
            session.commitConfiguration()
        }
        
#if targetEnvironment(macCatalyst)
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: .video, position: .unspecified
        )
        
        let acceptedCamera = discoverySession.devices.first(where: {
            $0.isContinuityCamera == false
        })
#else
        let acceptedCamera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        )
#endif
        
        guard let videoDevice = acceptedCamera,
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoDeviceInput)
                else {
            return false
        }
        
        session.addInput(videoDeviceInput)
        
        guard session.canAddOutput(videoDataOutput) else {
            return false
        }
        
        session.addOutput(videoDataOutput)
        
        videoDataOutput.setSampleBufferDelegate(
            videoOutputDelegate,
            queue: frameQueue
        )
        
        return true
    }
    
    // MARK: - Lifecycle
    
    func start() {
        if !isConfigured {
            isConfigured = configure()
        }
        
        guard isConfigured else {
            return
        }
        
        if !session.isRunning {
            session.startRunning()
        }
    }
    
    func stop() {
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    // MARK: - Preview
    
    func attachPreviewLayer(
        _ previewLayer: AVCaptureVideoPreviewLayer
    ) {
        previewLayer.session = session
    }
}
