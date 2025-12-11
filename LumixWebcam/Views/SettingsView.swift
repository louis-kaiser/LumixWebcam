//
//  SettingsView.swift
//  LumixWebcam
//
//  Created by Louis Kaiser on 11.12.25.
//

// SettingsView.swift

import SwiftUI
import Shared

struct SettingsView: View {
    @EnvironmentObject var extensionManager: ExtensionManager
    
    @AppStorage("autoStartCamera") private var autoStartCamera = false
    @AppStorage("showInMenuBar") private var showInMenuBar = true
    @AppStorage("preferredFrameRate") private var preferredFrameRate = 30
    
    var body: some View {
        TabView {
            GeneralSettingsView(
                autoStartCamera: $autoStartCamera,
                showInMenuBar: $showInMenuBar
            )
            .tabItem {
                Label("General", systemImage: "gear")
            }
            
            VideoSettingsView(preferredFrameRate: $preferredFrameRate)
                .tabItem {
                    Label("Video", systemImage: "video")
                }
            
            ExtensionSettingsView()
                .environmentObject(extensionManager)
                .tabItem {
                    Label("Extension", systemImage: "puzzlepiece.extension")
                }
        }
        .padding(20)
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsView: View {
    @Binding var autoStartCamera: Bool
    @Binding var showInMenuBar: Bool
    
    var body: some View {
        Form {
            Toggle("Automatically start camera on launch", isOn: $autoStartCamera)
            Toggle("Show in menu bar", isOn: $showInMenuBar)
        }
        .formStyle(.grouped)
    }
}

struct VideoSettingsView: View {
    @Binding var preferredFrameRate: Int
    
    var body: some View {
        Form {
            Picker("Preferred Frame Rate", selection: $preferredFrameRate) {
                Text("24 fps").tag(24)
                Text("30 fps").tag(30)
                Text("60 fps").tag(60)
            }
            
            Section {
                LabeledContent("Current Resolution") {
                    let res = SharedUserDefaults.shared.selectedResolution
                    Text("\(res.width) × \(res.height)")
                }
            }
        }
        .formStyle(.grouped)
    }
}

struct ExtensionSettingsView: View {
    @EnvironmentObject var extensionManager: ExtensionManager
    @State private var showingUninstallConfirm = false
    
    var body: some View {
        Form {
            Section {
                LabeledContent("Status") {
                    HStack {
                        Circle()
                            .fill(extensionManager.isInstalled ? .green : .red)
                            .frame(width: 8, height: 8)
                        Text(extensionManager.isInstalled ? "Installed" : "Not Installed")
                    }
                }
                
                LabeledContent("Version") {
                    Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                }
            }
            
            Section {
                Button("Reinstall Extension") {
                    Task {
                        try? await extensionManager.installExtension()
                    }
                }
                
                Button("Uninstall Extension", role: .destructive) {
                    showingUninstallConfirm = true
                }
            }
        }
        .formStyle(.grouped)
        .alert("Uninstall Extension?", isPresented: $showingUninstallConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Uninstall", role: .destructive) {
                Task {
                    try? await extensionManager.uninstallExtension()
                }
            }
        } message: {
            Text("The virtual camera will no longer be available to FaceTime and other apps.")
        }
    }
}
