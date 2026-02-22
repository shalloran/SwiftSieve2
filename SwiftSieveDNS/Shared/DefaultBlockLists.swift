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
    ]

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
