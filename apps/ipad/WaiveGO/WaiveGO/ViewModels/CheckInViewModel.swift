//
//  CheckInViewModel.swift
//  WaiveGO
//
//  Drives the check-in screen's state machine: idle -> scanning -> result -> idle.
//
//  The MATCH itself is still MOCKED — once a real face has been held in frame, we
//  fabricate a "verified" result instead of calling a facial-recognition service.
//  Replace the TODO below with a real service call once one exists. What's real
//  already: the camera and face detection (via `camera`, shared with
//  ScanningStateView) — a scan can no longer resolve to "verified" without an
//  actual face having been seen.

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

    /// Starts the camera and waits for a face to be held in frame before resolving
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
                        // TODO: replace with a real facial-recognition service call
                        // (services/facial-recognition via services/api) once one
                        // exists. This is still a fabricated match — the only thing
                        // that's real is that a face was actually held in frame.
                        self.resolve(.verified(GuestMatch(
                            guestName: "Jordan Rivera",
                            waiverExpirationDate: Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now
                        )))
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

    /// Applies a result, plays the matching go/stop cue, and schedules a return to idle
    /// so the kiosk is ready for the next guest without staff intervention.
    func resolve(_ newStatus: CheckInStatus) {
        scanTask?.cancel()
        camera.stop()
        status = newStatus

        switch newStatus {
        case .verified:
            CheckInSoundPlayer.shared.playVerified()
        case .notVerified:
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
