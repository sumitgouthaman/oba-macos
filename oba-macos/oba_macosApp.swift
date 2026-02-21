//
//  oba_macosApp.swift
//  oba-macos
//
//  Created by Sumit Gouthaman on 2/19/26.
//

import SwiftUI

@main
struct oba_macosApp: App {
    @StateObject private var store = Store()
    
    var body: some Scene {
        Window("Settings", id: "settings") {
            SettingsView()
                .environmentObject(store)
        }
        .defaultSize(width: 500, height: 600)
        
        MenuBarExtra("OneBusAway", systemImage: "bus") {
            PopoverView()
                .environmentObject(store)
        }
        .menuBarExtraStyle(.window)
    }
}
