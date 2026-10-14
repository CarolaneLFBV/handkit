//
//  LightDevice.swift
//  HandKit
//
//  Created by Carolane Lefebvre on 12/10/2026.
//

import Foundation
import HomeKit

struct LightDevice: Identifiable {
    let id: UUID
    let name: String
    let powerCharacteristic: HMCharacteristic?
    let brightnessCharacteristic: HMCharacteristic?
}
