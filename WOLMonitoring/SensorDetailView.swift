//
//  SensorDetailView.swift
//  WOLMonitoring
//
//  Created by Keith Beavers on 9/25/25.
//


import SwiftUI

struct SensorDetailView: View {
    // This view now receives a binding to SensorData to show live updates.
    @Binding var sensor: SensorData
    
    var body: some View {
        List {
            Section("Sensor Details") {
                LabeledContent("Name", value: sensor.name)
                LabeledContent {
                    Text("\(String(format: "%.1f", sensor.value)) \(sensor.unit)")
                } label: {
                    Text("Current Reading")
                }
            }
            
            Section("Historical Data") {
                // Placeholder for future graphs or data logs
                Text("No historical data available.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(sensor.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
