//
//  DNSProxyController.swift
//  SwiftSieveDNS
//

import Foundation
import NetworkExtension

/// uses NEDNSProxyManager to install/enable the DNS proxy (no VPN APIs)
@MainActor
final class DNSProxyController: ObservableObject {
    static let shared = DNSProxyController()

    /// extension bundle id — must match DNS Proxy extension target
    private static let providerBundleId = "topiaria.llc.SwiftSieveDNS.SwiftSieveDNSProxy"

    private let manager = NEDNSProxyManager.shared()
    @Published private(set) var isEnabled: Bool = false
    @Published private(set) var statusDescription: String = "Not configured"
    @Published private(set) var isRepairing: Bool = false

    private init() {
        loadPreferences()
    }

    func loadPreferences() {
        manager.loadFromPreferences { [weak self] error in
            Task { @MainActor in
                guard let self = self else { return }
                if let error = error {
                    self.statusDescription = "Error: \(error.localizedDescription)"
                    return
                }
                self.isEnabled = self.manager.isEnabled
                self.updateStatusDescription()
                // if system may have marked config invalid, re-apply to repair
                if self.configLooksInvalid() {
                    self.reapplyConfiguration()
                }
            }
        }
    }

    /// true when we're enabled but config is missing or wrong (e.g. Settings shows "Invalid")
    private func configLooksInvalid() -> Bool {
        guard manager.isEnabled else { return false }
        guard let proto = manager.providerProtocol else { return true }
        return proto.providerBundleIdentifier != Self.providerBundleId
    }

    private func updateStatusDescription() {
        if manager.providerProtocol == nil {
            statusDescription = "Not configured"
        } else if manager.isEnabled {
            statusDescription = "Connected"
        } else {
            statusDescription = "Disconnected"
        }
    }

    /// re-save current config to clear "Invalid" in Settings (load then save)
    func reapplyConfiguration() {
        isRepairing = true
        manager.loadFromPreferences { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.applyCurrentConfigAndSave { self.isRepairing = false }
            }
        }
    }

    /// set provider protocol and description from our bundle id, then save (keeps current isEnabled)
    private func applyCurrentConfigAndSave(completion: @escaping () -> Void) {
        let proto = NEDNSProxyProviderProtocol()
        proto.providerBundleIdentifier = Self.providerBundleId
        proto.providerConfiguration = nil
        manager.localizedDescription = "SwiftSieve DNS"
        manager.providerProtocol = proto
        manager.isEnabled = isEnabled
        manager.saveToPreferences { [weak self] error in
            Task { @MainActor in
                if let error = error {
                    self?.statusDescription = "Save error: \(error.localizedDescription)"
                } else {
                    self?.isEnabled = self?.manager.isEnabled ?? false
                    self?.updateStatusDescription()
                }
                completion()
            }
        }
    }

    /// create/save config and enable proxy (call after writing resolved blocklist to app group)
    func enableProxy() {
        AppGroupConstants.sharedDefaults?.set(true, forKey: AppGroupConstants.Keys.dnsProxyEnabled)
        let proto = NEDNSProxyProviderProtocol()
        proto.providerBundleIdentifier = Self.providerBundleId
        proto.providerConfiguration = nil
        manager.localizedDescription = "SwiftSieve DNS"
        manager.providerProtocol = proto
        manager.isEnabled = true
        manager.saveToPreferences { [weak self] error in
            Task { @MainActor in
                if let error = error {
                    self?.statusDescription = "Save error: \(error.localizedDescription)"
                    return
                }
                self?.isEnabled = true
                self?.updateStatusDescription()
            }
        }
    }

    func disableProxy() {
        AppGroupConstants.sharedDefaults?.set(false, forKey: AppGroupConstants.Keys.dnsProxyEnabled)
        manager.isEnabled = false
        manager.saveToPreferences { [weak self] error in
            Task { @MainActor in
                if let error = error {
                    self?.statusDescription = "Save error: \(error.localizedDescription)"
                    return
                }
                self?.isEnabled = false
                self?.updateStatusDescription()
            }
        }
    }
}
