//
//  DNSMessage.swift
//  SwiftSieveDNSProxy
//

import Foundation

/// minimal DNS wire-format: parse query name, build NXDOMAIN response
struct DNSMessage {
    let id: UInt16
    let queryName: String
    let queryType: UInt16
    let queryClass: UInt16
    let rawQuestion: Data

    /// parse query name and question section from request bytes (caller validates header is query)
    static func parseQuery(_ data: Data) -> DNSMessage? {
        guard data.count >= 12 else { return nil }
        let id = data.withUnsafeBytes { $0.load(fromByteOffset: 0, as: UInt16.self).bigEndian }
        let flags = data.withUnsafeBytes { $0.load(fromByteOffset: 2, as: UInt16.self).bigEndian }
        let qdcount = data.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt16.self).bigEndian }
        guard (flags & 0x8000) == 0, qdcount >= 1 else { return nil }
        var offset = 12
        var labels: [String] = []
        while offset < data.count {
            let len = Int(data[offset])
            offset += 1
            if len == 0 { break }
            if len > 63 || offset + len > data.count { return nil }
            if let s = String(bytes: data.subdata(in: offset..<(offset + len)), encoding: .utf8) {
                labels.append(s)
            }
            offset += len
        }
        guard offset + 4 <= data.count else { return nil }
        let qname = labels.joined(separator: ".")
        let qtype = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt16.self).bigEndian }
        let qclass = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 2, as: UInt16.self).bigEndian }
        let questionEnd = offset + 4
        let rawQuestion = data.subdata(in: 12..<questionEnd)
        return DNSMessage(id: id, queryName: qname.lowercased(), queryType: qtype, queryClass: qclass, rawQuestion: rawQuestion)
    }

    /// build NXDOMAIN response (authority response, no answers)
    func buildNXDOMAINResponse() -> Data {
        var out = Data()
        out.append(UInt8((id >> 8) & 0xFF))
        out.append(UInt8(id & 0xFF))
        out.append(0x81)
        out.append(0x83)
        out.append(contentsOf: [0, 1, 0, 0, 0, 0, 0, 0])
        out.append(rawQuestion)
        return out
    }
}
