//
//  ServerListScreen.swift
//  TAKAware
//

import SwiftUI

struct ServerListScreen: View {
    @ObservedObject var settingsStore = SettingsStore.global

    var body: some View {
        List {
            ForEach(settingsStore.serverConfigurations) { config in
                ServerConfigRow(config: config)
            }
            .onDelete { offsets in
                offsets.forEach {
                    settingsStore.deleteServerConfiguration(
                        id: settingsStore.serverConfigurations[$0].id
                    )
                }
            }
        }
        .overlay {
            if settingsStore.serverConfigurations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "antenna.radiowaves.left.and.right.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Servers")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Add a server using the + button")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Servers")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(
                    destination: ConnectionOptionsScreen(isProcessingDataPackage: .constant(false))
                ) {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

struct ServerConfigRow: View {
    let config: ServerConfiguration
    @ObservedObject var settingsStore = SettingsStore.global

    var isActive: Bool { settingsStore.activeServerId == config.id }

    var statusDotColor: Color {
        guard isActive else { return Color(.systemGray4) }
        return settingsStore.isConnectedToServer ? .green : .yellow
    }

    var statusLabel: String {
        guard isActive else { return "" }
        return settingsStore.isConnectedToServer ? "Connected" : settingsStore.connectionStatus
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusDotColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 3) {
                Text(config.name)
                    .font(.headline)
                    .foregroundColor(isActive ? .primary : .secondary)
                Text("\(config.host):\(config.port)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isActive && !statusLabel.isEmpty {
                Text(statusLabel)
                    .font(.caption2)
                    .foregroundColor(settingsStore.isConnectedToServer ? .green : .secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            settingsStore.activateServer(id: config.id)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                settingsStore.activateServer(id: config.id)
            } label: {
                Label("Connect", systemImage: "antenna.radiowaves.left.and.right")
            }
            .tint(.blue)
        }
    }
}
