//
//  ComputerManager.swift
//  WOLMonitoring
//
//  Created by Keith Beavers on 9/24/25.
//

import SwiftUI
internal import Combine
import Network // Added for Wake on LAN functionality

@MainActor
class ComputerManager: ObservableObject {
    @Published var computers: [Computer] = []
    
    private var saveCancellable: AnyCancellable?
    private var pollingCancellable: AnyCancellable?
    private var pingTimerCancellable: AnyCancellable?
    
    private let computersFileURL: URL
    private let sensorPollingService = SensorPollingService()
    private let pingingService = PingingService()
    
    init() {
        // Get the URL for the documents directory.
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.computersFileURL = documentsDirectory.appendingPathComponent("computers.json")
        
        // Load computers on initialization.
        self.getComputers()
        
        // This subscription handles saving data and telling the polling service
        // to update its tasks whenever the computers array changes.
        saveCancellable = $computers
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] computers in
                self?.saveComputers()
                self?.sensorPollingService.updatePolling(for: computers)
            }
        
        // This subscription listens for updates from the polling service
        // and applies them to our local computer data.
        pollingCancellable = sensorPollingService.sensorUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.applySensorUpdate(update)
            }
        
        // Initial call to set up polling for existing computers.
        sensorPollingService.updatePolling(for: computers)

        // Start pinging computers.
        startPinging()
    }
    
    func addComputer(_ computer: Computer) {
        self.computers.append(computer)
        refreshComputerStatus(withId: computer.id) // Ping new computer immediately.
    }
    
    func removeComputer(atOffsets offsets: IndexSet) {
        self.computers.remove(atOffsets: offsets)
    }
    
    // Re-added method for reordering computers
    func moveComputers(fromOffsets source: IndexSet, toOffset destination: Int) {
        self.computers.move(fromOffsets: source, toOffset: destination)
    }
    
    func getComputers() {
        computers = loadComputersFromFile()
    }
    
    // MARK: - Pinging
    
    /// Pings all computers that have an VaporIP address and updates their online status.
    func refreshAllComputersStatus() {
        Task {
            await withTaskGroup(of: (UUID, OnlineStatus).self) { group in
                for computer in computers {
                    if let ipAddress = computer.ipAddress {
                        group.addTask {
                            let status = await self.pingingService.ping(address: ipAddress)
                            return (computer.id, status)
                        }
                    }
                }
                
                for await (id, status) in group {
                    if let index = self.computers.firstIndex(where: { $0.id == id }) {
                        self.computers[index].onlineStatus = status
                    }
                }
            }
        }
    }
    
    /// Pings a single computer by its ID.
    func refreshComputerStatus(withId id: UUID) {
        guard let index = computers.firstIndex(where: { $0.id == id }),
              let ipAddress = computers[index].ipAddress else {
            return
        }
        
        Task {
            let status = await pingingService.ping(address: ipAddress)
            if let computerIndex = self.computers.firstIndex(where: { $0.id == id }) {
                self.computers[computerIndex].onlineStatus = status
            }
        }
    }
    
    private func startPinging() {
        stopPinging() // Ensure no previous timer is running
        
        // Ping once on startup
        refreshAllComputersStatus()
        
        // Schedule repeating pings every 10 seconds.
        pingTimerCancellable = Timer.publish(every: 10.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshAllComputersStatus()
            }
    }
    
    private func stopPinging() {
        pingTimerCancellable?.cancel()
        pingTimerCancellable = nil
    }
    
    /// Applies a sensor data update received from the polling service to the @Published computers array.
    private func applySensorUpdate(_ update: SensorUpdate) {
        guard let computerIndex = computers.firstIndex(where: { $0.id == update.computerId }),
              let componentIndex = computers[computerIndex].components.firstIndex(where: { $0.id == update.sensorId }) else {
            return
        }
        
        if case .sensor(var sensorData) = computers[computerIndex].components[componentIndex] {
            sensorData.value = update.value
            computers[computerIndex].components[componentIndex] = .sensor(sensorData)
        }
    }
    
    private func loadComputersFromFile() -> [Computer] {
        do {
            let data = try Data(contentsOf: computersFileURL)
            let decoder = JSONDecoder()
            return try decoder.decode([Computer].self, from: data)
        } catch {
            print("Could not load computers: \(error.localizedDescription)")
            // If the file doesn't exist or there's an error, return an empty array.
            return []
        }
    }
    
    private func saveComputers() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(computers)
            try data.write(to: computersFileURL, options: .atomic)
            print("Computers saved successfully.")
        } catch {
            print("Could not save computers: \(error.localizedDescription)")
        }
    }

    // MARK: - Wake on LAN
    
    /// Sends a Wake on LAN magic packet to the specified MAC address.
    /// This method attempts to send the packet to the broadcast address 255.255.255.255
    /// on UDP port 9.
    func wakeOnLAN(macAddress: String, broadcastIP: String = "255.255.255.255", port: UInt16 = 9) async {
        guard let macBytes = macAddress.macAddressBytes() else {
            print("Wake on LAN: Invalid MAC address format: \(macAddress)")
            return
        }
        print("Wake on LAN: Attempting to send magic packet to MAC: \(macAddress) on broadcast IP: \(broadcastIP):\(port)")

        // Construct the magic packet: 6 bytes of 0xFF, followed by 16 repetitions of the MAC address
        var magicPacket = Data(repeating: 0xFF, count: 6)
        for _ in 0..<16 {
            magicPacket.append(Data(macBytes))
        }

        let connection = NWConnection(host: NWEndpoint.Host(broadcastIP), port: NWEndpoint.Port(rawValue: port)!, using: .udp)

        connection.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                print("Wake on LAN: Connection is READY. Sending magic packet.")
                connection.send(content: magicPacket, completion: .contentProcessed({ error in
                    if let error = error {
                        print("Wake on LAN: Failed to send magic packet to \(macAddress): \(error.localizedDescription)")
                    } else {
                        print("Wake on LAN: Magic packet sent successfully to \(macAddress) on \(broadcastIP):\(port)")
                    }
                    connection.cancel() // Close connection after sending
                }))
            case .waiting(let error):
                print("Wake on LAN: Connection WAITING for \(macAddress): \(error.debugDescription)")
            case .failed(let error):
                print("Wake on LAN: Connection FAILED for \(macAddress): \(error.localizedDescription)")
                connection.cancel()
            case .cancelled:
                print("Wake on LAN: Connection CANCELLED for \(macAddress).")
            case .setup:
                print("Wake on LAN: Connection is in SETUP state for \(macAddress).")
            case .preparing:
                print("Wake on LAN: Connection is PREPARING for \(macAddress).")
            default:
                print("Wake on LAN: Connection in UNKNOWN state for \(macAddress).")
            }
        }
        
        connection.start(queue: .global(qos: .default))
    }
}

// MARK: - String Extension for MAC Address Parsing
fileprivate extension String {
    /// Converts a MAC address string (e.g., "00:11:22:33:44:55" or "00-11-22-33-44-55")
    /// into an array of 6 UInt8 bytes.
    func macAddressBytes() -> [UInt8]? {
        let hexComponents = self.split(whereSeparator: { $0 == ":" || $0 == "-" }).map { String($0) }
        guard hexComponents.count == 6 else { return nil }
        
        var bytes = [UInt8]()
        for component in hexComponents {
            guard let byte = UInt8(component, radix: 16) else { return nil }
            bytes.append(byte)
        }
        return bytes
    }
}
