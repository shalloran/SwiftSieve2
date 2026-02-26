//
//  DefaultBlockLists.swift
//  SwiftSieveDNS
//

import Foundation

/// single default block list (id, name, bundled .txt filename)
struct DefaultBlockList: Identifiable {
    let id: String
    let name: String
    /// filename without .txt, e.g. "general_ads"
    let filename: String
    let enabledByDefault: Bool
}

/// built-in block lists; load domains from bundled BlockLists/*.txt
enum DefaultBlockLists {
    static let all: [DefaultBlockList] = [
        DefaultBlockList(id: "general_ads", name: "General Marketing", filename: "general_ads", enabledByDefault: true),
        DefaultBlockList(id: "facebook_sdk", name: "Facebook Trackers", filename: "facebook_sdk", enabledByDefault: true),
        DefaultBlockList(id: "data_trackers", name: "Data Trackers", filename: "data_trackers", enabledByDefault: true),
        DefaultBlockList(id: "crypto_mining", name: "Crypto Mining", filename: "crypto_mining", enabledByDefault: false),
        DefaultBlockList(id: "marketing", name: "Marketing Trackers", filename: "marketing", enabledByDefault: true),
        DefaultBlockList(id: "ub_easylist", name: "uBlock: EasyList domains", filename: "ub_easylist", enabledByDefault: false),
        DefaultBlockList(id: "ub_easyprivacy", name: "uBlock: EasyPrivacy domains", filename: "ub_easyprivacy", enabledByDefault: false),
        DefaultBlockList(id: "ub_ublock_ads", name: "uBlock: ads filters domains", filename: "ub_ublock_ads", enabledByDefault: false),
        DefaultBlockList(id: "ub_ublock_privacy", name: "uBlock: privacy filters domains", filename: "ub_ublock_privacy", enabledByDefault: false),
        DefaultBlockList(id: "ub_peter_lowe", name: "uBlock: peter lowe hosts", filename: "ub_peter_lowe", enabledByDefault: false),
        DefaultBlockList(id: "ub_malicious_urlhaus", name: "uBlock: malicious urlhaus domains", filename: "ub_malicious_urlhaus", enabledByDefault: false),
    ]

    /// ids for ublock-derived lists (no per-domain toggles)
    static let uBlockIds: Set<String> = [
        "ub_easylist",
        "ub_easyprivacy",
        "ub_ublock_ads",
        "ub_ublock_privacy",
        "ub_peter_lowe",
        "ub_malicious_urlhaus",
    ]

    /// lists which support per-domain include/exclude in the ui
    static let domainTogglableLists: [DefaultBlockList] = all.filter { !uBlockIds.contains($0.id) }

    /// ublock-derived lists, toggled only at list level
    static let uBlockLists: [DefaultBlockList] = all.filter { uBlockIds.contains($0.id) }

    private static var domainCache: [String: Set<String>] = [:]
    private static let cacheLock = NSLock()

    /// load domain set from bundled .txt (one domain per line; skip empty and #); cached per filename to avoid disk I/O on every access
    static func loadDomains(filename: String, bundle: Bundle = .main) -> Set<String> {
        cacheLock.lock()
        if let cached = domainCache[filename] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()
        let subdirs = ["BlockLists", "SwiftSieveDNS/BlockLists", nil] as [String?]
        var url: URL?
        for sub in subdirs {
            if let s = sub {
                url = bundle.url(forResource: filename, withExtension: "txt", subdirectory: s)
            } else {
                url = bundle.url(forResource: filename, withExtension: "txt")
            }
            if url != nil { break }
        }
        guard let resourceURL = url, let content = try? String(contentsOf: resourceURL, encoding: .utf8) else {
            return []
        }
        let lines = content.components(separatedBy: .newlines)
        var out: Set<String> = []
        for line in lines {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.isEmpty || t.hasPrefix("#") { continue }
            out.insert(t.lowercased())
        }
        cacheLock.lock()
        domainCache[filename] = out
        cacheLock.unlock()
        return out
    }
}
