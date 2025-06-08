//
//  OverlayManager.swift
//  TAKAware
//
//  Created by Cory Foy on 6/8/25.
//

import CoreData
import SwiftTAK
import SwiftUI

struct OverlayManagerOptions: View {
    var body: some View {
        NavigationLink(destination: OverlayManagerScreen()) {
            Text("Overlay Manager")
        }
    }
}

struct OverlayManagerSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            OverlayManagerScreen()
            .navigationTitle("Overlay Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct OverlayManagerRow: View {
    var title: String
    var iconName: String
    var subtitleName: String
    var subtitleCount: Int

    var body: some View {
        HStack {
            Image(systemName: "eye.fill")
            ResizedImage(name: "om_\(iconName)")
            VStack(alignment: .leading) {
                Text(title)
                Text("^[\(subtitleCount) \(subtitleName)](inflect: true)")
                    .font(.system(size: 8.0))
            }
        }
    }
}

struct OverlayManagerScreen: View {
    @State var count1 = 5
    @State var count2 = 1
    @State var count3 = 0
    
    @FetchRequest(sortDescriptors: [], predicate: NSPredicate(format: "role != NULL"))
    private var contacts: FetchedResults<COTData>
    
    @FetchRequest(sortDescriptors: [], predicate: NSPredicate(format: "isAlert = YES"))
    private var contactAlerts: FetchedResults<COTData>
    
    @FetchRequest(sortDescriptors: [], predicate: NSPredicate(format: "NOT cotType IN %@", COTMapObject.OVERLAY_TYPES))
    private var markers: FetchedResults<COTData>
    
    @FetchRequest(sortDescriptors: [], predicate: NSPredicate(format: "cotType IN %@", COTMapObject.OVERLAY_TYPES))
    private var shapes: FetchedResults<COTData>
    
    @FetchRequest(sortDescriptors: [], predicate: NSPredicate(format: "videoURL != NULL"))
    private var videos: FetchedResults<COTData>
    
    @FetchRequest(sortDescriptors: [])
    private var dataPackages: FetchedResults<DataPackage>
    
    @FetchRequest(sortDescriptors: [])
    private var dataSyncMissions: FetchedResults<DataSyncMission>
    
    @FetchRequest(sortDescriptors: [])
    private var kmlOverlays: FetchedResults<KMLFile>
    
    var body: some View {
        List {
            NavigationLink {
                ContactsDetail()
            } label: {
                OverlayManagerRow(title: "Team", iconName: "team", subtitleName: "item", subtitleCount: contacts.count)
            }
            NavigationLink {
                MarkersDetail()
            } label: {
                OverlayManagerRow(title: "Markers", iconName: "markers", subtitleName: "item", subtitleCount: markers.count)
            }
            NavigationLink {
                DataPackageDetail()
            } label: {
                OverlayManagerRow(title: "Data Packages", iconName: "data_packages", subtitleName: "item", subtitleCount: dataPackages.count)
            }
            NavigationLink {
                ShapesDetail()
            } label: {
                OverlayManagerRow(title: "Shapes", iconName: "shapes", subtitleName: "item", subtitleCount: shapes.count)
            }
            NavigationLink {
                VideoList()
            } label: {
                OverlayManagerRow(title: "Video", iconName: "video", subtitleName: "item", subtitleCount: videos.count)
            }
            NavigationLink {
                DataSyncMissionDetail()
            } label: {
                OverlayManagerRow(title: "Feeds", iconName: "feeds", subtitleName: "feed", subtitleCount: dataSyncMissions.count)
            }
            NavigationLink {
                KMLOptionsDetail()
            } label: {
                OverlayManagerRow(title: "Image Overlay", iconName: "image_overlay", subtitleName: "item", subtitleCount: kmlOverlays.count)
            }
            NavigationLink {
                AlertsDetail()
            } label: {
                OverlayManagerRow(title: "Alerts", iconName: "alert", subtitleName: "alert", subtitleCount: contactAlerts.count)
            }
            NavigationLink {
                ChannelOptionsDetail()
            } label: {
                OverlayManagerRow(title: "Channels", iconName: "channels", subtitleName: "server", subtitleCount: 1)
            }
            // OverlayManagerRow(title: "Attachments", iconName: "attachments", subtitleName: "item", subtitleCount: count1)
            // OverlayManagerRow(title: "Navigation", iconName: "navigation", subtitleName: "item", subtitleCount: count1)
            
        }
        .navigationTitle("Overlay Manager")
    }
}
