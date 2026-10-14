import HomeKit


@MainActor 
final class LightController: NSObject, HMHomeManagerDelegate {
    // MARK: - HomeKit
    private let homeManager = HMHomeManager()
    private(set) var lights: [LightDevice] = []
    
    var onLightsChanged: (([LightDevice]) -> Void)?
    
    // MARK: - State
    private(set) var isReady = false
    private var onBrightnessReady: (@Sendable (CGFloat) async -> Void)?
    
    // MARK: - Errors
    private enum PowerStateError: Error {
        case invalidValue
    }
    
    // MARK: - Init
    override init() {
        super.init()
        homeManager.delegate = self
    }
    
    // MARK: - Discovery
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        var discoveredLights: [LightDevice] = []
        
        let accessories = manager.homes.flatMap(\.accessories)
        
        for accessory in accessories {
            guard let lightService = accessory.services.first(where: {
                $0.serviceType == HMServiceTypeLightbulb
            }) else {
                continue
            }
            
            var power: HMCharacteristic?
            var brightness: HMCharacteristic?
            
            for characteristic in lightService.characteristics
            {
                switch characteristic.characteristicType {
                case HMCharacteristicTypePowerState:
                    power = characteristic
                    
                case HMCharacteristicTypeBrightness:
                    brightness =
                    characteristic
                    
                default:
                    break
                }
            }
            
            let light = LightDevice(
                id: accessory.uniqueIdentifier,
                name: accessory.name,
                powerCharacteristic: power,
                brightnessCharacteristic: brightness
            )
            
            discoveredLights.append(light)
        }
        
        lights = discoveredLights
        onLightsChanged?(lights)
    }
    
    // MARK: - HomeKit
    func selectedLights(for ids: Set<UUID>) -> [LightDevice] {
        lights.filter { ids.contains($0.id) }
    }
    
    // MARK: - Power
    func toggle(for ids: Set<UUID>) async throws {
        var powerStates: [Bool] = []
        let powerCharacteristics = selectedLights(for: ids).compactMap(\.powerCharacteristic)
        
        guard !powerCharacteristics.isEmpty else { return }
        
        for power in powerCharacteristics {
            let reading = try await readPowerState(characteristic: power)
            powerStates.append(reading)
        }
        
        let allAreOn = powerStates.allSatisfy { state in
            state
        }
        
        if allAreOn {
            for power in powerCharacteristics {
                try await power.writeValue(false)
            }
        } else {
            for power in powerCharacteristics {
                try await power.writeValue(true)
            }
        }
    }
    
    
    func readPowerState(characteristic: HMCharacteristic) async throws -> Bool {
        try await characteristic.readValue()
        
        guard let value = characteristic.value as? NSNumber else {
            throw PowerStateError.invalidValue
        }
        
        return value.boolValue
    }
    
    // MARK: - Brightness
    func setBrightness(_ brightness: CGFloat, for ids: Set<UUID>) {
        let clampedBrightness = min(max(brightness, 0), 100)
        let value = NSNumber(value: Double(clampedBrightness))
        let lights = selectedLights(for: ids)
        
        for light in lights {
            guard let brightnessCharacteristic = light.brightnessCharacteristic else { continue }
            brightnessCharacteristic.writeValue(value) { error in
                if let error {
                    print("Failed to change brightness:", error)
                    return
                }
            }
        }
    }
}
