//
//  oba_macosApp.swift
//  oba-macos
//
//  Created by Sumit Gouthaman on 2/19/26.
//

import SwiftUI
import AppKit

@main
struct oba_macosApp: App {
    @StateObject private var store = Store()

    var body: some Scene {
        Window("Settings", id: "settings") {
            SettingsView()
                .environmentObject(store)
                .onAppear {
                    // Show in Dock while Settings window is open
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                }
                .onDisappear {
                    // Hide from Dock when Settings window is closed
                    NSApp.setActivationPolicy(.accessory)
                }
        }
        .defaultSize(width: 500, height: 600)

        MenuBarExtra("OneBusAway", systemImage: "bus") {
            PopoverView()
                .environmentObject(store)
        }
        .menuBarExtraStyle(.window)
    }
}
