//
//  ComputerView.swift
//  WOLMonitoring
//
//  Created by Keith Beavers on 9/24/25.
//

import SwiftUI

struct ComputerView: View {
    let computer: Computer
    
    var body: some View {
        VStack(spacing: 8) {
            Text(computer.name ?? "Error")
                .font(.largeTitle)
                .padding()
            
            Text(computer.macAddress ?? "No MAC Address")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .navigationTitle(computer.name ?? "Computer Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
