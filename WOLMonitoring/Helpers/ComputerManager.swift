//
//  ComputerManager.swift
//  WOLMonitoring
//
//  Created by Keith Beavers on 9/24/25.
//

import SwiftUI
internal import Combine

class ComputerManager: ObservableObject {
    @Published var computers: [Computer] = []
    private var cancellable: AnyCancellable?
    
    private let computersFileURL: URL
    
    init() {
        // Get the URL for the documents directory.
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.computersFileURL = documentsDirectory.appendingPathComponent("computers.json")
        
        // Load computers on initialization.
        self.getComputers()
        
        // Automatically save computers when the array changes.
        cancellable = $computers
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main) // Debounce to avoid excessive writes
            .sink { [weak self] _ in
                self?.saveComputers()
            }
    }
    
    func addComputer(_ computer: Computer) {
        self.computers.append(computer)
    }
    
    func removeComputer(atOffsets offsets: IndexSet) {
        self.computers.remove(atOffsets: offsets)
    }
    
    func getComputers() {
        computers = loadComputersFromFile()
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
}
