//
//  ExtensionDeviceSource.swift
//  LumixWebcam
//
//  Created by Louis Kaiser on 11.12.25.
//

// ExtensionDeviceSource.swift

import Foundation
import CoreMediaIO
import os.log

class ExtensionDeviceSource: NSObject, CMIOExtensionDeviceSource {
    private(set) var device: CMIOExtensionDevice!
    private var streamSource: ExtensionStreamSource!
    
    init(localizedName: String) {
        super.init()
        
        let deviceID = LumixConstants.deviceUUID
        
        device = CMIOExtensionDevice(
            localizedName: localizedName,
            deviceID: deviceID,
            legacyDeviceID: nil,
            source: self
        )
        
        streamSource = ExtensionStreamSource(
            localizedName: "Lumix S5 Video",
            streamID: LumixConstants.streamUUID,
            device: device
        )
        
        do {
            try device.addStream(streamSource.stream)
            logger.info("Added video stream to device")
        } catch {
            logger.error("Failed to add stream: \(error.localizedDescription)")
        }
    }
    
    // MARK: - CMIOExtensionDeviceSource
    
    var availableProperties: Set<CMIOExtensionProperty> {
        return [
            .deviceTransportType,
            .deviceModel,
            .deviceIsSuspended,
            .deviceLinkedCoreAudioDeviceUID
        ]
    }
    
    func deviceProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionDeviceProperties {
        let deviceProperties = CMIOExtensionDeviceProperties(dictionary: [:])
        
        if properties.contains(.deviceTransportType) {
            deviceProperties.transportType = kIOAudioDeviceTransportTypeUSB
        }
        if properties.contains(.deviceModel) {
            deviceProperties.model = LumixConstants.deviceModel
        }
        if properties.contains(.deviceIsSuspended) {
            deviceProperties.isSuspended = false
        }
        
        return deviceProperties
    }
    
    func setDeviceProperties(_ deviceProperties: CMIOExtensionDeviceProperties) throws {
        // Handle property changes if needed
    }
}
