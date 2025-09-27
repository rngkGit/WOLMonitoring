//
//  AddComponentScreenView.swift
//  WOLMonitoring
//
//  Created by Keith Beavers on 9/25/25.
//

import SwiftUI

struct AddComponentScreenView: View {
    @Environment(\.dismiss) var dismiss
    var existingComponents: [Component] // Added to check for existing components
    var onAddComponent: (Component) -> Void
    
    // State to manage input for a new sensor
    @State private var newSensorName: String = "" // Default to empty string
    @State private var newSensorType: String = "CPU Temp"
    @State private var newSensorUnit: String = "ºC" // Default to Celsius
    
    // State to manage input for a new IP Address
    @State private var newIPAddress: String = ""
    @State private var ipAddressError: String?

    // State to manage input for a new MAC Address
    @State private var newMACAddress: String = ""
    @State private var macAddressError: String?
    
    // State to control which type of component is being added
    @State private var selectedComponentType: ComponentType? = nil
    
    enum ComponentType: String, CaseIterable, Identifiable {
        case ipAddress = "IP Address"
        case macAddress = "MAC Address"
        case sensor = "Sensor"
        
        var id: String { self.rawValue }
    }
    
    private var isIPAddressValid: Bool {
        if newIPAddress.isEmpty { return false }
        return IPData.isValidIPAddress(newIPAddress)
    }
    
    private var isMACAddressValid: Bool {
        if newMACAddress.isEmpty { return false }
        // The MACAddressData.isValidMACAddress now handles various formats
        return MACAddressData.isValidMACAddress(newMACAddress)
    }
    
    // New computed property to check for existing IP Address components
    private var hasIPAddressComponent: Bool {
        existingComponents.contains { component in
            if case .ipAddress = component { return true }
            return false
        }
    }

