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
                    .onDelete(perform: deleteComputer)
                }
                
                Button {
                    isShowingAddComputerView = true
                } label: {
                    Label("Add Computer", systemImage: "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding([.horizontal, .bottom])
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        computerManager.refreshAllComputersStatus()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .sheet(isPresented: $isShowingAddComputerView) {
                AddComputerView(computerManager: computerManager)
            }
        }
    }
    
    private func deleteComputer(at offsets: IndexSet) {
        computerManager.removeComputer(atOffsets: offsets)
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
            return .yellow
        case .unknown:
            return .orange
        }
    }
}

#Preview {
    ContentView()
}
