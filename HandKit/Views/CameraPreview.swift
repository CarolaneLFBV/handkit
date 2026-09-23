import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let cameraManager: CameraManager

    func makeUIView(
        context: Context
    ) -> UIView {
        let view = PreviewView()

        Task {
            await cameraManager
                .attachPreviewLayer(
                    view.previewLayer
                )
        }

        return view
    }

    func updateUIView(
        _ uiView: UIView,
        context: Context
    ) {
    }
}
