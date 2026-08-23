//
//  AppConfig.swift
//  WaiveGO
//

import Foundation

enum AppConfig {
    /// Where services/api is currently reachable. It's deployed and running on the
    /// Droplet now (see infra/docker-compose.yml), but its port is loopback-only —
    /// not reachable from the public internet yet (no auth, no TLS — see
    /// infra/README.md's "Next steps"). So this still needs to point somewhere you
    /// can actually reach:
    ///
    /// - Simulator or physical iPad + a tunnel to the Droplet
    ///   (`ssh -L 3001:localhost:3001 root@<droplet-ip>`, run on whichever machine
    ///   the device connects through) — this is the one that hits the real,
    ///   deployed server and real data. "http://localhost:3001" from the
    ///   Simulator; from a physical iPad, that Mac's LAN IP instead (same
    ///   same-Wi-Fi requirement as local dev below).
    /// - Simulator, server running locally instead (`npm run dev` in
    ///   services/api): "http://localhost:3001" also works as-is here — just a
    ///   different, non-Droplet database.
    /// - Physical iPad, local dev server on your Mac: use your Mac's LAN IP
    ///   (`ipconfig getifaddr en0` in Terminal), e.g. "http://192.168.1.23:3001".
    /// - Once waivego-api is public behind a real domain + HTTPS, switch this to
    ///   that URL and the NSAllowsLocalNetworking exception in Info.plist can come
    ///   back out.
    static let apiBaseURL = URL(string: "http://localhost:3001")!
}
