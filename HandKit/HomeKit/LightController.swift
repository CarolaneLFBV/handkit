import HomeKit


@MainActor 
final class LightController: NSObject, HMHomeManagerDelegate {
    // MARK: - HomeKit
    private let homeManager = HMHomeManager()
    private(set) var lights: [LightDevice] = []
    private(set) var selectedLightIDs: Set<UUID> = []
    
    private var selectedLights: [LightDevice] {
        lights.filter { selectedLightIDs.contains($0.id) }
    }
    
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
    }
    
    // MARK: - HomeKit
    func toggleSelection(for id: UUID) {
        if selectedLightIDs.contains(id) {
            selectedLightIDs.remove(id)
        } else {
            selectedLightIDs.insert(id)
        }
    }
    
    // MARK: - Power
    func toggle() async throws {
        var powerStates: [Bool] = []
        let powerCharacteristics = selectedLights.compactMap({$0.powerCharacteristic})
        
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
    func setBrightness(_ brightness: CGFloat) {
        let clampedBrightness = min(max(brightness, 0), 100)
        let value = NSNumber(value: Double(clampedBrightness))
        
        for light in selectedLights {
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
