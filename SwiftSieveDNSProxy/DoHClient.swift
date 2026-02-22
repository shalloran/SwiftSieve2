//
//  DoHClient.swift
//  SwiftSieveDNSProxy
//

import Foundation

/// forwards DNS over HTTPS to Cloudflare (RFC 8484)
final class DoHClient {
    private let session: URLSession
    private let baseURL = "https://cloudflare-dns.com/dns-query"

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.waitsForConnectivity = false
        self.session = URLSession(configuration: config)
    }

    /// send wire-format request, return wire-format response (or nil on failure)
    func resolve(queryData: Data) async -> Data? {
        let base64 = queryData.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        guard let url = URL(string: "\(baseURL)?dns=\(base64)") else { return nil }
        var request = URLRequest(url: url)
        request.setValue("application/dns-message", forHTTPHeaderField: "Accept")
        request.httpMethod = "GET"
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            return data
        } catch {
            return nil
        }
    }
}
