//
//  FrameDistributor.swift
//  LumixWebcam
//
//  Created by Louis Kaiser on 11.12.25.
//

// FrameDistributor.swift

import Foundation
import CoreMedia
import CoreVideo
import os.log

class FrameDistributor {
    private var testPatternTimer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: "com.lumixwebcam.testpattern", qos: .userInteractive)
    
    private var frameCount: UInt64 = 0
    private var pixelBufferPool: PixelBufferPool?
    
    func startTestPattern(onFrame: @escaping (CMSampleBuffer) -> Void) {
        let resolution = SharedUserDefaults.shared.selectedResolution
        pixelBufferPool = PixelBufferPool(
            width: Int(resolution.width),
            height: Int(resolution.height)
        )
        
        let frameInterval = 1.0 / LumixConstants.defaultFrameRate
        
        testPatternTimer = DispatchSource.makeTimerSource(queue: timerQueue)
        testPatternTimer?.schedule(
            deadline: .now(),
            repeating: frameInterval,
            leeway: .milliseconds(1)
        )
        
        testPatternTimer?.setEventHandler { [weak self] in
            self?.generateTestFrame(onFrame: onFrame)
        }
        
        testPatternTimer?.resume()
        logger.info("Started test pattern generator")
    }
    
    func stopTestPattern() {
        testPatternTimer?.cancel()
        testPatternTimer = nil
        frameCount = 0
        logger.info("Stopped test pattern generator")
    }
    
    private func generateTestFrame(onFrame: @escaping (CMSampleBuffer) -> Void) {
        guard let pixelBuffer = pixelBufferPool?.createPixelBuffer() else {
            return
        }
        
        // Draw test pattern
        drawTestPattern(on: pixelBuffer)
        
        // Create sample buffer
        guard let sampleBuffer = createSampleBuffer(from: pixelBuffer) else {
            return
        }
        
        onFrame(sampleBuffer)
        frameCount += 1
    }
    
    private func drawTestPattern(on pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        // Create color bars pattern
        let barWidth = width / 8
        let colors: [(r: UInt8, g: UInt8, b: UInt8)] = [
            (255, 255, 255), // White
            (255, 255, 0),   // Yellow
            (0, 255, 255),   // Cyan
            (0, 255, 0),     // Green
            (255, 0, 255),   // Magenta
            (255, 0, 0),     // Red
            (0, 0, 255),     // Blue
            (0, 0, 0)        // Black
        ]
        
        // Add animation based on frame count
        let offset = Int(frameCount) % 60
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelOffset = y * bytesPerRow + x * 4
                let barIndex = ((x + offset) / barWidth) % 8
                let color = colors[barIndex]
                
                // BGRA format
                buffer[pixelOffset + 0] = color.b
                buffer[pixelOffset + 1] = color.g
                buffer[pixelOffset + 2] = color.r
                buffer[pixelOffset + 3] = 255
            }
        }
        
        // Draw "NO CAMERA" text indicator in center
        drawTextIndicator(buffer: buffer, width: width, height: height, bytesPerRow: bytesPerRow)
    }
    
    private func drawTextIndicator(buffer: UnsafeMutablePointer<UInt8>, width: Int, height: Int, bytesPerRow: Int) {
        // Draw a simple rectangle in the center
        let rectWidth = 200
        let rectHeight = 40
        let startX = (width - rectWidth) / 2
        let startY = (height - rectHeight) / 2
        
        for y in startY..<(startY + rectHeight) {
            for x in startX..<(startX + rectWidth) {
                let pixelOffset = y * bytesPerRow + x * 4
                
                // Semi-transparent black background
                buffer[pixelOffset + 0] = 0
                buffer[pixelOffset + 1] = 0
                buffer[pixelOffset + 2] = 0
                buffer[pixelOffset + 3] = 200
            }
        }
    }
    
    private func createSampleBuffer(from pixelBuffer: CVPixelBuffer) -> CMSampleBuffer? {
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )
        
        guard let format = formatDescription else { return nil }
        
        let now = CMClockGetTime(CMClockGetHostTimeClock())
        var timingInfo = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: Int32(LumixConstants.defaultFrameRate)),
            presentationTimeStamp: now,
            decodeTimeStamp: .invalid
        )
        
        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: format,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )
        
        return sampleBuffer
    }
}
