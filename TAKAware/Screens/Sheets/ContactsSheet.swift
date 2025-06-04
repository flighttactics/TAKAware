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

struct ContactsSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var settingsStore: SettingsStore = SettingsStore.global

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \COTData.callsign, ascending: true)], predicate: NSPredicate(format: "role != NULL"))
    private var contacts: FetchedResults<COTData>

    var body: some View {
        NavigationView {
            List(contacts) { contact in
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
            .navigationBarItems(leading: Menu {
                Button {
                    contacts.nsSortDescriptors = [NSSortDescriptor(keyPath: \COTData.callsign, ascending: true)]
                } label: {
                    Text("Name")
                }
                Button {
                    contacts.nsSortDescriptors = [NSSortDescriptor(keyPath: \COTData.team, ascending: true)]
                } label: {
                    Text("Team")
                }
                Button {
                    contacts.nsSortDescriptors = [NSSortDescriptor(keyPath: \COTData.role, ascending: true)]
                } label: {
                    Text("Role")
                }
                Button {
                    contacts.nsSortDescriptors = [NSSortDescriptor(keyPath: \COTData.battery, ascending: true)]
                } label: {
                    Text("Battery Life")
                }
            } label: { Text("Sort") }, trailing: Button("Close", action: {
                dismiss()
            }))
            .navigationTitle("Contacts")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
