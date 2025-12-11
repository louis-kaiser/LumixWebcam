//
//  ContentView.swift
//  LumixWebcam
//
//  Created by Louis Kaiser on 11.12.25.
//

// ContentView.swift

import SwiftUI
import AVFoundation

struct ContentView: View {
    @EnvironmentObject var cameraManager: CameraDiscoveryManager
    @EnvironmentObject var extensionManager: ExtensionManager
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            MainContentView()
        }
        .navigationTitle("Lumix S5 Webcam")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                ExtensionStatusBadge()
                
                Button(action: installExtension) {
                    Label("Install Extension", systemImage: "puzzlepiece.extension")
                }
                .disabled(extensionManager.isInstalled)
                
                Button(action: refreshCameras) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
        .alert("Extension Status", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            cameraManager.startDiscovery()
            extensionManager.checkInstallationStatus()
        }
    }
    
    private func installExtension() {
        Task {
            do {
                try await extensionManager.installExtension()
                alertMessage = "Camera extension installed successfully! Restart FaceTime to see the virtual camera."
                showingAlert = true
            } catch {
                alertMessage = "Failed to install extension: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
    
    private func refreshCameras() {
        cameraManager.refreshDevices()
    }
}

// MARK: - Sidebar View

struct SidebarView: View {
    @EnvironmentObject var cameraManager: CameraDiscoveryManager
    
    var body: some View {
        List(selection: $cameraManager.selectedDevice) {
            Section("Detected Cameras") {
                if cameraManager.lumixDevices.isEmpty {
                    Text("No Lumix cameras found")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(cameraManager.lumixDevices) { device in
                        CameraRowView(device: device)
                            .tag(device)
                    }
                }
            }
            
            Section("Other Cameras") {
                ForEach(cameraManager.otherDevices) { device in
                    CameraRowView(device: device)
                        .tag(device)
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 220)
    }
}

struct CameraRowView: View {
    let device: CameraDevice
    
    var body: some View {
        HStack {
            Image(systemName: device.isLumix ? "camera.fill" : "camera")
                .foregroundStyle(device.isLumix ? .orange : .secondary)
            
            VStack(alignment: .leading) {
                Text(device.name)
                    .fontWeight(device.isLumix ? .semibold : .regular)
                Text(device.manufacturer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Main Content View

struct MainContentView: View {
    @EnvironmentObject var cameraManager: CameraDiscoveryManager
    @EnvironmentObject var extensionManager: ExtensionManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Preview Area
            ZStack {
                if let device = cameraManager.selectedDevice {
                    CameraPreviewView(device: device)
                } else {
                    PlaceholderView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            
            // Control Bar
            ControlBar()
        }
    }
}

struct PlaceholderView: View {
    @EnvironmentObject var cameraManager: CameraDiscoveryManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.metering.unknown")
                .font(.system(size: 80))
                .foregroundStyle(.gray)
            
            Text("No Camera Selected")
                .font(.title2)
                .foregroundStyle(.white)
            
            if cameraManager.lumixDevices.isEmpty {
                VStack(spacing: 8) {
                    Text("Connect your Panasonic Lumix S5 via USB-C")
                        .foregroundStyle(.gray)
                    
                    Text("Make sure the camera is set to PC (Tether) mode")
                        .font(.caption)
                        .foregroundStyle(.gray.opacity(0.7))
                }
            } else {
                Text("Select a camera from the sidebar")
                    .foregroundStyle(.gray)
            }
        }
    }
}

// MARK: - Control Bar

struct ControlBar: View {
    @EnvironmentObject var cameraManager: CameraDiscoveryManager
    @EnvironmentObject var extensionManager: ExtensionManager
    
    @State private var selectedResolution: String = "1920x1080"
    
    let resolutions = ["3840x2160", "1920x1080", "1280x720"]
    
    var body: some View {
        HStack {
            // Selected Camera Info
            if let device = cameraManager.selectedDevice {
                Label(device.name, systemImage: "camera.fill")
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            // Resolution Picker
            Picker("Resolution", selection: $selectedResolution) {
                ForEach(resolutions, id: \.self) { res in
                    Text(res).tag(res)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 140)
            .onChange(of: selectedResolution) { _, newValue in
                updateResolution(newValue)
            }
            
            Divider()
                .frame(height: 20)
            
            // Activate Button
            Button(action: activateAsWebcam) {
                HStack {
                    Image(systemName: extensionManager.isStreaming ? "stop.fill" : "play.fill")
                    Text(extensionManager.isStreaming ? "Stop Streaming" : "Activate Webcam")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(extensionManager.isStreaming ? .red : .green)
            .disabled(cameraManager.selectedDevice == nil || !extensionManager.isInstalled)
        }
        .padding()
        .background(.bar)
    }
    
    private func updateResolution(_ resolution: String) {
        let components = resolution.split(separator: "x")
        guard components.count == 2,
              let width = Int32(components[0]),
              let height = Int32(components[1]) else { return }
        
        SharedUserDefaults.shared.selectedResolution = (width, height)
    }
    
    private func activateAsWebcam() {
        guard let device = cameraManager.selectedDevice else { return }
        
        if extensionManager.isStreaming {
            extensionManager.stopStreaming()
        } else {
            SharedUserDefaults.shared.selectedCameraID = device.uniqueID
            extensionManager.startStreaming()
        }
    }
}

// MARK: - Extension Status Badge

struct ExtensionStatusBadge: View {
    @EnvironmentObject var extensionManager: ExtensionManager
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(extensionManager.isInstalled ? .green : .red)
                .frame(width: 8, height: 8)
            
            Text(extensionManager.isInstalled ? "Extension Active" : "Extension Not Installed")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

#Preview {
    ContentView()
        .environmentObject(CameraDiscoveryManager())
        .environmentObject(ExtensionManager())
}
