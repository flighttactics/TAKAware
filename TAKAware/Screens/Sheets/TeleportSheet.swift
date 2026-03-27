//
//  TeleportSheet.swift
//  TAKAware
//
//  PoC: CoT Anti-Spoofing — COT-001 Teleport Demonstration
//  Allows selecting a contact and teleporting them to a chosen location.
//

import CoreData
import MapKit
import SwiftUI

struct TeleportSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var takManager: TAKManager

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \COTData.callsign, ascending: true)],
        predicate: NSPredicate(format: "role != NULL")
    )
    private var contacts: FetchedResults<COTData>

    @State private var selectedContact: COTData?
    @State private var targetLat: String = ""
    @State private var targetLon: String = ""
    @State private var showMapPicker = false
    @State private var pickedCoordinate: CLLocationCoordinate2D?
    @State private var statusMessage: String = ""

    // Preset locations for quick demo
    private let presets: [(String, Double, Double)] = [
        ("Ottawa",    45.4215, -75.6972),
        ("Montreal",  45.5019, -73.5674),
        ("Toronto",   43.6532, -79.3832),
        ("Calgary",   51.0447, -114.0719),
        ("Vancouver", 49.2827, -123.1207),
        ("Halifax",   44.6488, -63.5752),
        ("Null Island", 0.0, 0.0),
    ]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("⚠️ Security PoC — COT-001")) {
                    Text("This demonstrates the UID impersonation vulnerability. The selected contact will appear to teleport on all connected clients' maps.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                Section(header: Text("Select Target")) {
                    if contacts.isEmpty {
                        Text("No contacts available. Connect to a TAK server first.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(contacts, id: \.self) { contact in
                            Button {
                                selectedContact = contact
                            } label: {
                                HStack {
                                    if selectedContact == contact {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                    }
                                    VStack(alignment: .leading) {
                                        Text(contact.callsign ?? "Unknown")
                                            .foregroundColor(.primary)
                                        Text(contact.cotUid ?? "no uid")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Destination")) {
                    HStack {
                        TextField("Latitude", text: $targetLat)
                            .keyboardType(.decimalPad)
                        TextField("Longitude", text: $targetLon)
                            .keyboardType(.decimalPad)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(presets, id: \.0) { preset in
                                Button(preset.0) {
                                    targetLat = String(preset.1)
                                    targetLon = String(preset.2)
                                }
                                .buttonStyle(.bordered)
                                .font(.caption)
                            }
                        }
                    }

                    Button {
                        showMapPicker = true
                    } label: {
                        Label("Pick on Map", systemImage: "map")
                    }
                }

                Section {
                    Button {
                        executeTeleport()
                    } label: {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Teleport")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(selectedContact == nil || targetLat.isEmpty || targetLon.isEmpty)

                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundColor(statusMessage.contains("✓") ? .green : .red)
                    }
                }
            }
            .navigationTitle("Teleport PoC")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showMapPicker) {
                TeleportMapPicker(coordinate: $pickedCoordinate)
                    .onDisappear {
                        if let coord = pickedCoordinate {
                            targetLat = String(format: "%.6f", coord.latitude)
                            targetLon = String(format: "%.6f", coord.longitude)
                        }
                    }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func executeTeleport() {
        guard let contact = selectedContact,
              let uid = contact.cotUid,
              let lat = Double(targetLat),
              let lon = Double(targetLon) else {
            statusMessage = "✗ Invalid target or coordinates"
            return
        }

        let callsign = contact.callsign ?? "Unknown"
        takManager.teleportContact(
            targetUid: uid,
            callsign: callsign,
            toLatitude: lat,
            toLongitude: lon
        )
        statusMessage = "✓ Sent spoofed CoT for \(callsign) → [\(lat), \(lon)]"
    }
}

// MARK: - Map Picker

struct TeleportMapPicker: View {
    @Environment(\.dismiss) var dismiss
    @Binding var coordinate: CLLocationCoordinate2D?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 45.4215, longitude: -75.6972),
        span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
    )
    @State private var pin: CLLocationCoordinate2D?

    var body: some View {
        NavigationView {
            ZStack {
                Map(coordinateRegion: $region, annotationItems: pin.map { [PinItem(coordinate: $0)] } ?? []) { item in
                    MapMarker(coordinate: item.coordinate, tint: .red)
                }
                .onTapGesture { location in
                    // Convert tap to coordinate — approximate using region
                    // This is a simplified approach for the PoC
                }
                .ignoresSafeArea()

                // Crosshair in center
                Image(systemName: "plus")
                    .font(.title)
                    .foregroundColor(.red)
            }
            .navigationTitle("Tap to select location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Use Center") {
                        coordinate = region.center
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

private struct PinItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
