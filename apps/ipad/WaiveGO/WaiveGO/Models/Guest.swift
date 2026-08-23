//
//  Guest.swift
//  WaiveGO
//

import Foundation

struct Guest: Identifiable, Decodable {
    let id: String
    let fullName: String
    let smartwaiverWaiverId: String
    let waiverExpiration: String?
    let enrolledAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case smartwaiverWaiverId = "smartwaiver_waiver_id"
        case waiverExpiration = "waiver_expiration"
        case enrolledAt = "enrolled_at"
    }

    /// Test-mode guests (see services/api/src/routes/guests.ts) are always
    /// identifiable by this prefix — never confused with a real Smartwaiver waiver.
    var isTestGuest: Bool { smartwaiverWaiverId.hasPrefix("TEST-") }
}
