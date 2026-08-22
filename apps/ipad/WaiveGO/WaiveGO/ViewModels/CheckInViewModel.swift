//
//  CheckInViewModel.swift
//  WaiveGO
//
//  Drives the check-in screen's state machine: idle -> scanning -> result -> idle.
//
//  This is currently MOCKED — `simulateScan` fakes a camera capture + match instead of
//  calling a real facial-recognition service. Replace `simulateScan` with a call into
//  a camera/vision service once that exists, and feed its result into `resolve(_:)`.

import Combine
import Foundation

@MainActor
final class CheckInViewModel: ObservableObject {
    @Published private(set) var status: CheckInStatus = .idle

    private var resetTask: Task<Void, Never>?

    /// Kicks off a scan attempt. In the real app this starts the camera and hands
    /// frames to the facial-recognition service; here it just fakes a delay.
    func startScan() {
        resetTask?.cancel()
        status = .scanning

        Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            resolve(.verified(GuestMatch(
                guestName: "Jordan Rivera",
                waiverExpirationDate: Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now
            )))
        }
    }

    /// Applies a result, plays the matching go/stop cue, and schedules a return to idle
    /// so the kiosk is ready for the next guest without staff intervention.
    func resolve(_ newStatus: CheckInStatus) {
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
