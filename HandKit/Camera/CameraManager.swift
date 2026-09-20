//
//  CameraManager.swift
//  HandKit
//
//  Created by Carolane Lefebvre on 19/09/2026.
//

import Foundation
import AVFoundation

actor CameraManager {
    let session = AVCaptureSession()
    
    private let sessionQueue = DispatchSerialQueue(label: "camera.session")
    private let frameQueue = DispatchSerialQueue(label: "frame.session")
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoOutputDelegate: VideoOutputDelegate
    private var isConfigured = false
    
    private let viewModel: CameraViewModel
    
    // nonisolated => savoir quel est l'executor de l'actor sans devoir entrer dans l'isolation de ce dernier
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        return sessionQueue.asUnownedSerialExecutor()
    }
    
    init(
        viewModel: CameraViewModel,
        onToggle: @escaping @Sendable () -> Void
    ) {
        self.viewModel = viewModel

        self.videoOutputDelegate = VideoOutputDelegate(
            onBrightnessChanged: { newBrightness in
                Task { @MainActor in
                    viewModel.brightness = newBrightness
                }
            },
            onToggle: onToggle
        )
    }
    
    //MARK: - private methods
    
    private func configure() -> Bool {
        // edit config session
        session.beginConfiguration()
        
        defer {
            session.commitConfiguration()
        }
        
        // check si le video device existe et lequel
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              // crée l'input à partir du device
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              self.session.canAddInput(videoDeviceInput)
        else { return false }
                
        // fait la liaison avec la session
        session.addInput(videoDeviceInput)
        
        guard session.canAddOutput(videoDataOutput) else { return false }
        
        // créer l'output pour recevoir les frames de la caméra
        session.addOutput(videoDataOutput)
        
        videoDataOutput.setSampleBufferDelegate(
            videoOutputDelegate,
            queue: frameQueue
        )
        
        return true
    }
    
    // MARK: - methods
    
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
    
    func attachPreviewLayer(_ previewLayer: AVCaptureVideoPreviewLayer) {
        previewLayer.session = session
    }
}
