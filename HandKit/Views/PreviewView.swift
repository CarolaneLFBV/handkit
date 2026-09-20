//
//  PreviewView.swift
//  HandKit
//
//  Created by Carolane Lefebvre on 19/09/2026.
//

import AVFoundation
import UIKit

final class PreviewView: UIView {
    let previewLayer = AVCaptureVideoPreviewLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)

        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // bounds = zone view dans son propre système de coordonnées.
        previewLayer.frame = bounds
    }
}
