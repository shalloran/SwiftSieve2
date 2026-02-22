//
//  AppGroupConstants.swift
//  SwiftSieveDNS
//

import Foundation

enum AppGroupConstants {
    static let appGroupId = "group.topiaria.llc.SwiftSieveDNS"

    enum Keys {
        static let dnsProxyEnabled = "dns_proxy_enabled"
        static let allowlistedDomains = "allowlisted_domains"
        static let blockListDomainIds = "block_list_domain_ids"
        /// per-list excluded domains: [listId: [domain, ...]] — domains in list that user turned off
        static let blockListExclusions = "block_list_exclusions"
        static let customBlockedDomains = "custom_blocked_domains"
        /// app writes merged block list here so extension can read it
        static let resolvedBlockedDomains = "resolved_blocked_domains"
        /// extension appends "timestamp,domain"; app reads for block log
        static let blockLogEntries = "block_log_entries"
    }

    /// serial queue for app-group access to avoid CFPrefs/concurrency warnings
    static let appGroupQueue = DispatchQueue(label: "group.topiaria.llc.SwiftSieveDNS.appgroup", qos: .userInitiated)

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }
}
