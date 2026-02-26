//
//  AllowlistView.swift
//  SwiftSieveDNS
//

import SwiftUI

struct AllowlistView: View {
    @State private var storage = BlockListStorage()
    @State private var newDomain: String = ""

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        TextField("Domain to allow", text: $newDomain)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                        Button("Add") {
                            storage.addToAllowlist(newDomain)
                            newDomain = ""
                            dismissKeyboard()
                        }
                        .disabled(newDomain.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("Add domain")
                } footer: {
                    Text("Domains on the allowlist are never blocked, even if they appear in a block list.")
                }

                Section {
                    if storage.allowlist.isEmpty {
                        Text("No allowlist entries")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(Array(storage.allowlist).sorted(), id: \.self) { domain in
                            HStack {
                                Label(domain, systemImage: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Spacer()
                                Button("Remove") {
                                    storage.removeFromAllowlist(domain)
                                }
                                .foregroundColor(.red)
                            }
                        }
                    }
                } header: {
                    Text("Allowed domains")
                }
            }
            .navigationTitle("Allowlist")
            .navigationViewStyle(.stack)
            .onAppear {
                storage = BlockListStorage()
                storage.seedDefaultAllowlistIfNeeded()
            }
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    AllowlistView()
}
