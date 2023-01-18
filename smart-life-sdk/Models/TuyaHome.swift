//
//  TuyaHome.swift
//  smart-life-sdk
//
//  Created by Sittipong Suwannatrai on 17/1/23.
//

import Foundation
import TuyaSmartDeviceKit

struct TuyaHome {
    static var current: TuyaSmartHomeModel? {
        get {
            let defaults = UserDefaults.standard
            guard let homeID = defaults.string(forKey: "CurrentHome") else { return nil }
            guard let id = Int64(homeID)  else { return nil }
            return TuyaSmartHome.init(homeId: id)?.homeModel
        }
        set {
            let defaults = UserDefaults.standard
            defaults.setValue(newValue?.homeId, forKey: "CurrentHome")
        }
    }
}
