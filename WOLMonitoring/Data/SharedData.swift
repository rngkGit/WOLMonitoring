//
//  SharedData.swift
//  WOLMonitoring
//
//  Created by Keith Beavers on 9/24/25.
//

import Foundation
internal import Combine

class SharedData: ObservableObject {
    @Published var selectedComputer: Computer?
}
