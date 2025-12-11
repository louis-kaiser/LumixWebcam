//
//  CameraDevice.swift
//  LumixWebcam
//
//  Created by Louis Kaiser on 11.12.25.
//

// CameraDevice.swift

import Foundation

struct CameraDevice: Identifiable, Hashable {
    let uniqueID: String
    let name: String
    let manufacturer: String
    let modelID: String
    let isLumix: Bool
    
    var id: String { uniqueID }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueID)
    }
    
    static func == (lhs: CameraDevice, rhs: CameraDevice) -> Bool {
        lhs.uniqueID == rhs.uniqueID
    }
}
