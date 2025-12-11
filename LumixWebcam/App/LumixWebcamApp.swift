// LumixWebcamApp.swift

import SwiftUI

@main
struct LumixWebcamApp: App {
    @StateObject private var cameraManager = CameraDiscoveryManager()
    @StateObject private var extensionManager = ExtensionManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cameraManager)
                .environmentObject(extensionManager)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentMinSize)
        
        Settings {
            SettingsView()
                .environmentObject(cameraManager)
                .environmentObject(extensionManager)
        }
    }
}
