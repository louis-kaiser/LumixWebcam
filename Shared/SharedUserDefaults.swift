//
//  SharedUserDefaults.swift
//  LumixWebcam
//
//  Created by Louis Kaiser on 11.12.25.
//

// Shared/SharedUserDefaults.swift

import Foundation

public class SharedUserDefaults {
    public static let shared = SharedUserDefaults()
    
    private let defaults: UserDefaults?
    
    private init() {
        defaults = UserDefaults(suiteName: LumixConstants.appGroupID)
    }
    
    // MARK: - Selected Camera
    public var selectedCameraID: String? {
        get { defaults?.string(forKey: LumixConstants.selectedCameraIDKey) }
        set { defaults?.set(newValue, forKey: LumixConstants.selectedCameraIDKey) }
    }
    
    // MARK: - Selected Resolution
    public var selectedResolution: (width: Int32, height: Int32) {
        get {
            let width = defaults?.integer(forKey: "\(LumixConstants.selectedResolutionKey)_width") ?? Int(LumixConstants.defaultWidth)
            let height = defaults?.integer(forKey: "\(LumixConstants.selectedResolutionKey)_height") ?? Int(LumixConstants.defaultHeight)
            return (Int32(width), Int32(height))
        }
        set {
            defaults?.set(newValue.width, forKey: "\(LumixConstants.selectedResolutionKey)_width")
            defaults?.set(newValue.height, forKey: "\(LumixConstants.selectedResolutionKey)_height")
        }
    }
    
    // MARK: - Extension Active State
    public var isExtensionActive: Bool {
        get { defaults?.bool(forKey: LumixConstants.isExtensionActiveKey) ?? false }
        set { defaults?.set(newValue, forKey: LumixConstants.isExtensionActiveKey) }
    }
}
