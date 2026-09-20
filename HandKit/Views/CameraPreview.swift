//
//  CameraPreview.swift
//  HandKit
//
//  Created by Carolane Lefebvre on 19/09/2026.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let cameraManager: CameraManager
    
    // créer/config UIView initiale
    func makeUIView(context: Context) -> UIView {
        let view = PreviewView()
        
        Task {
            await cameraManager.attachPreviewLayer(view.previewLayer)
        }
        
        return view
    }
    
    // update UIView si SwiftUI change son état
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}
