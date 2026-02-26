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
    /// true when save succeeded but system never enabled (timeout); user can tap "Reset and try again"
    @Published private(set) var activationFailed: Bool = false
    /// true when save failed with "permission denied" (TestFlight/App Store blocks DNS proxy creation)
    @Published private(set) var isSavePermissionDenied: Bool = false
    private var activationCheckTimer: DispatchSourceTimer?

    private init() {
        loadPreferences()
    }

    func loadPreferences() {
        manager.loadFromPreferences { [weak self] error in
            Task { @MainActor in
                guard let self = self else { return }
                if let error = error {
                    self.statusDescription = "Error: \(error.localizedDescription)"
                    self.isSavePermissionDenied = false
                    return
                }
                self.isSavePermissionDenied = false
                self.isEnabled = self.manager.isEnabled
                if self.manager.isEnabled && self.manager.providerProtocol != nil {
                    self.activationFailed = false
                }
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

    private func waitForSystemActivation(
        maxWaitSeconds: TimeInterval = 15,
        pollIntervalSeconds: TimeInterval = 1,
        completion: (() -> Void)? = nil
    ) {
        activationCheckTimer?.cancel()

        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        activationCheckTimer = timer

        let deadline = Date().addingTimeInterval(maxWaitSeconds)
        let onComplete = { DispatchQueue.main.async { completion?() } }

        timer.setEventHandler { [weak self] in
            guard let self = self else {
                timer.cancel()
                onComplete()
                return
            }

            if Date() >= deadline {
                timer.cancel()
                DispatchQueue.main.async {
                    self.isEnabled = self.manager.isEnabled
                    self.updateStatusDescription()
                    self.activationFailed = true
                    self.statusDescription = "iOS didn't enable the DNS proxy. Tap 'Reset and try again' to request permission again."
                    completion?()
                }
                return
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.manager.loadFromPreferences { [weak self] error in
                    guard let self = self else { return }
                    if let error = error {
                        timer.cancel()
                        DispatchQueue.main.async {
                            self.statusDescription = "error checking status: \(error.localizedDescription)"
                            completion?()
                        }
                        return
                    }
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        let isNowEnabled = self.manager.isEnabled && self.manager.providerProtocol != nil
                        if isNowEnabled {
                            timer.cancel()
                            self.isEnabled = true
                            self.activationFailed = false
                            self.updateStatusDescription()
                            completion?()
                        }
                    }
                }
            }
        }

        timer.schedule(deadline: .now() + pollIntervalSeconds, repeating: pollIntervalSeconds)
        timer.resume()
    }

    /// clear config then re-apply and save again so iOS may show the permission sheet again
    func resetAndRetryActivation() {
        activationFailed = false
        isRepairing = true
        manager.loadFromPreferences { [weak self] _ in
            guard let self = self else { return }
            self.manager.providerProtocol = nil
            self.manager.isEnabled = false
            self.manager.saveToPreferences { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.enableProxyWithActivationCompletion { self.isRepairing = false }
                }
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
        enableProxyWithActivationCompletion(activationCompletion: nil)
    }

    /// load from system first, then set config and save (recommended before save to avoid permission denied / missing prompt)
    private func enableProxyWithActivationCompletion(activationCompletion: (() -> Void)?) {
        AppGroupConstants.sharedDefaults?.set(true, forKey: AppGroupConstants.Keys.dnsProxyEnabled)
        manager.loadFromPreferences { [weak self] loadError in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let loadError = loadError {
                    self.statusDescription = "Load error: \(loadError.localizedDescription)"
                    return
                }
            }
            let proto = NEDNSProxyProviderProtocol()
            proto.providerBundleIdentifier = Self.providerBundleId
            proto.providerConfiguration = nil
            self.manager.localizedDescription = "SwiftSieve DNS"
            self.manager.providerProtocol = proto
            self.manager.isEnabled = true
            self.manager.saveToPreferences { [weak self] error in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if let error = error {
                        let denied = error.localizedDescription.lowercased().contains("permission denied")
                        self.isSavePermissionDenied = denied
                        self.statusDescription = denied
                            ? "Permission denied (TestFlight/App Store)"
                            : "Save error: \(error.localizedDescription)"
                        activationCompletion?()
                        return
                    }
                    self.isSavePermissionDenied = false
                    self.statusDescription = "saved config, waiting for system..."
                }
                self.waitForSystemActivation(completion: activationCompletion)
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
