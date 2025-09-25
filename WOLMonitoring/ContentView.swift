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
            .navigationTitle("Home")
            .navigationDestination(for: Computer.self) { computer in
                ComputerView(computer: computer)
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
