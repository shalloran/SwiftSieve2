//
//  BlockListStorage.swift
//  SwiftSieveDNS
//

import Foundation

/// block/allowlist storage in app group; app writes, extension reads
struct BlockListStorage {
    private let defaults: UserDefaults?

    init(defaults: UserDefaults? = AppGroupConstants.sharedDefaults) {
        self.defaults = defaults
    }

    /// default domains that start on the allowlist
    static let defaultAllowlistDomains: Set<String> = [
        "apple.com",
        "icloud.com",
        "kagi.com",
        "teams.microsoft.com",
    ]

    var allowlist: Set<String> {
        get {
            guard let defaults, let arr = defaults.array(forKey: AppGroupConstants.Keys.allowlistedDomains) as? [String] else {
                return []
            }
            return Set(arr)
        }
        set {
            defaults?.set(Array(newValue), forKey: AppGroupConstants.Keys.allowlistedDomains)
        }
    }

    mutating func addToAllowlist(_ domain: String) {
        var w = allowlist
        w.insert(domain.lowercased())
        allowlist = w
    }

    mutating func removeFromAllowlist(_ domain: String) {
        var w = allowlist
        w.remove(domain.lowercased())
        allowlist = w
    }

    mutating func seedDefaultAllowlistIfNeeded() {
        guard allowlist.isEmpty else { return }
        allowlist = Self.defaultAllowlistDomains
    }

    var customBlockedDomains: Set<String> {
        get {
            guard let defaults, let arr = defaults.array(forKey: AppGroupConstants.Keys.customBlockedDomains) as? [String] else {
                return []
            }
            return Set(arr.map { $0.lowercased() })
        }
        set {
            defaults?.set(Array(newValue), forKey: AppGroupConstants.Keys.customBlockedDomains)
        }
    }

    mutating func addCustomBlockedDomain(_ domain: String) {
        let d = domain.trimmingCharacters(in: .whitespaces).lowercased()
        guard !d.isEmpty else { return }
        var set = customBlockedDomains
        set.insert(d)
        customBlockedDomains = set
        writeResolvedBlockedDomains()
    }

    mutating func removeCustomBlockedDomain(_ domain: String) {
        var set = customBlockedDomains
        set.remove(domain.lowercased())
        customBlockedDomains = set
        writeResolvedBlockedDomains()
    }

    var blockListDomainIds: Set<String> {
        get {
            guard let defaults, let arr = defaults.array(forKey: AppGroupConstants.Keys.blockListDomainIds) as? [String] else {
                return []
            }
            return Set(arr)
        }
        set {
            defaults?.set(Array(newValue), forKey: AppGroupConstants.Keys.blockListDomainIds)
        }
    }

    mutating func setBlockListEnabled(_ id: String, _ enabled: Bool) {
        var ids = blockListDomainIds
        if enabled { ids.insert(id) } else { ids.remove(id) }
        blockListDomainIds = ids
        writeResolvedBlockedDomains()
    }

    /// domains excluded from blocking for this list (user toggled off in dropdown)
    func excludedDomains(forList listId: String) -> Set<String> {
        guard let defaults,
              let dict = defaults.dictionary(forKey: AppGroupConstants.Keys.blockListExclusions),
              let arr = dict[listId] as? [String] else {
            return []
        }
        return Set(arr.map { $0.lowercased() })
    }

    mutating func setDomainInList(_ listId: String, domain: String, included: Bool) {
        var set = excludedDomains(forList: listId)
        let d = domain.lowercased()
        if included {
            set.remove(d)
        } else {
            set.insert(d)
        }
        var dict = (defaults?.dictionary(forKey: AppGroupConstants.Keys.blockListExclusions) as? [String: [String]]) ?? [:]
        dict[listId] = Array(set)
        defaults?.set(dict, forKey: AppGroupConstants.Keys.blockListExclusions)
        writeResolvedBlockedDomains()
    }

    private func hashDomain(_ s: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        let prime: UInt64 = 0x100000001b3
        for b in s.utf8 {
            hash ^= UInt64(b)
            hash &*= prime
        }
        return hash
    }

    private func writeHashes(_ all: Set<String>, defaults: UserDefaults) {
        var data = Data()
        data.reserveCapacity(all.count * MemoryLayout<UInt64>.size)
        for d in all {
            var h = hashDomain(d)
            h = h.littleEndian
            withUnsafeBytes(of: &h) { data.append(contentsOf: $0) }
        }
        defaults.set(data, forKey: AppGroupConstants.Keys.resolvedBlockedDomainHashes)
        defaults.removeObject(forKey: AppGroupConstants.Keys.resolvedBlockedDomains)
    }

    /// write merged blocklist to app group so extension can read it (async, for list changes)
    func writeResolvedBlockedDomains() {
        let def = defaults
        DispatchQueue.global(qos: .userInitiated).async {
            guard let defaults = def else { return }
            let storage = BlockListStorage(defaults: defaults)
            let all = storage.getAllBlockedDomains()
            storage.writeHashes(all, defaults: defaults)
        }
    }

    /// write merged blocklist on app group queue then run completion on main (avoids sync I/O on main / unsafeForcedSync)
    func writeResolvedBlockedDomainsThen(onQueue queue: DispatchQueue = AppGroupConstants.appGroupQueue, mainCompletion: @escaping () -> Void) {
        let def = defaults
        let all = getAllBlockedDomains()
        queue.async {
            if let defaults = def {
                let storage = BlockListStorage(defaults: defaults)
                storage.writeHashes(all, defaults: defaults)
            }
            DispatchQueue.main.async { mainCompletion() }
        }
    }

    func getAllBlockedDomains() -> Set<String> {
        var all = customBlockedDomains
        for list in DefaultBlockLists.all where blockListDomainIds.contains(list.id) {
            let listDomains = DefaultBlockLists.loadDomains(filename: list.filename)
            let excluded = excludedDomains(forList: list.id)
            all.formUnion(listDomains.subtracting(excluded))
        }
        return all.subtracting(allowlist)
    }

    func getIsCombinedBlockListEmpty() -> Bool {
        getAllBlockedDomains().isEmpty
    }

    /// which list (by display name) a blocked domain came from, or "Custom"
    func sourceName(for domain: String) -> String {
        let d = domain.lowercased()
        if customBlockedDomains.contains(d) { return "Custom" }
        for list in DefaultBlockLists.all where blockListDomainIds.contains(list.id) {
            let listDomains = DefaultBlockLists.loadDomains(filename: list.filename)
            if listDomains.contains(d) && !excludedDomains(forList: list.id).contains(d) { return list.name }
        }
        return "Unknown"
    }
}
