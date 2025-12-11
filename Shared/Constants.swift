//
//  Constants.swift
//  LumixWebcam
//
//  Created by Louis Kaiser on 11.12.25.
//

// Shared/Constants.swift

import Foundation
import CoreMedia

public enum LumixConstants {
    // MARK: - Identifiers
    public static let extensionBundleID = "com.yourcompany.LumixWebcam.LumixCameraExtension"
    public static let appGroupID = "group.com.yourcompany.LumixWebcam"
    
    // MARK: - Camera Properties
    public static let deviceName = "Lumix S5 Webcam"
    public static let deviceManufacturer = "Panasonic (Virtual)"
    public static let deviceModel = "Lumix S5"
    
    // MARK: - UUIDs (Generate your own for production!)
    public static let deviceUUID = UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!
    public static let streamUUID = UUID(uuidString: "B2C3D4E5-F6A7-8901-BCDE-F12345678901")!
    
    // MARK: - Video Settings
    public static let defaultWidth: Int32 = 1920
    public static let defaultHeight: Int32 = 1080
    public static let defaultFrameRate: Float64 = 30.0
    public static let pixelFormat = kCVPixelFormatType_32BGRA
    
    // MARK: - Supported Resolutions
    public static let supportedResolutions: [(width: Int32, height: Int32)] = [
        (3840, 2160),  // 4K
        (1920, 1080),  // 1080p
        (1280, 720),   // 720p
    ]
    
    // MARK: - User Defaults Keys
    public static let selectedCameraIDKey = "selectedCameraID"
    public static let selectedResolutionKey = "selectedResolution"
    public static let isExtensionActiveKey = "isExtensionActive"
}
