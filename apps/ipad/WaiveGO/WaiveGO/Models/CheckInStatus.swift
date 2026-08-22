//
//  CheckInStatus.swift
//  WaiveGO
//
//  Represents where a single check-in attempt is in its lifecycle.
//  TODO: once the facial-recognition service and API exist, `verified`/`notVerified`
//  will be populated from a real match result instead of the mock data in
//  CheckInViewModel.

import Foundation

enum CheckInStatus {
    case idle
    case scanning
    case verified(GuestMatch)
    case notVerified(reason: NotVerifiedReason)
}

struct GuestMatch: Identifiable {
    let id = UUID()
    let guestName: String
    let waiverExpirationDate: Date
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
