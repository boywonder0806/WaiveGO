//
//  CameraService.swift
//  WaiveGO
//
//  Runs the front camera (the kiosk-facing side, so it sees the guest) and publishes
//  whether a face is currently in frame using on-device Vision face detection. This is
//  detection only — "is there a face here" — not recognition/matching. Real matching
//  still needs the facial-recognition service call, which isn't wired up yet.

import AVFoundation
import Combine
import Vision

@MainActor
final class CameraService: NSObject, ObservableObject {
    @Published private(set) var isFaceDetected = false
    @Published private(set) var isAuthorized = false

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "com.waivego.camera.session")
    private let videoOutput = AVCaptureVideoDataOutput()
    private var didConfigureSession = false

    // Only re-run Vision a few times a second, not on every frame — plenty responsive
    // for "is a face in view" and much cheaper than analyzing all ~30fps.
    nonisolated(unsafe) private var lastDetectionTime = Date.distantPast
    private let detectionInterval: TimeInterval = 0.2

    func start() {
        Task {
            isAuthorized = await requestAccess()
            guard isAuthorized else { return }
            sessionQueue.async { [weak self] in
                self?.configureSessionIfNeeded()
                self?.session.startRunning()
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    private func requestAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    /// No-ops safely if there's no camera (e.g. the Simulator) — the UI falls back to a
    /// static placeholder rather than crashing.
    private func configureSessionIfNeeded() {
        guard !didConfigureSession else { return }
        didConfigureSession = true

        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return
        }
        session.addInput(input)

        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let now = Date()
        guard now.timeIntervalSince(lastDetectionTime) >= detectionInterval else { return }
        lastDetectionTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        try? handler.perform([request])
        let found = !(request.results ?? []).isEmpty

        Task { @MainActor [weak self] in
            self?.isFaceDetected = found
        }
    }
}
