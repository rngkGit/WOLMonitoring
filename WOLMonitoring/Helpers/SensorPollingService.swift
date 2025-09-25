//
//  SensorPollingService.swift
//  WOLMonitoring
//
//  Created by Keith Beavers on 9/25/25.
//

import Foundation
internal import Combine
import Network

/// A data structure to transport sensor updates from the polling service to the data manager.
struct SensorUpdate {
    let computerId: UUID
    let sensorId: UUID
    let value: Double
}

/// A class dedicated to polling CPU temperature sensors for all computers.
class SensorPollingService {
    /// A Combine publisher that emits updates whenever a sensor's value is successfully fetched.
    let sensorUpdatePublisher = PassthroughSubject<SensorUpdate, Never>()
    
    /// A dictionary to hold and manage active polling tasks, keyed by sensor ID.
    private var pollingTasks: [UUID: Task<Void, Never>] = [:]

    deinit {
        stopPollingForAllSensors()
    }

    /// Scans all computers and sensors, starting or stopping polling tasks as needed to match the current configuration.
    func updatePolling(for computers: [Computer]) {
        var requiredSensorIDs = Set<UUID>()
        
        // Identify all sensors that should be polling
        for computer in computers {
            // Find the first valid IP address for this computer
            guard let ipAddress = computer.components.firstNonNil({
                if case .ipAddress(let ipData) = $0 { return ipData.address }
                return nil
            }) else {
                continue // No IP address, can't poll any sensors for this computer
            }
            
            // Find all CPU Temp sensors for this computer and start polling
            for component in computer.components {
                if case .sensor(let sensorData) = component, sensorData.type == "CPU Temp" {
                    requiredSensorIDs.insert(sensorData.id)
                    // Start polling if not already started
                    startPollingForSensor(computerId: computer.id, sensorId: sensorData.id, ipAddress: ipAddress)
                }
            }
        }
        
        // Stop polling for sensors that are no longer required (e.g., were deleted)
        let currentSensorIDs = Set(pollingTasks.keys)
        let sensorsToStop = currentSensorIDs.subtracting(requiredSensorIDs)
        for sensorId in sensorsToStop {
            stopPollingForSensor(sensorId: sensorId)
        }
    }
    
    /// Starts a polling task for a specific sensor.
    private func startPollingForSensor(computerId: UUID, sensorId: UUID, ipAddress: String) {
        guard pollingTasks[sensorId] == nil else { return } // Already polling

        let newPollingTask = Task {
            while !Task.isCancelled {
                if let temp = await fetchTemperature(ipAddress: ipAddress) {
                    // Send the update through the publisher instead of modifying data directly
                    let update = SensorUpdate(computerId: computerId, sensorId: sensorId, value: temp)
                    sensorUpdatePublisher.send(update)
                } else {
                    print("Failed to fetch temperature for sensor \(sensorId) from \(ipAddress)")
                }
                
                // If the task was cancelled during the fetch, exit the loop.
                guard !Task.isCancelled else { break }
                
                try? await Task.sleep(for: .seconds(5))
            }
            print("Polling task for sensor \(sensorId) cancelled or stopped.")
        }
        pollingTasks[sensorId] = newPollingTask
    }
    
    /// Stops a polling task for a specific sensor.
    private func stopPollingForSensor(sensorId: UUID) {
        pollingTasks[sensorId]?.cancel()
        pollingTasks.removeValue(forKey: sensorId)
    }

    /// Stops all currently active polling tasks.
    func stopPollingForAllSensors() {
        for task in pollingTasks.values {
            task.cancel()
        }
        pollingTasks.removeAll()
        print("All polling tasks stopped.")
    }

    /// Establishes a TCP connection and fetches temperature data.
    private func fetchTemperature(ipAddress: String) async -> Double? {
        let port: NWEndpoint.Port = 51201
        let host = NWEndpoint.Host(ipAddress)
        let connection = NWConnection(host: host, port: port, using: .tcp)
        
        return await withCheckedContinuation { continuation in
            var receivedData = Data()
            var hasResumed = false
            var timeoutTask: Task<Void, Never>?

            func safeResume(value: Double?) {
                if !hasResumed {
                    hasResumed = true
                    timeoutTask?.cancel()
                    connection.cancel()
                    continuation.resume(returning: value)
                }
            }
            
            timeoutTask = Task {
                try? await Task.sleep(for: .seconds(3))
                if !hasResumed {
                    print("Connection to \(ipAddress):\(port) timed out.")
                    safeResume(value: nil)
                }
            }

            connection.stateUpdateHandler = { newState in
                switch newState {
                case .ready:
                    connection.receiveMessage { (content, _, isComplete, error) in
                        if let content = content { receivedData.append(content) }
                        if isComplete || error != nil {
                            if let output = String(data: receivedData, encoding: .utf8),
                               let match = output.firstMatch(of: /CPU Temperature: (\d+\.?\d*) C/),
                               let temp = Double(String(match.1)) {
                                safeResume(value: temp)
                            } else {
                                safeResume(value: nil)
                            }
                        }
                    }
                case .failed, .cancelled:
                    safeResume(value: nil)
                default:
                    break
                }
            }
            connection.start(queue: .global(qos: .userInitiated))
        }
    }
}

// Helper extension to find the first non-nil result from a map.
extension Sequence {
    func firstNonNil<T>(_ transform: (Element) throws -> T?) rethrows -> T? {
        for element in self {
            if let result = try transform(element) {
                return result
            }
        }
        return nil
    }
}
