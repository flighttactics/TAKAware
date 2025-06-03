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
    @StateObject var channelManager: ChannelManager = ChannelManager()
    @State var channelState = true
    
    private static var contactsFetchRequest: NSFetchRequest<COTData> {
        let fetchUser: NSFetchRequest<COTData> = COTData.fetchRequest()
        fetchUser.predicate = NSPredicate(format: "role != NULL")
        fetchUser.sortDescriptors = [NSSortDescriptor(keyPath: \COTData.callsign, ascending: true)]
        return fetchUser
    }
    
    @FetchRequest(fetchRequest: contactsFetchRequest)
    private var contacts: FetchedResults<COTData>

    var body: some View {
        NavigationView {
            List(contacts) { contact in
                HStack {
                    Text(contact.callsign ?? "Unknown Callsign")
                    BatteryStatusIcon(battery: contact.battery)
                    Spacer()
                    Button {
                        NotificationCenter.default.post(name: Notification.Name(AppConstants.NOTIFY_SCROLL_TO_COORDINATE), object: CLLocationCoordinate2D(latitude: contact.latitude, longitude: contact.longitude))
                    } label: {
                        Image(systemName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                    }
                }
            }
            .navigationBarItems(trailing: Button("Close", action: {
                dismiss()
            }))
            .navigationTitle("Contacts")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
