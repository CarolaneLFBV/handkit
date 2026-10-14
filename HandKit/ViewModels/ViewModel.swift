//
//  ViewModel.swift
//  HandKit
//
//  Created by Carolane Lefebvre on 14/10/2026.
//

import Foundation

@MainActor @Observable
final class ViewModel {
    private let controller: LightController
    private(set) var lights: [LightItem] = []
    private(set) var selectedLightIDs: Set<UUID> = []

    init(controller: LightController) {
        self.controller = controller

        controller.onLightsChanged = { [weak self] discoveredLights in
            self?.updateLights(discoveredLights)
        }

        updateLights(controller.lights)
    }

    //MARK: - Methods
    
    func toggleSelection(for id: UUID) {
        if selectedLightIDs.contains(id) {
            selectedLightIDs.remove(id)
        } else {
            selectedLightIDs.insert(id)
        }
    }
    
    func toggle() async throws {
        try await controller.toggle(for: selectedLightIDs)
    }
    
    func setBrightness(_ brightness: CGFloat) {
        controller.setBrightness(brightness, for: selectedLightIDs)
    }
    
    // MARK: - Private methods
    
    private func updateLights(_ discoveredLights: [LightDevice]) {
        let newLights = discoveredLights.map { light in
            LightItem(id: light.id, name: light.name)
        }

        lights = newLights
    }
}
