import SwiftUI

struct ContentView: View {
    @State private var viewModel: CameraViewModel
    private let cameraManager: CameraManager
    private let lightController: LightController
    
    // Create one instance only of the viewModel for both sides: the camera manager and our current view
    init() {
        let viewModel = CameraViewModel()
        let lightController = LightController()

        self._viewModel = State(initialValue: viewModel)
        self.lightController = lightController

        self.cameraManager = CameraManager(
            viewModel: viewModel,
            onToggle: {
                Task { @MainActor in
                    lightController.toggle()
                }
            }
        )
    }
    
    var body: some View {
        ZStack {
            CameraPreview(cameraManager: cameraManager)
            
            VStack(spacing: 8) {
                Text("Brightness \(Int(viewModel.brightness))%")
                ProgressView(value: viewModel.brightness, total: 100)
            }
            .padding()
        }
        .task {
            await cameraManager.start()
        }
    }
}
