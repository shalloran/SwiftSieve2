//
//  DNSProxyProvider.swift
//  SwiftSieveDNSProxy
//

import NetworkExtension
import os.log

class DNSProxyProvider: NEDNSProxyProvider {

    private let log = OSLog(subsystem: "topiaria.llc.SwiftSieveDNS.SwiftSieveDNSProxy", category: "DNSProxy")
    private var blockedDomains: Set<String> = []
    private var allowlist: Set<String> = []
    private let doh = DoHClient()

    override func startProxy(options: [String: Any]?, completionHandler: @escaping (Error?) -> Void) {
        loadBlocklistFromAppGroup()
        completionHandler(nil)
    }

    override func stopProxy(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    override func handleNewUDPFlow(_ flow: NEAppProxyUDPFlow, initialRemoteEndpoint remoteEndpoint: NWEndpoint) -> Bool {
        handleUDPFlow(flow)
        return true
    }

    private func loadBlocklistFromAppGroup() {
        let defaults = UserDefaults(suiteName: "group.topiaria.llc.SwiftSieveDNS")
        if let arr = defaults?.array(forKey: "resolved_blocked_domains") as? [String] {
            blockedDomains = Set(arr.map { $0.lowercased() })
        } else {
            blockedDomains = []
        }
        if let arr = defaults?.array(forKey: "allowlisted_domains") as? [String] {
            allowlist = Set(arr.map { $0.lowercased() })
        } else {
            allowlist = []
        }
    }

    private func isBlocked(_ queryName: String) -> Bool {
        if allowlist.contains(queryName) { return false }
        if blockedDomains.contains(queryName) { return true }
        var check = queryName
        while let dot = check.firstIndex(of: ".") {
            check = String(check[check.index(after: dot)...])
            if blockedDomains.contains(check) { return true }
        }
        return false
    }

    private func appendBlockLog(domain: String) {
        let entry = "\(Date().timeIntervalSince1970),\(domain)"
        let defaults = UserDefaults(suiteName: "group.topiaria.llc.SwiftSieveDNS")
        var arr = (defaults?.array(forKey: "block_log_entries") as? [String]) ?? []
        arr.append(entry)
        if arr.count > 500 { arr.removeFirst(arr.count - 500) }
        defaults?.set(arr, forKey: "block_log_entries")
    }

    private func handleUDPFlow(_ flow: NEAppProxyUDPFlow) {
        flow.open(withLocalEndpoint: nil) { [weak self] error in
            guard let self = self, error == nil else { return }
            self.readAndHandleDatagrams(flow)
        }
    }

    private func readAndHandleDatagrams(_ flow: NEAppProxyUDPFlow) {
        flow.readDatagrams { [weak self] datagrams, remoteEndpoints, error in
            guard let self = self else { return }
            if let error = error {
                os_log(.error, log: self.log, "read error: %{public}@", error.localizedDescription)
                flow.closeReadWithError(error)
                return
            }
            guard let packets = datagrams, let endpoints = remoteEndpoints, !packets.isEmpty else {
                flow.closeReadWithError(nil)
                return
            }
            Task {
                for (i, packet) in packets.enumerated() {
                    let endpoint = i < endpoints.count ? endpoints[i] : endpoints.last
                    await self.handleOneDatagram(packet, flow: flow, remoteEndpoint: endpoint)
                }
                self.readAndHandleDatagrams(flow)
            }
        }
    }

    private func handleOneDatagram(_ data: Data, flow: NEAppProxyUDPFlow, remoteEndpoint: NWEndpoint?) async {
        guard let msg = DNSMessage.parseQuery(data) else {
            if let ep = remoteEndpoint { flow.writeDatagrams([data], sentBy: [ep]) { _ in } }
            return
        }
        loadBlocklistFromAppGroup()
        if isBlocked(msg.queryName) {
            appendBlockLog(domain: msg.queryName)
            let response = msg.buildNXDOMAINResponse()
            if let ep = remoteEndpoint {
                flow.writeDatagrams([response], sentBy: [ep]) { _ in }
            }
            return
        }
        if let response = await doh.resolve(queryData: data), let ep = remoteEndpoint {
            flow.writeDatagrams([response], sentBy: [ep]) { _ in }
        } else if let ep = remoteEndpoint {
            let fallback = msg.buildNXDOMAINResponse()
            flow.writeDatagrams([fallback], sentBy: [ep]) { _ in }
        }
    }
}
