//
//  PingingService.swift
//  WOLMonitoring
//
//  Created by Keith Beavers on 9/24/25.
//

import Foundation
import Network

// The OnlineStatus enum definition has been moved to Computer.swift to resolve ambiguity.
// It is now available globally from that file.

actor PingingService {
    /// Checks the status of a host based on its response to a connection attempt.
    /// - .online: The computer is on and the helper service is running.
    /// - .warning: The computer is on, but the helper service is not running.
    /// - .offline: The computer is off or not responding on the network.
    func ping(address: String) async -> OnlineStatus {
        let servicePort: NWEndpoint.Port = 51201
        // Port 22 is a common port for general host reachability (e.g., SSH).
        // You might need to adjust this if the target machine doesn't have an always-open port 22,
        // or if you prefer a different well-known port.
        let generalReachabilityPort: NWEndpoint.Port = 22

        print("PingingService: Starting ping for \(address)...")

        // Step 1: Attempt connection to the specific service port (51201)
        // Give it a bit more time for explicit refusal if the OS sends one.
        let serviceCheckResult = await attemptConnection(address: address, port: servicePort, timeout: 3.0)

        if serviceCheckResult.connected {
            print("PingingService: \(address): Final Status for \(address): .online (Service port \(servicePort) connected)")
            return .online
        }

        if serviceCheckResult.refused {
            print("PingingService: \(address): Final Status for \(address): .warning (Service port \(servicePort) refused, indicating host is responsive but service is off)")
            return .warning
        }

        // If we're here, service port either timed out or had another non-refused failure.
        // This is ambiguous: computer could be off, or on but service is off (and silently dropping packets).
        // Proceed to a general host reachability check.
        print("PingingService: \(address): Service port \(servicePort) ambiguous (timed out/other failure). Performing secondary check on port \(generalReachabilityPort)...")

        // Step 2: Attempt a general host reachability check on a common port (e.g., 22).
        // This check has a slightly longer timeout as a fallback.
        let generalCheckResult = await attemptConnection(address: address, port: generalReachabilityPort, timeout: 4.0)

        if generalCheckResult.connected || generalCheckResult.refused {
            // The general reachability check found the host to be online (either connected or explicitly refused on port 22).
            // Since the service port (51201) didn't connect or explicitly refuse,
            // this strongly implies the computer is on but the service is off (or silently dropping packets).
            print("PingingService: \(address): Final Status for \(address): .warning (General port \(generalReachabilityPort) connected or refused, confirming host is on but service \(servicePort) is not)")
            return .warning
        } else {
            // Both the service port and the general port timed out or had other non-refused failures.
            // This indicates the computer is likely completely offline or unreachable.
            print("PingingService: \(address): Final Status for \(address): .offline (Both service port \(servicePort) and general port \(generalReachabilityPort) timed out/failed)")
            return .offline
        }
    }

    /// Helper function to encapsulate the NWConnection logic for a given port and timeout.
    /// Returns a tuple indicating if the connection was established, refused, or timed out/failed otherwise.
    private func attemptConnection(address: String, port: NWEndpoint.Port, timeout: TimeInterval) async -> (connected: Bool, refused: Bool) {
        let host = NWEndpoint.Host(address)
        let connection = NWConnection(host: host, port: port, using: .tcp)

        return await withCheckedContinuation { continuation in
            var hasResumed = false

            // Centralized handler to safely resume the continuation once.
            let complete: ((connected: Bool, refused: Bool)) -> Void = { result in
                if !hasResumed {
                    hasResumed = true
                    connection.cancel() // Cancel the connection to release resources and stop further state updates.
                    continuation.resume(returning: result)
                }
            }

            // Setup a timeout for this specific connection attempt.
            let timeoutTask = Task {
                do {
                    try await Task.sleep(for: .seconds(timeout))
                    // If we reach here, no definitive state (ready or failed) was achieved in time.
                    print("PingingService: \(address): Port \(port): Connection timed out after \(timeout)s. Resuming with (connected: false, refused: false).")
                    complete((connected: false, refused: false)) // Neither connected nor refused within timeout
                } catch is CancellationError {
                    // Task was cancelled, likely because connection completed sooner.
                    print("PingingService: \(address): Port \(port): Timeout task cancelled because connection completed sooner.")
                }
            }

            // The stateUpdateHandler is the core of our logic, called by the system
            // whenever the connection's state changes.
            connection.stateUpdateHandler = { newState in
                print("PingingService: \(address): Port \(port): State changed to \(newState)")
                switch newState {
                case .ready:
                    // SCENARIO: Connection successful.
                    timeoutTask.cancel()
                    complete((connected: true, refused: false))
                    
                case .failed(let error):
                    // SCENARIO: Connection failed.
                    timeoutTask.cancel()
                    print("PingingService: \(address): Port \(port): Connection failed with error: \(error)")
                    if case .posix(let code) = error, code == .ECONNREFUSED {
                        // Explicit "Connection refused" indicates host is on, but port is closed.
                        complete((connected: false, refused: true))
                    } else {
                        // Any other failure (e.g., host unreachable, network down).
                        complete((connected: false, refused: false))
                    }

                case .waiting(let error):
                    // **CRITICAL FIX HERE:**
                    // Connection is waiting (e.g., for network path or resources).
                    // We now also check for explicit connection refused errors in the waiting state.
                    print("PingingService: \(address): Port \(port): Waiting with error: \(error)")
                    if case .posix(let code) = error, code == .ECONNREFUSED {
                        // If connection is refused in a waiting state, treat it as a refusal.
                        timeoutTask.cancel() // Cancel timeout, we have a definitive state.
                        print("PingingService: \(address): Port \(port): Connection refused while waiting. Resuming with (connected: false, refused: true).")
                        complete((connected: false, refused: true))
                    } else {
                        // For other waiting errors, we continue to wait for a definitive .ready or .failed state.
                        break
                    }

                case .cancelled:
                    // Connection was explicitly cancelled by our `complete` handler.
                    print("PingingService: \(address): Port \(port): Connection cancelled.")
                    // No need to complete here; `complete` already did its job.

                default:
                    // .preparing, .setup. These are intermediate states; we ignore them and wait.
                    break
                }
            }
            
            // Start the connection process.
            connection.start(queue: .global())
        }
    }
}
