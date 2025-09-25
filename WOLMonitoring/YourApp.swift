// YourApp.swift
import SwiftUI

@main
struct WOLMonitoringApp: App {
    @StateObject private var sharedData = SharedData()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sharedData)          // <‑‑ inject here
        }
    }
}
