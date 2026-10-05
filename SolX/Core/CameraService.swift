import Foundation
import AVFoundation
import Combine
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Grid overlay types for photography composition
public enum CompositionGrid: String, CaseIterable, Identifiable, Sendable {
    case ruleOfThirds = "Rule of Thirds"
    case goldenRatio = "Golden Ratio"
    case centerCross = "Center Target"
    case off = "Off"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .ruleOfThirds: return "grid"
        case .goldenRatio: return "circle.hexagongrid.circle"
        case .centerCross: return "plus.viewfinder"
        case .off: return "grid.slash"
        }
    }
}

/// CameraService orchestrates AVFoundation live viewfinder capture and photo snapping.
public final class CameraService: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    public static let shared = CameraService()
    
    @Published public var isCameraAvailable: Bool = false
    @Published public var isTorchOn: Bool = false
    @Published public var isTorchAvailable: Bool = false
    @Published public var gridMode: CompositionGrid = .ruleOfThirds
    @Published public var isCapturing: Bool = false
    @Published public var showCaptureFlash: Bool = false
    
    public let captureSession = AVCaptureSession()
    private var photoOutput: AVCapturePhotoOutput?
    private var videoDevice: AVCaptureDevice?
    
    override private init() {
        super.init()
        checkCameraPermissions()
    }
    
    public func checkCameraPermissions() {
        #if targetEnvironment(simulator)
        DispatchQueue.main.async {
            self.isCameraAvailable = false
        }
        #elseif canImport(UIKit)
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.setupCaptureSession()
                } else {
                    DispatchQueue.main.async {
                        self?.isCameraAvailable = false
                    }
                }
            }
        default:
            DispatchQueue.main.async {
                self.isCameraAvailable = false
            }
        }
        #endif
    }
    
    private func setupCaptureSession() {
        #if !targetEnvironment(simulator) && canImport(UIKit)
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input) else {
            captureSession.commitConfiguration()
            DispatchQueue.main.async {
                self.isCameraAvailable = false
            }
            return
        }
        
        captureSession.addInput(input)
        self.videoDevice = device
        
        let output = AVCapturePhotoOutput()
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            self.photoOutput = output
        }
        
        captureSession.commitConfiguration()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
            DispatchQueue.main.async {
                self?.isCameraAvailable = true
                self?.isTorchAvailable = device.hasTorch
            }
        }
        #endif
    }
    
    public func toggleTorch() {
        guard let device = videoDevice, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            if device.torchMode == .on {
                device.torchMode = .off
                isTorchOn = false
            } else {
                try device.setTorchModeOn(level: 1.0)
                isTorchOn = true
            }
            device.unlockForConfiguration()
        } catch {
            print("Torch error: \(error)")
        }
    }
    
    public func cycleGrid() {
        let all = CompositionGrid.allCases
        if let idx = all.firstIndex(of: gridMode) {
            let nextIdx = (idx + 1) % all.count
            gridMode = all[nextIdx]
            HapticService.trigger(.light)
        }
    }
    
    public func takePhoto() {
        HapticService.trigger(.heavy)
        
        withAnimation(.easeInOut(duration: 0.12)) {
            self.showCaptureFlash = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            withAnimation(.easeOut(duration: 0.2)) {
                self.showCaptureFlash = false
            }
        }
        
        #if !targetEnvironment(simulator) && canImport(UIKit)
        guard isCameraAvailable, let photoOutput = self.photoOutput else {
            return
        }
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
        #endif
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        #if canImport(UIKit)
        guard error == nil, let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            return
        }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        #endif
    }
}
