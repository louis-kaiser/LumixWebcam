//
//  ExtensionProvider.swift
//  LumixWebcam
//
//  Created by Louis Kaiser on 11.12.25.
//

// ExtensionProvider.swift

import Foundation
import CoreMediaIO
import os.log

let logger = Logger(subsystem: LumixConstants.extensionBundleID, category: "Extension")

class ExtensionProviderSource: NSObject, CMIOExtensionProviderSource {
    private(set) var provider: CMIOExtensionProvider!
    private var deviceSource: ExtensionDeviceSource!
    
    init(clientQueue: DispatchQueue?) {
        super.init()
        
        provider = CMIOExtensionProvider(source: self, clientQueue: clientQueue)
        deviceSource = ExtensionDeviceSource(localizedName: LumixConstants.deviceName)
        
        do {
            try provider.addDevice(deviceSource.device)
            logger.info("Successfully added virtual camera device")
        } catch {
            logger.error("Failed to add device: \(error.localizedDescription)")
        }
    }
    
    // MARK: - CMIOExtensionProviderSource
    
    func connect(to client: CMIOExtensionClient) throws {
        logger.info("Client connected: \(client.description)")
    }
    
    func disconnect(from client: CMIOExtensionClient) {
        logger.info("Client disconnected: \(client.description)")
    }
    
    var availableProperties: Set<CMIOExtensionProperty> {
        return [.providerName, .providerManufacturer]
    }
    
    func providerProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionProviderProperties {
        let providerProperties = CMIOExtensionProviderProperties(dictionary: [:])
        
        if properties.contains(.providerName) {
            providerProperties.name = LumixConstants.deviceName
        }
        if properties.contains(.providerManufacturer) {
            providerProperties.manufacturer = LumixConstants.deviceManufacturer
        }
        
        return providerProperties
    }
    
    func setProviderProperties(_ providerProperties: CMIOExtensionProviderProperties) throws {
        // Read-only provider
    }
}
