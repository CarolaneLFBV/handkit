import SwiftUI

struct ContentView: View {
    private let cameraManager: CameraManager
    private let lightController: LightController

    init() {
        let lightController = LightController()

        let cameraManager = CameraManager(
            onBrightnessChanged: { brightness in
                Task { @MainActor in
                    lightController.setBrightness(brightness)
                }
            },
            onToggle: {
                Task { @MainActor in
                    do {
                        try await lightController.toggle()
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        )
        self.lightController = lightController
        self.cameraManager = cameraManager
    }

    var body: some View {
        CameraPreview(
            cameraManager: cameraManager
        )
        .ignoresSafeArea()
        .task {
            await cameraManager.start()
        }
        .onDisappear {
            Task {
                await cameraManager.stop()
            }
        }
    }
}
