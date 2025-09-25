//
//  ComputerList.swift
//  WOLMonitoring
//
//  Created by Keith Beavers on 9/24/25.
//

import Foundation

struct ComputerList: Identifiable {
    let id: UUID = UUID()
    var computerName: String?
    var macAddress: String?
}
