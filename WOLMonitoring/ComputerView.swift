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
    @State private var isShowingAddComponentSheet = false // New state for adding components
    
    var body: some View {
        // Removed the VStack around the List and the Add Component button
        VStack {
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
                
                // MARK: - New Wake on LAN Section
                if let macAddress = computer.macAddress {
                    Section("Actions") {
                        Button {
                            Task {
                                await computerManager.wakeOnLAN(macAddress: macAddress)
                            }
                        } label: {
                            Label("Wake Up Computer", systemImage: "power.dotted")
                        }
                    }
                }
                
                Section("Details") {
                    // Always show components if they exist, otherwise a placeholder
                    if computer.components.isEmpty {
                        VStack { // Use a VStack to hold the text and the new button
                            Text("No components added yet.")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical)
                            
                            Button("Add Component") { // New button to add components
                                isShowingAddComponentSheet = true
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.bottom)
                        }
                    } else {
                        ForEach($computer.components) { $component in
                            ComponentRowView(component: $component) { componentID in
                                // This closure is called when a component requests deletion
                                computer.components.removeAll(where: { $0.id == componentID })
                            }
                        }
                    }
                }
            }
            .refreshable { // Added pull-to-refresh for this computer's status
                // Reverted to withId: as requested
                await computerManager.refreshComputerStatus(withId: computer.id)
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isShowingAddComponentSheet = true
                } label: {
                    Label("Add Component", systemImage: "plus") // Using plus.circle.fill for better visibility
                }
            }
        }
        .sheet(isPresented: $isPresentingEditView) {
            EditComputerView(computer: $computer)
        }
        .sheet(isPresented: $isShowingAddComponentSheet) {
            // New sheet for adding components, now passing existing components
            AddComponentScreenView(existingComponents: computer.components) { newComponent in
                computer.components.append(newComponent)
            }
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
    var onDeleteComponent: (Component.ID) -> Void // Closure to propagate component deletion
    
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
                NavigationLink(destination: SensorDetailView(sensor: sensorBinding, onDelete: { sensorID in
                    // When SensorDetailView requests deletion, pass it up to ComputerView
                    onDeleteComponent(sensorID)
                })) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sensorBinding.wrappedValue.name)
                            .font(.headline)
                        Text(sensorBinding.wrappedValue.displayString)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
