//
//  ContentView.swift
//  WOLMonitoring
//
//  Created by Keith Beavers on 9/24/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var computerManager = ComputerManager()
    @State private var isShowingAddComputerView = false
    
    // Environment value to check if the list is in editing mode
    @Environment(\.editMode) var editMode
    
    // State to manage delete confirmation
    @State private var showingDeleteConfirmation = false
    @State private var deleteOffsets: IndexSet?
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(computerManager.computers) { computer in
                        NavigationLink(value: computer) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(computer.name ?? "Unknown")
                                        .font(.headline)
                                    Text(statusText(for: computer))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "desktopcomputer")
                                    .imageScale(.large)
                                    .foregroundStyle(statusColor(for: computer))
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    // onDelete is now automatically conditional based on editMode
                    // SwiftUI's List will only allow swipe-to-delete when editMode is active and EditButton is present.
                    .onDelete { offsets in
                        deleteOffsets = offsets
                        showingDeleteConfirmation = true
                    }
                    .onMove(perform: computerManager.moveComputers) // Re-added onMove for reordering
                }
                .refreshable { // Pull-to-refresh for all computers' status
                    await computerManager.refreshAllComputersStatus()
                }
            }
            .navigationTitle("Computers")
            .navigationDestination(for: Computer.self) { computer in
                // Find the computer in the manager to create a binding for editing.
                if let index = computerManager.computers.firstIndex(where: { $0.id == computer.id }) {
                    ComputerView(computer: $computerManager.computers[index], computerManager: computerManager)
                } else {
                    // Fallback for a computer that might have been deleted
                    // while the detail view is pushed.
                    Text("Computer not found")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton() // Re-added EditButton to control editing mode
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingAddComputerView = true
                    } label: {
                        Label("Add Computer", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddComputerView) {
                AddComputerView(computerManager: computerManager)
            }
            // Confirmation alert for deletion
            .alert("Delete Computer?", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let offsets = deleteOffsets {
                        computerManager.removeComputer(atOffsets: offsets)
                    }
                    deleteOffsets = nil // Clear the stored offsets
                }
                Button("Cancel", role: .cancel) {
                    deleteOffsets = nil // Clear the stored offsets
                }
            } message: {
                Text("Are you sure you want to delete the selected computer? This action cannot be undone.")
            }
        }
    }
    
    private func statusText(for computer: Computer) -> String {
        guard computer.ipAddress != nil else {
            return computer.macAddress ?? "No Details"
        }
        
        switch computer.onlineStatus {
        case .online:
            return "Online"
        case .offline:
            return "Offline"
        case .warning:
            return "Service Offline"
        case .unknown:
            return "Checking Status..."
        }
    }

    private func statusColor(for computer: Computer) -> Color {
        guard computer.ipAddress != nil else {
            return .secondary
        }

        switch computer.onlineStatus {
        case .online:
            return .green
        case .offline:
            return .red
        case .warning:
            return .orange
        case .unknown:
            return .orange
        }
    }
}

#Preview {
    ContentView()
}
