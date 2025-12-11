//
//  CameraPreviewView.swift
//  LumixWebcam
//
//  Created by Louis Kaiser on 11.12.25.
//

// CameraPreviewView.swift

import SwiftUI
import AVFoundation

struct CameraPreviewView: NSViewRepresentable {
    let device: CameraDevice
    
    func makeNSView(context: Context) -> CapturePreviewView {
        let view = CapturePreviewView()
        view.setupSession(with: device)
        return view
    }
    
    func updateNSView(_ nsView: CapturePreviewView, context: Context) {
        if nsView.currentDeviceID != device.uniqueID {
            nsView.setupSession(with: device)
        }
    }
}

class CapturePreviewView: NSView {
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private(set) var currentDeviceID: String?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupSession(with device: CameraDevice) {
        // Stop existing session
        captureSession?.stopRunning()
        previewLayer?.removeFromSuperlayer()
        
        currentDeviceID = device.uniqueID
        
        // Find the AVCaptureDevice
        guard let avDevice = AVCaptureDevice(uniqueID: device.uniqueID) else {
            showErrorState("Camera not accessible")
            return
        }
        
        // Create session
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        do {
            let input = try AVCaptureDeviceInput(device: avDevice)
            
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            // Setup preview layer
            let preview = AVCaptureVideoPreviewLayer(session: session)
            preview.videoGravity = .resizeAspect
            preview.frame = bounds
            preview.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
            
            layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
            layer?.addSublayer(preview)
            
            self.captureSession = session
            self.previewLayer = preview
            
            // Start session on background thread
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
            
        } catch {
            showErrorState("Failed to setup camera: \(error.localizedDescription)")
        }
    }
    
    private func showErrorState(_ message: String) {
        DispatchQueue.main.async {
            let textLayer = CATextLayer()
            textLayer.string = message
            textLayer.fontSize = 16
            textLayer.foregroundColor = NSColor.white.cgColor
            textLayer.alignmentMode = .center
            textLayer.frame = self.bounds
            textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
            
            self.layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
            self.layer?.addSublayer(textLayer)
        }
    }
    
    override func layout() {
        super.layout()
        previewLayer?.frame = bounds
    }
    
    deinit {
        captureSession?.stopRunning()
    }
}
