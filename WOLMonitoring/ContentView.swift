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
                                    Text(computer.macAddress ?? "No MAC Address")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "desktopcomputer")
                                    .imageScale(.large)
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
                    ComputerView(computer: $computerManager.computers[index])
                } else {
                    // Fallback for a computer that might have been deleted
                    // while the detail view is pushed.
                    Text("Computer not found")
                }
            }
            .toolbar {
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
}

#Preview {
    ContentView()
}
