//
//  Computer.swift
//  WOLMonitoring
//
//  Created by Keith Beavers on 9/24/25.
//

import Foundation

struct Computer: Identifiable, Hashable, Codable {
    let id: UUID = UUID()
    var name: String?
    var macAddress: String?
}
