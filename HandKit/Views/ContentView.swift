import SwiftUI

struct ContentView: View {
    @State private var viewModel: ViewModel
    @State private var cameraManager: CameraManager

    init() {
        let lightController = LightController()
        let viewModel = ViewModel(controller: lightController)
        
        _viewModel = State(initialValue: viewModel)
        _cameraManager = State(initialValue: CameraManager(
            onBrightnessChanged: { brightness in
                Task { @MainActor in
                    viewModel.setBrightness(brightness)
                }
            },
            onToggle: {
                Task { @MainActor in
                    do {
                        try await viewModel.toggle()
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        ))
    }

    var body: some View {
        VStack {
            CameraPreview(
                cameraManager: cameraManager
            )
            
            List(viewModel.lights) { light in
                Button {
                    viewModel.toggleSelection(for: light.id)
                } label: {
                    HStack {
                        Text(light.name)
                        if viewModel.selectedLightIDs.contains(light.id) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
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
