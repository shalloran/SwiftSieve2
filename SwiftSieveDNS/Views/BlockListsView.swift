//
//  BlockListsView.swift
//  SwiftSieveDNS
//

import SwiftUI

struct BlockListsView: View {
    @State private var storage = BlockListStorage()
    @State private var customDomain: String = ""

    var body: some View {
        List {
            Section(header: Text("Default lists")) {
                ForEach(DefaultBlockLists.all) { list in
                    Toggle(list.name, isOn: bindingForList(id: list.id))
                }
            }
            Section(header: Text("Custom blocked domains")) {
                HStack {
                    TextField("domain to block", text: $customDomain)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    Button("Add") {
                        storage.addCustomBlockedDomain(customDomain)
                        customDomain = ""
                    }
                    .disabled(customDomain.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ForEach(Array(storage.customBlockedDomains).sorted(), id: \.self) { domain in
                    HStack {
                        Text(domain)
                        Spacer()
                        Button("Remove") {
                            storage.removeCustomBlockedDomain(domain)
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("Block lists")
        .onAppear {
            storage = BlockListStorage()
        }
    }

    private func bindingForList(id: String) -> Binding<Bool> {
        Binding(
            get: { storage.blockListDomainIds.contains(id) },
            set: { storage.setBlockListEnabled(id, $0) }
        )
    }
}
