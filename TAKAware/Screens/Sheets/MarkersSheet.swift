//
//  MarkersSheet.swift
//  TAKAware
//
//  Created by Cory Foy on 6/8/25.
//

import CoreData
import MapKit
import SwiftUI

struct MarkersDetail: View {
    @FetchRequest(sortDescriptors: [], predicate: NSPredicate(format: "role == NULL AND NOT cotType IN %@ AND (icon == NULL OR icon == '')", COTMapObject.OVERLAY_TYPES))
    private var markers: FetchedResults<COTData>
    
    @FetchRequest(sortDescriptors: [], predicate: NSPredicate(format: "role == NULL AND NOT cotType IN %@ AND icon != NULL AND icon != ''", COTMapObject.OVERLAY_TYPES))
    private var icons: FetchedResults<COTData>
    
    var body: some View {
        List {
            NavigationLink {
                MarkersWithoutIconsDetail()
            } label: {
                HStack {
                    ResizedImage(name: "om_markers")
                    VStack(alignment: .leading) {
                        Text("Markers")
                        Text("^[\(markers.count) items](inflect: true)")
                            .font(.system(size: 8.0))
                    }
                }
            }
            NavigationLink {
                MarkersWithIconsDetail()
            } label: {
                HStack {
                    ResizedImage(name: "om_icons")
                    VStack(alignment: .leading) {
                        Text("Icons")
                        Text("^[\(markers.count) items](inflect: true)")
                            .font(.system(size: 8.0))
                    }
                }
            }
        }
    }
}

struct MarkersWithoutIconsDetail: View {
    @SectionedFetchRequest(
      entity: COTData.entity(),
      sectionIdentifier: \.baseCotType,
      sortDescriptors: [
        NSSortDescriptor(SortDescriptor(\COTData.cotType, comparator: .localizedStandard))
      ],
      predicate: NSPredicate(format: "role == NULL AND NOT cotType IN %@ AND (icon == NULL OR icon == '')", COTMapObject.OVERLAY_TYPES)
    ) var markers: SectionedFetchResults<String?, COTData>
    
    var body: some View {
        List {
            ForEach(markers) { section in
                Section(header: Text(section.id!)) {
                    ForEach(section.sorted(by: { ($0.callsign ?? "") < ($1.callsign ?? "") })) { marker in
                        HStack {
                            IconImage(annotation: MapPointAnnotation(mapPoint: marker))
                            Text(marker.callsign ?? "Unknown Marker")
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            NotificationCenter.default.post(name: Notification.Name(AppConstants.NOTIFY_SCROLL_TO_CONTACT), object: marker.cotUid)
                        }
                    }
                }
            }
        }
    }
}

struct MarkersWithIconsDetail: View {
    @SectionedFetchRequest(
      entity: COTData.entity(),
      sectionIdentifier: \.icon,
      sortDescriptors: [
        NSSortDescriptor(SortDescriptor(\COTData.icon, comparator: .localizedStandard))
      ],
      predicate: NSPredicate(format: "role == NULL AND NOT cotType IN %@ AND icon != NULL AND icon != ''", COTMapObject.OVERLAY_TYPES)
    ) var markers: SectionedFetchResults<String?, COTData>
    
    var body: some View {
        List {
            ForEach(markers) { section in
                NavigationLink {
                    List {
                        ForEach(section.sorted(by: { ($0.callsign ?? "") < ($1.callsign ?? "") })) { marker in
                            HStack {
                                IconImage(annotation: MapPointAnnotation(mapPoint: marker))
                                Text(marker.callsign ?? "Unknown Marker")
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                NotificationCenter.default.post(name: Notification.Name(AppConstants.NOTIFY_SCROLL_TO_CONTACT), object: marker.cotUid)
                            }
                        }
                    }
                } label: {
                    HStack {
                        IconImage(iconPath: section.id!)
                        Text("^[\(section.count) items](inflect: true)")
                    }
                }
            }
        }
    }
}

struct ShapesDetail: View {
    @FetchRequest(sortDescriptors: [], predicate: NSPredicate(format: "cotType IN %@", COTMapObject.OVERLAY_TYPES))
    private var allShapes: FetchedResults<COTData>
    
    
    @SectionedFetchRequest(
      entity: COTData.entity(),
      sectionIdentifier: \.cotType,
      sortDescriptors: [],
      predicate: NSPredicate(format: "cotType IN %@", COTMapObject.OVERLAY_TYPES)
    ) var shapes: SectionedFetchResults<String?, COTData>
    
    var body: some View {
        List {
            ForEach(shapes) { section in
                Section(header: Text(COTMapObject.typeToDescriptor(section.id!))) {
                    ForEach(section) { shape in
                        HStack {
                            Text(shape.callsign ?? "Shape")
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            NotificationCenter.default.post(name: Notification.Name(AppConstants.NOTIFY_SCROLL_TO_CONTACT), object: shape.cotUid)
                        }
                    }
                }
            }
        }
    }
}
