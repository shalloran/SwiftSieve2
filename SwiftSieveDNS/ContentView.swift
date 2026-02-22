//
//  ContentView.swift
//  SwiftSieveDNS
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            AllowlistView()
                .tabItem {
                    Label("Allowlist", systemImage: "checkmark.circle")
                }
            BlockLogView()
                .tabItem {
                    Label("Block log", systemImage: "doc.text")
                }
        }
    }
}

#Preview {
    ContentView()
}
