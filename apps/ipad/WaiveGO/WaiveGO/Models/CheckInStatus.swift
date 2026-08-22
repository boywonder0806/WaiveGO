//
//  CheckInStatus.swift
//  WaiveGO
//
//  Represents where a single check-in attempt is in its lifecycle. `verified` /
//  `notVerified` are populated from services/api's real /v1/checkin response (see
//  APIClient.checkIn). `error` is distinct from `notVerified` on purpose — it means
//  the system couldn't complete a check, not that this guest doesn't have a waiver,
//  and staff should be able to tell those apart at a glance.

import Foundation

enum CheckInStatus {
    case idle
    case scanning
    case verified(GuestMatch)
    case notVerified(reason: NotVerifiedReason)
    case error(message: String)
}

struct GuestMatch: Identifiable {
    let id = UUID()
    let guestName: String
    // Not returned by /v1/checkin today (see services/api/src/routes/checkin.ts) —
    // optional rather than fabricated.
    let waiverExpirationDate: Date?
}

enum NotVerifiedReason {
    case noFaceMatch
    case waiverExpired(guestName: String)
    case noWaiverOnFile

    var title: String {
        switch self {
        case .noFaceMatch: return "No Match Found"
        case .waiverExpired: return "Waiver Expired"
        case .noWaiverOnFile: return "No Waiver On File"
        }
    }

    var message: String {
        switch self {
        case .noFaceMatch:
            return "We couldn't match that face to a signed waiver. Please see a staff member."
        case .waiverExpired(let guestName):
            return "\(guestName)'s waiver has expired. A new waiver needs to be signed."
        case .noWaiverOnFile:
            return "No signed waiver was found for this guest. Please sign a waiver to continue."
        }
    }
}
