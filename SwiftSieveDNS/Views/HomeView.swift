//
//  HomeView.swift
//  SwiftSieveDNS
//

import SwiftUI

struct HomeView: View {
    @StateObject private var proxy = DNSProxyController.shared
    @State private var storage = BlockListStorage()
    @State private var customDomain: String = ""
    /// cached so we don't run getAllBlockedDomains() (and disk I/O) on every keystroke
    @State private var isBlockListEmpty: Bool = true
    /// which block list dropdown is expanded (one at a time)
    @State private var expandedListId: String? = nil

    var body: some View {
        NavigationView {
            List {
                Section {
                    Toggle("DNS proxy", isOn: Binding(
                        get: { proxy.isEnabled },
                        set: { enabled in
                            if enabled {
                                if !isBlockListEmpty {
                                    storage.writeResolvedBlockedDomainsThen { DNSProxyController.shared.enableProxy() }
                                }
                            } else {
                                proxy.disableProxy()
                            }
                        }
                    ))
                    .disabled(isBlockListEmpty)
                    HStack {
                        Text("Status")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(proxy.statusDescription)
                            .foregroundColor(.secondary)
                    }
                    if isBlockListEmpty {
                        Text("Add at least one block list below to enable the proxy.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    if proxy.statusDescription != "Not configured" {
                        Button {
                            proxy.reapplyConfiguration()
                        } label: {
                            HStack {
                                if proxy.isRepairing {
                                    Text("Repairing…")
                                    Spacer()
                                } else {
                                    Text("Repair configuration")
                                    Spacer()
                                    Text("Use if Settings shows Invalid")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .disabled(proxy.isRepairing)
                    }
                } header: {
                    Text("Status")
                }

                Section {
                    ForEach(DefaultBlockLists.all) { list in
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedListId == list.id },
                                set: { expandedListId = $0 ? list.id : nil }
                            ),
                            content: {
                                ForEach(Array(DefaultBlockLists.loadDomains(filename: list.filename)).sorted(), id: \.self) { domain in
                                    Toggle(domain, isOn: domainIncludedBinding(listId: list.id, domain: domain))
                                }
                            },
                            label: {
                                HStack {
                                    Text(list.name)
                                    Spacer()
                                    Toggle("", isOn: bindingForList(id: list.id))
                                        .labelsHidden()
                                }
                            }
                        )
                    }
                } header: {
                    Text("Block lists")
                } footer: {
                    Text("Expand a list to include or exclude individual domains. Off = domain not blocked even when list is on.")
                }

                Section {
                    HStack {
                        TextField("Domain to block", text: $customDomain)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                        Button("Add") {
                            storage.addCustomBlockedDomain(customDomain)
                            customDomain = ""
                            refreshBlockListEmpty()
                            dismissKeyboard()
                        }
                        .disabled(customDomain.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    ForEach(Array(storage.customBlockedDomains).sorted(), id: \.self) { domain in
                        HStack {
                            Text(domain)
                            Spacer()
                            Button("Remove") {
                                storage.removeCustomBlockedDomain(domain)
                                refreshBlockListEmpty()
                            }
                            .foregroundColor(.red)
                        }
                    }
                } header: {
                    Text("Custom blocked domains")
                }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationViewStyle(.stack)
            .navigationTitle("SwiftSieve DNS")
            .onAppear {
                storage = BlockListStorage()
                seedDefaultBlockListsIfNeeded()
                refreshBlockListEmpty()
                DNSProxyController.shared.loadPreferences()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                DNSProxyController.shared.loadPreferences()
            }
        }
    }

    private func bindingForList(id: String) -> Binding<Bool> {
        Binding(
            get: { storage.blockListDomainIds.contains(id) },
            set: { enabled in
                storage.setBlockListEnabled(id, enabled)
                refreshBlockListEmpty()
            }
        )
    }

    /// true = domain is included (blocked when list is on), false = excluded
    private func domainIncludedBinding(listId: String, domain: String) -> Binding<Bool> {
        Binding(
            get: { !storage.excludedDomains(forList: listId).contains(domain.lowercased()) },
            set: { included in
                storage.setDomainInList(listId, domain: domain, included: included)
                refreshBlockListEmpty()
            }
        )
    }

    private func refreshBlockListEmpty() {
        isBlockListEmpty = storage.getIsCombinedBlockListEmpty()
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    /// on first launch, enable default lists so resolved list includes them without user toggling
    private func seedDefaultBlockListsIfNeeded() {
        guard storage.blockListDomainIds.isEmpty else { return }
        var ids = storage.blockListDomainIds
        for list in DefaultBlockLists.all where list.enabledByDefault {
            ids.insert(list.id)
        }
        if !ids.isEmpty {
            storage.blockListDomainIds = ids
            storage.writeResolvedBlockedDomains()
        }
    }
}

#Preview {
    HomeView()
}
