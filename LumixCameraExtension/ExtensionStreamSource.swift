//
//  ExtensionStreamSource.swift
//  LumixWebcam
//
//  Created by Louis Kaiser on 11.12.25.
//

// ExtensionStreamSource.swift

import Foundation
import CoreMediaIO
import AVFoundation
import os.log
import Shared

class ExtensionStreamSource: NSObject, CMIOExtensionStreamSource {
    private(set) var stream: CMIOExtensionStream!
    private weak var device: CMIOExtensionDevice?
    
    private let captureSession: LumixCaptureSession
    private let frameDistributor: FrameDistributor
    
    private var streamingClients: Set<CMIOExtensionClient> = []
    private var streamFormat: CMIOExtensionStreamFormat!
    
    private let streamQueue = DispatchQueue(label: "com.lumixwebcam.stream", qos: .userInteractive)
    
    // Timing
    private var sequenceNumber: UInt64 = 0
    private var startTime: CMTime?
    
    init(localizedName: String, streamID: UUID, device: CMIOExtensionDevice) {
        self.device = device
        self.captureSession = LumixCaptureSession()
        self.frameDistributor = FrameDistributor()
        
        super.init()
        
        // Create stream format
        let resolution = SharedUserDefaults.shared.selectedResolution
        let formatDescription = createFormatDescription(
            width: resolution.width,
            height: resolution.height
        )
        
        streamFormat = CMIOExtensionStreamFormat(
            formatDescription: formatDescription,
            maxFrameDuration: CMTime(value: 1, timescale: Int32(LumixConstants.defaultFrameRate)),
            minFrameDuration: CMTime(value: 1, timescale: 60),
            validFrameDurations: nil
        )
        
        stream = CMIOExtensionStream(
            localizedName: localizedName,
            streamID: streamID,
            direction: .source,
            clockType: .hostTime,
            source: self
        )
        
        // Setup capture session callback
        captureSession.onFrameCaptured = { [weak self] sampleBuffer in
            self?.handleCapturedFrame(sampleBuffer)
        }
        
        setupNotifications()
    }
    
    private func setupNotifications() {
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.lumixwebcam.startStreaming"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.startCapturing()
        }
        
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.lumixwebcam.stopStreaming"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.stopCapturing()
        }
    }
    
    // MARK: - CMIOExtensionStreamSource
    
    var formats: [CMIOExtensionStreamFormat] {
        return [streamFormat]
    }
    
    var activeFormatIndex: Int = 0 {
        didSet {
            // Handle format change
        }
    }
    
    var availableProperties: Set<CMIOExtensionProperty> {
        return [
            .streamActiveFormatIndex,
            .streamFrameDuration,
            .streamSinkBufferQueueSize,
            .streamSinkBuffersRequiredForStartup
        ]
    }
    
    func streamProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionStreamProperties {
        let streamProperties = CMIOExtensionStreamProperties(dictionary: [:])
        
        if properties.contains(.streamActiveFormatIndex) {
            streamProperties.activeFormatIndex = 0
        }
        if properties.contains(.streamFrameDuration) {
            streamProperties.frameDuration = CMTime(value: 1, timescale: Int32(LumixConstants.defaultFrameRate))
        }
        
        return streamProperties
    }
    
    func setStreamProperties(_ streamProperties: CMIOExtensionStreamProperties) throws {
        if let formatIndex = streamProperties.activeFormatIndex {
            activeFormatIndex = formatIndex
        }
    }
    
    func authorizedToStartStream(for client: CMIOExtensionClient) -> Bool {
        logger.info("Authorization requested by client: \(client.description)")
        return true
    }
    
    func startStream() throws {
        logger.info("Starting stream")
        startCapturing()
    }
    
    func stopStream() throws {
        logger.info("Stopping stream")
        stopCapturing()
    }
    
    // MARK: - Frame Handling
    
    private func startCapturing() {
        guard let cameraID = SharedUserDefaults.shared.selectedCameraID else {
            logger.warning("No camera selected, using test pattern")
            frameDistributor.startTestPattern { [weak self] sampleBuffer in
                self?.handleCapturedFrame(sampleBuffer)
            }
            return
        }
        
        captureSession.startCapture(deviceID: cameraID)
    }
    
    private func stopCapturing() {
        captureSession.stopCapture()
        frameDistributor.stopTestPattern()
    }
    
    private func handleCapturedFrame(_ sampleBuffer: CMSampleBuffer) {
        streamQueue.async { [weak self] in
            self?.sendFrame(sampleBuffer)
        }
    }
    
    private func sendFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let stream = stream else { return }
        
        // Get timing
        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        if startTime == nil {
            startTime = presentationTime
        }
        
        // Create timing info
        var timingInfo = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: Int32(LumixConstants.defaultFrameRate)),
            presentationTimeStamp: presentationTime,
            decodeTimeStamp: .invalid
        )
        
        // Send to stream
        do {
            try stream.send(
                sampleBuffer,
                discontinuity: [],
                hostTimeInNanoseconds: UInt64(presentationTime.seconds * Double(NSEC_PER_SEC))
            )
            sequenceNumber += 1
        } catch {
            logger.error("Failed to send frame: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helpers
    
    private func createFormatDescription(width: Int32, height: Int32) -> CMFormatDescription {
        var formatDescription: CMFormatDescription?
        
        let extensions: [String: Any] = [
            kCMFormatDescriptionExtension_FormatName as String: "Lumix S5 Video",
            kCMFormatDescriptionExtension_Vendor as String: "Panasonic"
        ]
        
        CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: LumixConstants.pixelFormat,
            width: width,
            height: height,
            extensions: extensions as CFDictionary,
            formatDescriptionOut: &formatDescription
        )
        
        return formatDescription!
    }
}
