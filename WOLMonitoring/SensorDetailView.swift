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
    var onDelete: ((SensorData.ID) -> Void)? // Closure to notify parent to delete this sensor
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        List {
            Section("Sensor Details") {
                LabeledContent("Sensor Name", value: sensor.name)
                LabeledContent {
                    // Correctly create a Text view using the new displayString computed property
                    Text(sensor.displayString)
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Remove Sensor", systemImage: "trash.fill")
                }
            }
        }
        .confirmationDialog("Remove Sensor", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Remove Sensor", role: .destructive) {
                onDelete?(sensor.id)
            }
        } message: {
            Text("Are you sure you want to remove the sensor '\(sensor.name)'?")
        }
    }
}
