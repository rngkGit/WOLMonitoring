//
//  Computer.swift
//  WOLMonitoring
//
//  Created by Keith Beavers on 9/24/25.
//

import Foundation

struct Computer: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String?
    var components: [Component] = []

    var macAddress: String? {
        for component in components {
            if case .macAddress(let macData) = component, !macData.address.isEmpty {
                return macData.address
            }
        }
        return nil
    }
}
