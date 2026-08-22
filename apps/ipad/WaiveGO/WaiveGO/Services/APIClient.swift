//
//  APIClient.swift
//  WaiveGO
//
//  Talks to services/api. Currently just the one call the check-in flow needs;
//  POST /v1/guests (enrollment) will get a client method here too once there's an
//  enrollment screen to call it from.

import Foundation

struct CheckInResponse: Decodable {
    let verified: Bool
    let reason: String?
    let guestName: String?
}

enum APIClientError: LocalizedError {
    case invalidResponse
    case server(status: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Received an unexpected response from the server."
        case .server(let status, let message):
            return "Server error (\(status)): \(message)"
        }
    }
}

final class APIClient {
    static let shared = APIClient()
    private init() {}

    /// Sends a captured photo to /v1/checkin and returns the match/verification
    /// result. Throws on any network failure or non-2xx response — the caller
    /// decides how to present that (see CheckInViewModel).
    func checkIn(imageData: Data) async throws -> CheckInResponse {
        try await postImage(imageData, to: "v1/checkin", decodeAs: CheckInResponse.self)
    }

    private func postImage<T: Decodable>(_ imageData: Data, to path: String, decodeAs: T.Type) async throws -> T {
        var request = URLRequest(url: AppConfig.apiBaseURL.appendingPathComponent(path))
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = multipartBody(imageData: imageData, boundary: boundary)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "no response body"
            throw APIClientError.server(status: httpResponse.statusCode, message: message)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    private func multipartBody(imageData: Data, boundary: String) -> Data {
        var body = Data()
        body.append("--\(boundary)\r\n".utf8Data)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"capture.jpg\"\r\n".utf8Data)
        body.append("Content-Type: image/jpeg\r\n\r\n".utf8Data)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".utf8Data)
        return body
    }
}

private extension String {
    var utf8Data: Data { Data(self.utf8) }
}
