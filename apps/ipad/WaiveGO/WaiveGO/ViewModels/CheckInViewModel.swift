//
//  CheckInViewModel.swift
//  WaiveGO
//
//  Drives the check-in screen's state machine: idle -> scanning -> result -> idle.
//
//  Once a face has been held in frame for a beat, this captures a still photo and
//  sends it to services/api's POST /v1/checkin, which does the real work (CompreFace
//  match + Smartwaiver waiver check) — see APIClient.checkIn. Nothing here fabricates
//  a result anymore. services/api isn't deployed anywhere public yet (see
//  infra/docker-compose.yml's TODO), so AppConfig.apiBaseURL needs to point at
//  wherever it's actually reachable for this to succeed — see that file's comment.

import Combine
import Foundation

@MainActor
final class CheckInViewModel: ObservableObject {
    @Published private(set) var status: CheckInStatus = .idle

    /// Shared with ScanningStateView so the live preview on screen and the
    /// match-decision logic below are reading the exact same camera session.
    let camera = CameraService()

    private var resetTask: Task<Void, Never>?
    private var scanTask: Task<Void, Never>?

    /// A face has to be continuously in frame this long before we treat it as a
    /// real capture — filters out someone just passing through the background.
    private let requiredHoldDuration: TimeInterval = 1.0
    /// Give up and return to idle if nobody presents a face for this long, rather
    /// than leaving the camera running (and the kiosk stuck) indefinitely.
    private let noFaceTimeout: TimeInterval = 20

    /// Starts the camera and waits for a face to be held in frame before doing
    /// anything — no more "approves no matter what."
    func startScan() {
        resetTask?.cancel()
        scanTask?.cancel()
        status = .scanning
        camera.start()

        scanTask = Task { [weak self] in
            guard let self else { return }
            let deadline = Date().addingTimeInterval(self.noFaceTimeout)
            var holdStart: Date?

            while !Task.isCancelled {
                if self.camera.isFaceDetected {
                    let start = holdStart ?? Date()
                    holdStart = start
                    if Date().timeIntervalSince(start) >= self.requiredHoldDuration {
                        await self.performCheckIn()
                        return
                    }
                } else {
                    holdStart = nil
                }

                if Date() >= deadline {
                    self.camera.stop()
                    self.status = .idle
                    return
                }

                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    /// Captures the current frame and calls services/api. Runs on the same Task as
    /// the hold-detection loop above, so it's naturally cancelled if the view
    /// disappears mid-request (e.g. resolve() is called elsewhere first).
    private func performCheckIn() async {
        guard let imageData = camera.captureStillJPEG() else {
            resolve(.error(message: "Couldn't capture a photo — try again"))
            return
        }

        do {
            let response = try await APIClient.shared.checkIn(imageData: imageData)
            resolve(Self.status(from: response))
        } catch {
            resolve(.error(message: "Couldn't reach the check-in service. Is services/api running?"))
        }
    }

    /// Maps services/api's /v1/checkin JSON response onto our local state.
    private static func status(from response: CheckInResponse) -> CheckInStatus {
        if response.verified {
            return .verified(GuestMatch(guestName: response.guestName ?? "Guest", waiverExpirationDate: nil))
        }

        switch response.reason {
        case "expired":
            return .notVerified(reason: .waiverExpired(guestName: response.guestName ?? "Guest"))
        case "no_waiver":
            return .notVerified(reason: .noWaiverOnFile)
        default:
            return .notVerified(reason: .noFaceMatch)
        }
    }

    /// Applies a result, plays the matching go/stop cue, and schedules a return to idle
    /// so the kiosk is ready for the next guest without staff intervention.
    func resolve(_ newStatus: CheckInStatus) {
        scanTask?.cancel()
        camera.stop()
        status = newStatus

        switch newStatus {
        case .verified:
            CheckInSoundPlayer.shared.playVerified()
        case .notVerified, .error:
            CheckInSoundPlayer.shared.playNotVerified()
        case .idle, .scanning:
            break
        }

        resetTask?.cancel()
        resetTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            status = .idle
        }
    }

    // MARK: - Debug helpers (for building/testing the UI before real integration exists)

    func simulateNotVerified(_ reason: NotVerifiedReason) {
        resolve(.notVerified(reason: reason))
    }
}
