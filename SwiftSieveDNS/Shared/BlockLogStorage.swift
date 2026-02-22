//
//  BlockLogStorage.swift
//  SwiftSieveDNS
//

import Foundation

/// reads block log from app group (extension writes when blocking)
enum BlockLogStorage {
    private static var defaults: UserDefaults? { AppGroupConstants.sharedDefaults }

    static func getEntries() -> [String] {
        guard let defaults,
              let arr = defaults.array(forKey: AppGroupConstants.Keys.blockLogEntries) as? [String] else {
            return []
        }
        return arr
    }

    static func clear() {
        defaults?.set([], forKey: AppGroupConstants.Keys.blockLogEntries)
    }
}
