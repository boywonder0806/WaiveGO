//
//  AppConfig.swift
//  WaiveGO
//

import Foundation

enum AppConfig {
    /// Where services/api is currently reachable. Not deployed anywhere public yet
    /// (see infra/docker-compose.yml's TODO), so this points at local dev by
    /// default — change it to match wherever you're actually running the server:
    ///
    /// - Simulator, server running on this same Mac (`npm run dev` in services/api):
    ///   "http://localhost:3001" works as-is.
    /// - Physical iPad, server running on your Mac: the Simulator's "localhost"
    ///   trick doesn't work from a real device — use your Mac's LAN IP instead
    ///   (`ipconfig getifaddr en0` in Terminal), e.g. "http://192.168.1.23:3001".
    ///   Both devices need to be on the same Wi-Fi network.
    /// - Once services/api is deployed to the Droplet behind a domain + HTTPS,
    ///   switch this to that URL and the NSAllowsLocalNetworking exception in
    ///   Info.plist can come back out.
    static let apiBaseURL = URL(string: "http://localhost:3001")!
}
