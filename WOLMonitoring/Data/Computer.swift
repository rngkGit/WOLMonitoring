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
    var macAddress: String?
    var components: [Component] = []
}
