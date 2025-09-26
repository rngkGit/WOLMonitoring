//
//  Computer.swift
//  WOLMonitoring
//
//  Created by Keith Beavers on 9/24/25.
//

import Foundation

enum OnlineStatus: Codable, Hashable { // Added Codable and Hashable
    case unknown
    case online
    case offline
    case warning

    /// Returns a semantic color name for the status, useful for UI representation.
    var colorName: String {
        switch self {
        case .online:
            return "green" // e.g., for a green icon
        case .warning:
            return "orange" // e.g., for an orange icon
        case .offline:
            return "red" // e.g., for a red icon
        case .unknown:
            return "gray" // e.g., for a gray or indeterminate icon
        }
    }
}

struct Computer: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String?
    var components: [Component] = []

    // This property is transient and will not be saved to disk.
    // It is managed by the PingingService.
    var onlineStatus: OnlineStatus = .unknown

    var macAddress: String? {
        for component in components {
            if case .macAddress(let macData) = component, !macData.address.isEmpty {
                return macData.address
            }
        }
        return nil
    }
    
    var ipAddress: String? {
        for component in components {
            if case .ipAddress(let ipData) = component, !ipData.address.isEmpty {
                return ipData.address
            }
        }
        return nil
    }
    
    // MARK: - Codable Conformance
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case components
    }
    
    // We need a custom initializer to set the default value for onlineStatus,
    // which is not part of the encoded data.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.components = try container.decode([Component].self, forKey: .components)
        self.onlineStatus = .unknown
    }
    
    // We need a custom encode function to exclude onlineStatus from being saved.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(components, forKey: .components)
    }
    
    // Default initializer for creating new computers.
    init(id: UUID = UUID(), name: String?, components: [Component] = []) {
        self.id = id
        self.name = name
        self.components = components
        self.onlineStatus = .unknown
    }
    
    // MARK: - Equatable & Hashable Conformance
    
    // Conformance is based on ID only to ensure stable identity even when other properties change.
    static func == (lhs: Computer, rhs: Computer) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