    // New computed property to check for existing MAC Address components
    private var hasMACAddressComponent: Bool {
        existingComponents.contains { component in
            if case .macAddress = component { return true }
            return false
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Select Component Type", selection: $selectedComponentType) {
                    Text("Select a type").tag(nil as ComponentType?) // Optional nil tag for placeholder
                    ForEach(ComponentType.allCases) { type in
                        // Conditionally include options based on existing components
                        if type == .ipAddress && hasIPAddressComponent {
                            // Do not include this option if an IP Address already exists
                        } else if type == .macAddress && hasMACAddressComponent {
                            // Do not include this option if a MAC Address already exists
                        } else {
                            Text(type.rawValue).tag(type as ComponentType?)
                        }
                    }
                }
                // Reset selection if the currently selected type becomes disabled
                .onChange(of: hasIPAddressComponent) { oldValue, newValue in
                    if newValue == true && selectedComponentType == .ipAddress {
                        selectedComponentType = nil
                    }
                }
                .onChange(of: hasMACAddressComponent) { oldValue, newValue in
                    if newValue == true && selectedComponentType == .macAddress {
                        selectedComponentType = nil
                    }
                }
                
                if selectedComponentType == .ipAddress {
                    Section("New IP Address") {
                        TextField("IP Address", text: $newIPAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .keyboardType(.decimalPad)
                            .onChange(of: newIPAddress) {
                                validateIPAddressInput(newIPAddress)
                            }
                        if let error = ipAddressError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                } else if selectedComponentType == .macAddress {
                    Section("New MAC Address") {
                        TextField("MAC Address", text: $newMACAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onChange(of: newMACAddress) {
                                validateMacAddressInput(newMACAddress)
                            }
                        if let error = macAddressError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                } else if selectedComponentType == .sensor {
                    Section("New Sensor") {
                        TextField("Sensor Name", text: $newSensorName) // User must type name
                        Picker("Sensor Type", selection: $newSensorType) {
                            Text("CPU Temp").tag("CPU Temp")
                        }
                        // Removed onChange here, name is now independently managed by TextField
                        
                        // Picker for unit selection
                        Picker("Unit", selection: $newSensorUnit) {
                            Text("Celsius (ºC)").tag("ºC")
                            Text("Fahrenheit (ºF)").tag("ºF")
                        }
                    }
                }
            }
            .onAppear {
                // Initial check to reset selection if IP/MAC already exists
                if hasIPAddressComponent && selectedComponentType == .ipAddress {
                    selectedComponentType = nil
                }
                if hasMACAddressComponent && selectedComponentType == .macAddress {
                    selectedComponentType = nil
                }
            }
            .navigationTitle("Add Component")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addComponentAndDismiss()
                    }
                    .disabled(!isFormValidForAdding) // Disable Save button if form is not valid
                }
            }
        }
    }
    
    private var isFormValidForAdding: Bool {
        guard let type = selectedComponentType else { return false }
        
        switch type {
        case .ipAddress:
            return isIPAddressValid
        case .macAddress:
            return isMACAddressValid
        case .sensor:
            // Require sensor name to be non-empty
            return !newSensorName.trimmingCharacters(in: .whitespaces).isEmpty &&
                   !newSensorType.trimmingCharacters(in: .whitespaces).isEmpty &&
                   !newSensorUnit.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }
    
    private func addComponentAndDismiss() {
        guard let type = selectedComponentType else { return }
        
        switch type {
        case .ipAddress:
            guard isIPAddressValid else { return }
            onAddComponent(.ipAddress(IPData(address: newIPAddress)))
        case .macAddress:
            guard isMACAddressValid else { return }
            // Format the MAC address with colons before saving
            let formattedMAC = formatMACAddress(newMACAddress)
            onAddComponent(.macAddress(MACAddressData(address: formattedMAC)))
        case .sensor:
            guard !newSensorName.isEmpty && !newSensorType.isEmpty && !newSensorUnit.isEmpty else { return }
            onAddComponent(.sensor(SensorData(name: newSensorName, type: newSensorType, value: 0.0, unit: newSensorUnit)))
        }
        dismiss()
    }
    
    /// Validates the given MAC address input and updates the `macAddressError` state.
    private func validateMacAddressInput(_ input: String) {
        let trimmedInput = input.trimmingCharacters(in: .whitespaces)
        
        if trimmedInput.isEmpty {
            macAddressError = "MAC Address cannot be empty."
        } else if !MACAddressData.isValidMACAddress(trimmedInput) {
            macAddressError = "Invalid MAC Address format. E.g., 00:11:22:33:44:55"
        } else {
            macAddressError = nil // MAC address is valid
        }
    }
    
    /// Validates the given IP address input and updates the `ipAddressError` state.
    private func validateIPAddressInput(_ input: String) {
        let trimmedInput = input.trimmingCharacters(in: .whitespaces)
        
        if trimmedInput.isEmpty {
            ipAddressError = "IP Address cannot be empty."
        } else if !IPData.isValidIPAddress(trimmedInput) {
            ipAddressError = "Invalid IP Address format. E.g., 192.168.1.1"
        } else {
            ipAddressError = nil // IP address is valid
        }
    }

    /// Formats a MAC address string (with or without separators) into the XX:XX:XX:XX:XX:XX format.
    /// Returns the original string if it cannot be formatted.
    private func formatMACAddress(_ mac: String) -> String {
        let cleanMAC = mac.replacingOccurrences(of: "[: -]", with: "", options: .regularExpression)
        
        guard cleanMAC.count == 12 else {
            return mac // Return original if not 12 hex chars after cleaning
        }
        
        var formatted = ""
        for i in 0..<6 {
            let startIndex = cleanMAC.index(cleanMAC.startIndex, offsetBy: i * 2)
            let endIndex = cleanMAC.index(startIndex, offsetBy: 2)
            formatted += cleanMAC[startIndex..<endIndex]
            if i < 5 {
                formatted += ":"
            }
        }
        return formatted
    }
}
