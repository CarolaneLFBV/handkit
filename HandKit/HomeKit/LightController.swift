import HomeKit

@MainActor
final class LightController: NSObject, HMHomeManagerDelegate {
    // MARK: - HomeKit

    private let homeManager = HMHomeManager()

    private var powerCharacteristic: HMCharacteristic?

    private var brightnessCharacteristic: HMCharacteristic?

    // MARK: - State

    private(set) var currentBrightness: CGFloat = 0

    private(set) var isReady = false
    
    private var onBrightnessReady: (@Sendable (CGFloat) async -> Void)?

    // MARK: - Init

    override init() {
        super.init()
        homeManager.delegate = self
    }

    // MARK: - Discovery

    func homeManagerDidUpdateHomes(
        _ manager: HMHomeManager
    ) {
        guard let accessory = manager.homes
            .flatMap(\.accessories)
            .first(where: { $0.name == "Lamp" })
        else {
            print("Lamp not found")
            return
        }

        guard let lightService =
            accessory.services.first(
                where: {
                    $0.serviceType ==
                    HMServiceTypeLightbulb
                }
            )
        else {
            print("Light service not found")
            return
        }

        for characteristic
        in lightService.characteristics
        {
            switch characteristic.characteristicType {
            case HMCharacteristicTypePowerState:
                powerCharacteristic = characteristic

            case HMCharacteristicTypeBrightness:
                brightnessCharacteristic =
                    characteristic

            default:
                break
            }
        }

        readBrightness()
    }

    // MARK: - Power

    func toggle() {
        guard let powerCharacteristic else {
            return
        }

        powerCharacteristic.readValue {
            error in

            if let error {
                print(
                    "Failed to read power state:",
                    error
                )
                return
            }

            guard let value =
                powerCharacteristic.value
                    as? NSNumber
            else {
                return
            }

            let newState = !value.boolValue

            powerCharacteristic.writeValue(
                newState
            ) { error in
                if let error {
                    print(
                        "Failed to change power state:",
                        error
                    )
                }
            }
        }
    }

    // MARK: - Brightness

    func readBrightness() {
        guard let brightnessCharacteristic else {
            return
        }

        brightnessCharacteristic.readValue { [weak self] error in
            if let error {
                print("Failed to read brightness:", error)
                return
            }

            guard let value = brightnessCharacteristic.value as? NSNumber else {
                return
            }

            let brightness = CGFloat(value.doubleValue)

            Task { @MainActor [weak self] in
                guard let self else {
                    return
                }

                self.currentBrightness = brightness
                self.isReady = true
                
                if let onBrightnessReady = self.onBrightnessReady {
                    Task {
                        await onBrightnessReady(brightness)
                    }
                }
            }
        }
    }

    func setBrightness(_ brightness: CGFloat) {
        guard let brightnessCharacteristic else {
            return
        }

        let clampedBrightness = min(max(brightness, 0), 100)
        let value = NSNumber(value: Double(clampedBrightness))

        brightnessCharacteristic.writeValue(value) { [weak self] error in
            if let error {
                print("Failed to change brightness:", error)
                return
            }

            Task { @MainActor [weak self] in
                self?.currentBrightness = clampedBrightness
            }
        }
    }
    
    func setBrightnessReadyHandler(
        _ handler: @escaping @Sendable (CGFloat) async -> Void
    ) {
        onBrightnessReady = handler
    }
}
