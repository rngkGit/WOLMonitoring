//
//  ComputerView.swift
//  WOLMonitoring
//
//  Created by Keith Beavers on 9/24/25.
//

import SwiftUI

struct ComputerView: View {
    @Binding var computer: Computer
    @State private var isPresentingEditView = false
    
    var body: some View {
        List {
            Section("Summary") {
                HStack(spacing: 16) {
                    Image(systemName: "desktopcomputer")
                        .font(.largeTitle)
                        .imageScale(.large)
                        .frame(width: 60)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(computer.name ?? "Unknown Computer")
                            .font(.headline)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Details") {
                if computer.components.isEmpty {
                    Text("No components added yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach($computer.components) { $component in
                        ComponentRowView(component: $component)
                    }
                }
            }
        }
        .navigationTitle(computer.name ?? "Computer Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    isPresentingEditView = true
                }
            }
        }
        .sheet(isPresented: $isPresentingEditView) {
            EditComputerView(computer: $computer)
        }
    }
}

fileprivate struct ComponentRowView: View {
    @Binding var component: Component
    
    var body: some View {
        switch component {
        case .ipAddress(let ipData):
            VStack(alignment: .leading, spacing: 2) {
                Text("IP Address")
                    .font(.headline)
                Text(ipData.address)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        case .macAddress(let macData):
            VStack(alignment: .leading, spacing: 2) {
                Text("MAC Address")
                    .font(.headline)
                Text(macData.address)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        case .sensor:
            // Use the binding extension to safely get a binding to the sensor data
            if let sensorBinding = $component.sensor {
                NavigationLink(destination: SensorDetailView(sensor: sensorBinding)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sensorBinding.wrappedValue.name)
                            .font(.headline)
                        Text("\(String(format: "%.1f", sensorBinding.wrappedValue.value)) \(sensorBinding.wrappedValue.unit)")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
