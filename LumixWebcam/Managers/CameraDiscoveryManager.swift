//
//  CameraDiscoveryManager.swift
//  LumixWebcam
//
//  Created by Louis Kaiser on 11.12.25.
//

// CameraDiscoveryManager.swift

import Foundation
import AVFoundation
import Combine

@MainActor
class CameraDiscoveryManager: ObservableObject {
    @Published var allDevices: [CameraDevice] = []
    @Published var selectedDevice: CameraDevice?
    
    private var discoverySession: AVCaptureDevice.DiscoverySession?
    private var observer: NSKeyValueObservation?
    
    var lumixDevices: [CameraDevice] {
        allDevices.filter { $0.isLumix }
    }
    
    var otherDevices: [CameraDevice] {
        allDevices.filter { !$0.isLumix }
    }
    
    init() {
        setupDiscoverySession()
    }
    
    private func setupDiscoverySession() {
        // Discover all video devices
        discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera,
                .external,
                .continuityCamera
            ],
            mediaType: .video,
            position: .unspecified
        )
    }
    
    func startDiscovery() {
        refreshDevices()
        
        // Observe device changes
        observer = discoverySession?.observe(\.devices, options: [.new]) { [weak self] _, _ in
            Task { @MainActor in
                self?.refreshDevices()
            }
        }
        
        // Also observe for device connection notifications
        NotificationCenter.default.addObserver(
            forName: .AVCaptureDeviceWasConnected,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshDevices()
        }
        
        NotificationCenter.default.addObserver(
            forName: .AVCaptureDeviceWasDisconnected,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshDevices()
        }
    }
    
    func refreshDevices() {
        guard let devices = discoverySession?.devices else { return }
        
        allDevices = devices.map { device in
            CameraDevice(
                uniqueID: device.uniqueID,
                name: device.localizedName,
                manufacturer: device.manufacturer ?? "Unknown",
                modelID: device.modelID,
                isLumix: isLumixCamera(device)
            )
        }
        
        // Auto-select first Lumix if nothing selected
        if selectedDevice == nil {
            selectedDevice = lumixDevices.first
        }
        
        // If selected device disconnected, clear selection
        if let selected = selectedDevice,
           !allDevices.contains(where: { $0.uniqueID == selected.uniqueID }) {
            selectedDevice = nil
        }
    }
    
    private func isLumixCamera(_ device: AVCaptureDevice) -> Bool {
        let name = device.localizedName.lowercased()
        let manufacturer = (device.manufacturer ?? "").lowercased()
        let modelID = device.modelID.lowercased()
        
        // Check for Panasonic/Lumix identifiers
        let lumixKeywords = ["lumix", "panasonic", "dc-s5", "s5ii", "s5iix", "gh6", "gh5"]
        
        return lumixKeywords.contains { keyword in
            name.contains(keyword) ||
            manufacturer.contains(keyword) ||
            modelID.contains(keyword)
        }
    }
}
