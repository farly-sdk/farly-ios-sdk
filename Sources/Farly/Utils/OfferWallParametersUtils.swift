//
//  OfferWallParametersUtils.swift
//  Farly
//
//  Created by Philippe Auriach on 31/01/2022.
//

import UIKit
import AdSupport
import Foundation
import CoreTelephony
import AppTrackingTransparency

public enum Device: String {
    case iPhone = "iphone"
    case iPod = "ipod"
    case iPad = "ipad"
    case Unknown = "unknown"
}

class OfferWallParametersUtils {
    
    static func getCurrentDevice() -> Device {
        let name = UIDevice.current.model.replacingOccurrences(of: "Simulator", with: "")
        
        switch name {
        case _ where name.starts(with: "iPad"):
            return .iPad
        case _ where name.starts(with: "iPod"):
            return .iPod
        case _ where name.starts(with: "iPhone"):
            return .iPhone
        default:
            return .Unknown
        }
    }

    static func getIDFA() -> String? {
        
        if #available(iOS 14, *) {
            if ATTrackingManager.trackingAuthorizationStatus != .authorized {
                return nil
            }
        } else {
            if !ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
                return nil
            }
        }
        
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
    
    static func getLocale() -> Locale {
        if let preferred = Locale.preferredLanguages.first {
            return Locale(identifier: preferred)
        }
        return Locale.current
    }
    
    static func getCountryCode() -> String? {
        for pref in Locale.preferredLanguages {
            if let countryCode = Locale(identifier: pref).regionCode {
                return countryCode
            }
        }
        return Locale.current.regionCode
    }
    
    static func getCarrierCode() -> String? {
        let networkInfo = CTTelephonyNetworkInfo()
        if #available(iOS 12.0, *) {
            let carriers = networkInfo.serviceSubscriberCellularProviders

            if let carrier = carriers?.values.first(where: { $0.carrierName != nil }) {
                if let MCC = carrier.mobileCountryCode, let MNC = carrier.mobileNetworkCode {
                    return "\(MCC)-\(MNC)"
                }
            }
        }
        // Fallback on earlier versions
        if let carrier = networkInfo.subscriberCellularProvider {
            if let MCC = carrier.mobileCountryCode, let MNC = carrier.mobileNetworkCode {
                return "\(MCC)-\(MNC)"
            }
        }

        return nil
    }
    
    static func getDeviceModelCode() -> String? {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
