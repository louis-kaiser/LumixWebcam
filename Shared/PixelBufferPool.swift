//
//  PixelBufferPool.swift
//  LumixWebcam
//
//  Created by Louis Kaiser on 11.12.25.
//

// Shared/PixelBufferPool.swift

import CoreVideo
import Foundation

public class PixelBufferPool {
    private var pool: CVPixelBufferPool?
    private let width: Int
    private let height: Int
    private let pixelFormat: OSType
    
    public init(width: Int, height: Int, pixelFormat: OSType = kCVPixelFormatType_32BGRA) {
        self.width = width
        self.height = height
        self.pixelFormat = pixelFormat
        createPool()
    }
    
    private func createPool() {
        let poolAttributes: [String: Any] = [
            kCVPixelBufferPoolMinimumBufferCountKey as String: 3
        ]
        
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: pixelFormat,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:],
            kCVPixelBufferMetalCompatibilityKey as String: true
        ]
        
        CVPixelBufferPoolCreate(
            kCFAllocatorDefault,
            poolAttributes as CFDictionary,
            pixelBufferAttributes as CFDictionary,
            &pool
        )
    }
    
    public func createPixelBuffer() -> CVPixelBuffer? {
        guard let pool = pool else { return nil }
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
        
        guard status == kCVReturnSuccess else {
            print("Failed to create pixel buffer: \(status)")
            return nil
        }
        
        return pixelBuffer
    }
    
    public func copyPixelBuffer(from source: CVPixelBuffer) -> CVPixelBuffer? {
        guard let destination = createPixelBuffer() else { return nil }
        
        CVPixelBufferLockBaseAddress(source, .readOnly)
        CVPixelBufferLockBaseAddress(destination, [])
        
        defer {
            CVPixelBufferUnlockBaseAddress(source, .readOnly)
            CVPixelBufferUnlockBaseAddress(destination, [])
        }
        
        let srcBaseAddress = CVPixelBufferGetBaseAddress(source)
        let dstBaseAddress = CVPixelBufferGetBaseAddress(destination)
        
        let srcBytesPerRow = CVPixelBufferGetBytesPerRow(source)
        let dstBytesPerRow = CVPixelBufferGetBytesPerRow(destination)
        let height = CVPixelBufferGetHeight(source)
        
        if srcBytesPerRow == dstBytesPerRow {
            memcpy(dstBaseAddress, srcBaseAddress, srcBytesPerRow * height)
        } else {
            for row in 0..<height {
                let srcRow = srcBaseAddress?.advanced(by: row * srcBytesPerRow)
                let dstRow = dstBaseAddress?.advanced(by: row * dstBytesPerRow)
                memcpy(dstRow, srcRow, min(srcBytesPerRow, dstBytesPerRow))
            }
        }
        
        return destination
    }
}
