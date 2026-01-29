import Foundation
import AVFoundation
import SwiftUI
import Combine

/// CameraService: Manages camera capture session for face scanning
@MainActor
final class CameraService: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var isAuthorized = false
    @Published var isSessionRunning = false
    @Published var capturedImage: UIImage?
    @Published var error: CameraError?

    // MARK: - Private Properties

    private let captureSession = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.looksmaxai.camera.session")
    private var photoContinuation: CheckedContinuation<UIImage?, Never>?

    // MARK: - Camera Position

    enum CameraPosition {
        case front
        case back

        var avPosition: AVCaptureDevice.Position {
            switch self {
            case .front: return .front
            case .back: return .back
            }
        }
    }

    private var currentPosition: CameraPosition = .front

    // MARK: - Initialization

    override init() {
        super.init()
    }

    // MARK: - Authorization

    func checkAuthorization() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            isAuthorized = false
            error = .accessDenied
        @unknown default:
            isAuthorized = false
        }
    }

    // MARK: - Session Setup

    func setupSession() async {
        guard isAuthorized else {
            error = .accessDenied
            return
        }

        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }

    private func configureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo

        // Add video input
        do {
            guard let videoDevice = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: currentPosition.avPosition
            ) else {
                Task { @MainActor in
                    self.error = .cameraUnavailable
                }
                captureSession.commitConfiguration()
                return
            }

            let videoInput = try AVCaptureDeviceInput(device: videoDevice)

            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                videoDeviceInput = videoInput
            } else {
                Task { @MainActor in
                    self.error = .cannotAddInput
                }
                captureSession.commitConfiguration()
                return
            }
        } catch {
            Task { @MainActor in
                self.error = .inputCreationFailed(error)
            }
            captureSession.commitConfiguration()
            return
        }

        // Add photo output
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true

            if let connection = photoOutput.connection(with: .video) {
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = currentPosition == .front
                }
            }
        } else {
            Task { @MainActor in
                self.error = .cannotAddOutput
            }
            captureSession.commitConfiguration()
            return
        }

        captureSession.commitConfiguration()
    }

    // MARK: - Session Control

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                Task { @MainActor in
                    self.isSessionRunning = true
                }
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                Task { @MainActor in
                    self.isSessionRunning = false
                }
            }
        }
    }

    // MARK: - Camera Switching

    func switchCamera() {
        currentPosition = currentPosition == .front ? .back : .front

        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.captureSession.beginConfiguration()

            // Remove existing input
            if let currentInput = self.videoDeviceInput {
                self.captureSession.removeInput(currentInput)
            }

            // Add new input
            do {
                guard let videoDevice = AVCaptureDevice.default(
                    .builtInWideAngleCamera,
                    for: .video,
                    position: self.currentPosition.avPosition
                ) else {
                    self.captureSession.commitConfiguration()
                    return
                }

                let videoInput = try AVCaptureDeviceInput(device: videoDevice)

                if self.captureSession.canAddInput(videoInput) {
                    self.captureSession.addInput(videoInput)
                    self.videoDeviceInput = videoInput
                }

                // Update mirroring
                if let connection = self.photoOutput.connection(with: .video) {
                    if connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = self.currentPosition == .front
                    }
                }
            } catch {
                Task { @MainActor in
                    self.error = .inputCreationFailed(error)
                }
            }

            self.captureSession.commitConfiguration()
        }
    }

    // MARK: - Photo Capture

    func capturePhoto() async -> UIImage? {
        return await withCheckedContinuation { continuation in
            self.photoContinuation = continuation

            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }

                let settings = AVCapturePhotoSettings()
                settings.isHighResolutionPhotoEnabled = true

                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    // MARK: - Preview Layer

    var previewLayer: AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        return layer
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        Task { @MainActor in
            if let error = error {
                self.error = .captureFailure(error)
                self.photoContinuation?.resume(returning: nil)
                self.photoContinuation = nil
                return
            }

            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                self.photoContinuation?.resume(returning: nil)
                self.photoContinuation = nil
                return
            }

            self.capturedImage = image
            self.photoContinuation?.resume(returning: image)
            self.photoContinuation = nil
        }
    }
}

// MARK: - Camera Error

enum CameraError: LocalizedError {
    case accessDenied
    case cameraUnavailable
    case cannotAddInput
    case cannotAddOutput
    case inputCreationFailed(Error)
    case captureFailure(Error)

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Camera access denied. Please enable in Settings."
        case .cameraUnavailable:
            return "Camera is not available on this device."
        case .cannotAddInput:
            return "Cannot configure camera input."
        case .cannotAddOutput:
            return "Cannot configure camera output."
        case .inputCreationFailed(let error):
            return "Camera input failed: \(error.localizedDescription)"
        case .captureFailure(let error):
            return "Photo capture failed: \(error.localizedDescription)"
        }
    }
}
