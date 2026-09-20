//
//  LightController.swift
//  HandKit
//
//  Created by Carolane Lefebvre on 20/09/2026.
//

import HomeKit

final class LightController: NSObject, HMHomeManagerDelegate {
    private let homeManager = HMHomeManager()
    private var powerCharacteristic: HMCharacteristic?
    private var brightnessCharacteristic: HMCharacteristic?
    
    override init() {
        super.init()
        homeManager.delegate = self
    }

    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        // Find the accessory named "Lamp"
        guard let accessory = manager.homes
            .flatMap(\.accessories)
            .first(where: { $0.name == "Lamp" })
        else {
            print("Lamp not found")
            return
        }

        // Find the light service
        guard let lightService = accessory.services.first(
            where: { $0.serviceType == HMServiceTypeLightbulb }
        ) else {
            print("Light service not found")
            return
        }

        // Find the characteristics we need
        for characteristic in lightService.characteristics {
            if characteristic.characteristicType == HMCharacteristicTypePowerState {
                powerCharacteristic = characteristic
            }

            if characteristic.characteristicType == HMCharacteristicTypeBrightness {
                brightnessCharacteristic = characteristic
            }
        }
    }
    
    private func setPower(
        _ isOn: Bool,
        characteristic: HMCharacteristic
    ) {
        characteristic.writeValue(isOn) { error in
            if let error {
                print("Failed to change power state:", error)
                return
            }

            print("Power changed:", isOn)
        }
    }
    
    func toggle() {
        guard let powerCharacteristic else {
            return
        }

        powerCharacteristic.readValue { error in
            if let error {
                print("Failed to read power state:", error)
                return
            }

            guard let value = powerCharacteristic.value as? NSNumber else {
                return
            }

            let isOn = value.boolValue
            let newState = !isOn

            powerCharacteristic.writeValue(newState) { error in
                if let error {
                    print("Failed to change power state:", error)
                    return
                }

                print("Power changed:", newState)
            }
        }
    }
}
