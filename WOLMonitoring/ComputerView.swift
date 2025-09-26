//
//  ComputerView.swift
//  WOLMonitoring
//
//  Created by Keith Beavers on 9/24/25.
//

import SwiftUI

struct ComputerView: View {
    @Binding var computer: Computer
    var computerManager: ComputerManager
    @State private var isPresentingEditView = false
    
    var body: some View {
        List {
            Section("Summary") {
                HStack(spacing: 16) {
                    Image(systemName: "desktopcomputer")
                        .font(.largeTitle)
                        .imageScale(.large)
                        .frame(width: 60)
                        .foregroundStyle(statusColor) // This will now correctly show orange for warning

                    VStack(alignment: .leading, spacing: 4) {
                        Text(computer.name ?? "Unknown Computer")
                            .font(.headline)
                        Text(statusText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Details") {
                if computer.components.isEmpty {
                    VStack(spacing: 12) {
                        Text("No components added yet.")
                            .foregroundStyle(.secondary)
                        Button("Add Component") {
                            isPresentingEditView = true
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical)
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
                Button {
                    computerManager.refreshComputerStatus(withId: computer.id)
                } label: {
                    Label("Refresh Status", systemImage: "arrow.clockwise")
                }
            }
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
    
    private var statusText: String {
        if computer.ipAddress == nil {
            return "No IP Address for Status Check"
        }
        
        switch computer.onlineStatus {
        case .online:
            return "Online"
        case .offline:
            return "Offline"
        case .warning:
            return "Service Offline" // This text clearly differentiates "service offline"
        case .unknown:
            return "Checking Status..."
        }
    }

    private var statusColor: Color {
        if computer.ipAddress == nil {
            return .secondary
        }

        switch computer.onlineStatus {
        case .online:
            return .green
        case .offline:
            return .red
        case .warning:
            return .orange // Changed from .yellow to .orange
        case .unknown:
            return .gray // Changed from .orange to .gray
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
