//
//  ExtensionManager.swift
//  LumixWebcam
//
//  Created by Louis Kaiser on 11.12.25.
//

// ExtensionManager.swift

import Foundation
import SystemExtensions

@MainActor
class ExtensionManager: NSObject, ObservableObject {
    @Published var isInstalled = false
    @Published var isStreaming = false
    @Published var installationError: String?
    
    private var activationRequest: OSSystemExtensionRequest?
    
    override init() {
        super.init()
        checkInstallationStatus()
    }
    
    func checkInstallationStatus() {
        // Check if extension is loaded by attempting to find its bundle
        let extensionBundleID = LumixConstants.extensionBundleID
        
        // The extension is considered installed if it's in the system extensions folder
        // or if the CMIOExtension has registered successfully
        let request = OSSystemExtensionRequest.propertiesRequest(
            forExtensionWithIdentifier: extensionBundleID,
            queue: .main
        )
        request.delegate = self
        OSSystemExtensionManager.shared.submitRequest(request)
    }
    
    func installExtension() async throws {
        let extensionBundleID = LumixConstants.extensionBundleID
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = OSSystemExtensionRequest.activationRequest(
                forExtensionWithIdentifier: extensionBundleID,
                queue: .main
            )
            
            self.activationRequest = request
            request.delegate = self
            
            // Store continuation for delegate callbacks
            self.activationContinuation = continuation
            
            OSSystemExtensionManager.shared.submitRequest(request)
        }
    }
    
    func uninstallExtension() async throws {
        let extensionBundleID = LumixConstants.extensionBundleID
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = OSSystemExtensionRequest.deactivationRequest(
                forExtensionWithIdentifier: extensionBundleID,
                queue: .main
            )
            
            request.delegate = self
            self.deactivationContinuation = continuation
            
            OSSystemExtensionManager.shared.submitRequest(request)
        }
    }
    
    func startStreaming() {
        SharedUserDefaults.shared.isExtensionActive = true
        isStreaming = true
        
        // Send notification to extension
        DistributedNotificationCenter.default().postNotificationName(
            NSNotification.Name("com.lumixwebcam.startStreaming"),
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }
    
    func stopStreaming() {
        SharedUserDefaults.shared.isExtensionActive = false
        isStreaming = false
        
        // Send notification to extension
        DistributedNotificationCenter.default().postNotificationName(
            NSNotification.Name("com.lumixwebcam.stopStreaming"),
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }
    
    // MARK: - Continuation Storage
    private var activationContinuation: CheckedContinuation<Void, Error>?
    private var deactivationContinuation: CheckedContinuation<Void, Error>?
}

// MARK: - OSSystemExtensionRequestDelegate

extension ExtensionManager: OSSystemExtensionRequestDelegate {
    nonisolated func request(
        _ request: OSSystemExtensionRequest,
        actionForReplacingExtension existing: OSSystemExtensionProperties,
        withExtension ext: OSSystemExtensionProperties
    ) -> OSSystemExtensionRequest.ReplacementAction {
        return .replace
    }
    
    nonisolated func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        Task { @MainActor in
            self.installationError = "Please approve the system extension in System Preferences > Privacy & Security"
        }
    }
    
    nonisolated func request(
        _ request: OSSystemExtensionRequest,
        didFinishWithResult result: OSSystemExtensionRequest.Result
    ) {
        Task { @MainActor in
            switch result {
            case .completed:
                self.isInstalled = true
                self.installationError = nil
                self.activationContinuation?.resume(returning: ())
                self.deactivationContinuation?.resume(returning: ())
                
            case .willCompleteAfterReboot:
                self.installationError = "Extension will be activated after reboot"
                self.activationContinuation?.resume(returning: ())
                
            @unknown default:
                break
            }
            
            self.activationContinuation = nil
            self.deactivationContinuation = nil
        }
    }
    
    nonisolated func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        Task { @MainActor in
            self.isInstalled = false
            self.installationError = error.localizedDescription
            
            let nsError = error as NSError
            
            // Check if already installed (error code 4 = already installed)
            if nsError.code == 4 {
                self.isInstalled = true
                self.activationContinuation?.resume(returning: ())
            } else {
                self.activationContinuation?.resume(throwing: error)
            }
            
            self.deactivationContinuation?.resume(throwing: error)
            
            self.activationContinuation = nil
            self.deactivationContinuation = nil
        }
    }
}
