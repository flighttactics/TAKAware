//
//  ContactsSheet.swift
//  TAKAware
//
//  Created by Cory Foy on 5/18/25.
//

import CoreData
import Foundation
import MapKit
import SwiftTAK
import SwiftUI

struct ContactsSelectionSheet: View {
    let selectedAnnotation: MapPointAnnotation

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var takManager: TAKManager
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    @State private var selection = Set<COTData>()
    @State private var editMode: EditMode = .active
    @State private var sortTerm: String = "name"

    @FetchRequest(sortDescriptors: [], predicate: NSPredicate(format: "role != NULL"))
    private var contacts: FetchedResults<COTData>
    
    func sendPointToContacts() {
        takManager.sendPointTo(annotation: selectedAnnotation, contacts: Array(selection))
        dismiss()
    }

    var body: some View {
        NavigationView {
            Group {
                List(contacts.sorted(by: {
                    switch(sortTerm) {
                    case "battery":
                        ($0.battery < $1.battery) && ($0.callsign ?? "") < ($1.callsign ?? "")
                    case "team":
                        ($0.team ?? "") < ($1.team ?? "") && ($0.callsign ?? "") < ($1.callsign ?? "")
                    case "role":
                        ($0.role ?? "") < ($1.role ?? "") && ($0.callsign ?? "") < ($1.callsign ?? "")
                    default:
                        ($0.callsign ?? "") < ($1.callsign ?? "")
                    }
                }), id: \.self, selection: $selection) { contact in
                    HStack {
                        IconImage(annotation: MapPointAnnotation(mapPoint: contact), frameSize: 40.0)
                        Text(contact.callsign ?? "Unknown Callsign")
                        Spacer()
                    }
                }
                HStack {
                    if selection.count == 0 {
                        Text("Select the contacts to send to")
                    } else {
                        Button { sendPointToContacts() } label: {
                            Text("Send to ^[\(selection.count) contacts](inflect: true)")
                        }
                        .buttonStyle(BorderedProminentButtonStyle())
                        .disabled(selection.count == 0)
                    }
                }
                .padding()
            }
            .environment(\.editMode, $editMode)
            .navigationBarItems(leading: Menu {
                sortButton("Name", sortTermToCheck: "name")
                sortButton("Team", sortTermToCheck: "team")
                sortButton("Role", sortTermToCheck: "role")
                sortButton("Battery Life", sortTermToCheck: "battery")
            } label: { Text("Sort") }, trailing: Button("Close", action: {
                dismiss()
            }))
            .navigationTitle("Contacts")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func sortButton(_ name: String, sortTermToCheck: String) -> some View {
        Button {
            sortTerm = sortTermToCheck
        } label: {
            HStack {
                if sortTerm == sortTermToCheck {
                    Image(systemName: "checkmark")
                }
                Text(name)
            }
        }
    }
}

struct ContactsSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    @State private var sortTerm: String = "name"

    @FetchRequest(sortDescriptors: [], predicate: NSPredicate(format: "role != NULL"))
    private var contacts: FetchedResults<COTData>

    var body: some View {
        NavigationView {
            Group {
                List(contacts.sorted(by: {
                    switch(sortTerm) {
                    case "battery":
                        $0.battery < $1.battery
                    case "team":
                        ($0.team ?? "") < ($1.team ?? "")
                    case "role":
                        ($0.role ?? "") < ($1.role ?? "")
                    default:
                        ($0.callsign ?? "") < ($1.callsign ?? "")
                    }
                })) { contact in
                    HStack {
                        IconImage(annotation: MapPointAnnotation(mapPoint: contact), frameSize: 40.0)
                        Text(contact.callsign ?? "Unknown Callsign")
                        BatteryStatusIcon(battery: contact.battery)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        NotificationCenter.default.post(name: Notification.Name(AppConstants.NOTIFY_SCROLL_TO_CONTACT), object: contact.cotUid)
                    }
                }
            }
            .navigationBarItems(leading: Menu {
                sortButton("Name", sortTermToCheck: "name")
                sortButton("Team", sortTermToCheck: "team")
                sortButton("Role", sortTermToCheck: "role")
                sortButton("Battery Life", sortTermToCheck: "battery")
            } label: { Text("Sort") }, trailing: Button("Close", action: {
                dismiss()
            }))
            .navigationTitle("Contacts")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func sortButton(_ name: String, sortTermToCheck: String) -> some View {
        Button {
            sortTerm = sortTermToCheck
        } label: {
            HStack {
                if sortTerm == sortTermToCheck {
                    Image(systemName: "checkmark")
                }
                Text(name)
            }
        }
    }
}
