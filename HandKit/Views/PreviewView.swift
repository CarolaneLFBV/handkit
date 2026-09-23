import AVFoundation
import UIKit

final class PreviewView: UIView {
    let previewLayer: AVCaptureVideoPreviewLayer

    override init(
        frame: CGRect
    ) {
        previewLayer =
            AVCaptureVideoPreviewLayer()

        super.init(frame: frame)

        previewLayer.videoGravity =
            .resizeAspectFill

        layer.addSublayer(previewLayer)
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError(
            "init(coder:) has not been implemented"
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        previewLayer.frame = bounds
    }
}
