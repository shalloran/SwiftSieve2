//
//  BlockLogView.swift
//  SwiftSieveDNS
//

import SwiftUI

struct BlockLogView: View {
    @State private var entries: [String] = BlockLogStorage.getEntries()
    @State private var storage = BlockListStorage()

    var body: some View {
        NavigationView {
            List {
                if entries.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.shield")
                                .font(.system(size: 44))
                                .foregroundColor(.secondary)
                            Text("No blocks yet")
                                .font(.headline)
                            Text("Blocked queries will appear here with time and which list caused the block.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                } else {
                    Section {
                        ForEach(entries.reversed(), id: \.self) { entry in
                            blockLogRow(entry)
                        }
                    } header: {
                        Text("Recent blocks")
                    } footer: {
                        Text("Newest at top. Source is the block list that matched the domain.")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Block log")
            .navigationViewStyle(.stack)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") {
                        BlockLogStorage.clear()
                        entries = BlockLogStorage.getEntries()
                    }
                    .disabled(entries.isEmpty)
                }
            }
            .onAppear {
                entries = BlockLogStorage.getEntries()
                storage = BlockListStorage()
            }
        }
    }

    private func blockLogRow(_ entry: String) -> some View {
        let parts = entry.split(separator: ",", maxSplits: 1)
        let timeStr = parts.first.map(String.init) ?? ""
        let domain = parts.count > 1 ? String(parts[1]) : ""
        let (timeFormatted, sourceName) = parseEntry(timeStr: timeStr, domain: domain)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(domain)
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
            }
            HStack(spacing: 8) {
                Label(timeFormatted, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("·")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Label(sourceName, systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func parseEntry(timeStr: String, domain: String) -> (String, String) {
        let formatted: String = {
            guard let t = Double(timeStr) else { return "—" }
            let d = Date(timeIntervalSince1970: t)
            let f = DateFormatter()
            f.dateStyle = .short
            f.timeStyle = .short
            return f.string(from: d)
        }()
        let source = storage.sourceName(for: domain)
        return (formatted, source)
    }
}

#Preview {
    BlockLogView()
}
