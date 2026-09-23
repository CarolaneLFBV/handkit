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
                    lightController.toggle()
                }
            }
        )

        // When HomeKit finishes reading the real brightness,
        // synchronize the gesture system with that value.
        lightController.setBrightnessReadyHandler { brightness in
            await cameraManager.updateCurrentBrightness(brightness)
        }

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
