//
//  LumixCaptureSession.swift
//  LumixWebcam
//
//  Created by Louis Kaiser on 11.12.25.
//

// LumixCaptureSession.swift

import Foundation
import AVFoundation
import CoreMedia
import os.log
import Shared

class LumixCaptureSession: NSObject {
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    
    private let sessionQueue = DispatchQueue(label: "com.lumixwebcam.capture", qos: .userInteractive)
    private let outputQueue = DispatchQueue(label: "com.lumixwebcam.output", qos: .userInteractive)
    
    var onFrameCaptured: ((CMSampleBuffer) -> Void)?
    
    private var isCapturing = false
    
    func startCapture(deviceID: String) {
        sessionQueue.async { [weak self] in
            self?.setupAndStartSession(deviceID: deviceID)
        }
    }
    
    func stopCapture() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
            self?.isCapturing = false
            logger.info("Capture session stopped")
        }
    }
    
    private func setupAndStartSession(deviceID: String) {
        guard !isCapturing else { return }
        
        // Find the camera device
        guard let device = AVCaptureDevice(uniqueID: deviceID) else {
            logger.error("Could not find camera with ID: \(deviceID)")
            return
        }
        
        // Create session
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        session.beginConfiguration()
        
        // Add input
        do {
            let input = try AVCaptureDeviceInput(device: device)
            
            if session.canAddInput(input) {
                session.addInput(input)
                logger.info("Added camera input: \(device.localizedName)")
            } else {
                logger.error("Cannot add camera input")
                return
            }
        } catch {
            logger.error("Failed to create camera input: \(error.localizedDescription)")
            return
        }
        
        // Add output
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: LumixConstants.pixelFormat
        ]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: outputQueue)
        
        if session.canAddOutput(output) {
            session.addOutput(output)
            logger.info("Added video output")
        } else {
            logger.error("Cannot add video output")
            return
        }
        
        // Configure connection
        if let connection = output.connection(with: .video) {
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = false
            }
        }
        
        session.commitConfiguration()
        
        // Store references
        self.captureSession = session
        self.videoOutput = output
        
        // Start running
        session.startRunning()
        isCapturing = true
        
        logger.info("Capture session started successfully")
    }
    
    // Configure camera for best quality
    private func configureCamera(_ device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            
            // Set highest available frame rate
            if let format = device.formats.last(where: { format in
                let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                return dimensions.width >= 1920 && dimensions.height >= 1080
            }) {
                device.activeFormat = format
                
                // Set frame rate
                let desiredFrameRate = CMTime(value: 1, timescale: Int32(LumixConstants.defaultFrameRate))
                device.activeVideoMinFrameDuration = desiredFrameRate
                device.activeVideoMaxFrameDuration = desiredFrameRate
            }
            
            device.unlockForConfiguration()
        } catch {
            logger.error("Failed to configure camera: \(error.localizedDescription)")
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension LumixCaptureSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        onFrameCaptured?(sampleBuffer)
    }
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didDrop sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        logger.warning("Dropped frame")
    }
}
