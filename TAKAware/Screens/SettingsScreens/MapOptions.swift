//
//  MapOptions.swift
//  TAKTracker
//
//  Created by Cory Foy on 9/22/23.
//

import CoreData
import Foundation
import MapKit
import SwiftUI
import UniformTypeIdentifiers

struct MapOptions: View {
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    @State var isShowingFilePicker = false
    @State var isShowingAlert = false
    @State var alertText: String = ""
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)])
    var mapSources: FetchedResults<MapSource>
    
    private static var mapSourceFetchRequest: NSFetchRequest<MapSource> {
        let fetchSource: NSFetchRequest<MapSource> = MapSource.fetchRequest()
        fetchSource.sortDescriptors = []
        fetchSource.predicate = NSPredicate(format: "visible = YES")
        return fetchSource
    }
    
    @FetchRequest(fetchRequest: mapSourceFetchRequest)
    private var visibleMapSources: FetchedResults<MapSource>
    
    let availableBaseMaps = [
        "Standard",
        "Hybrid",
        "Satellite",
        "Flyover"
    ]
    
    func updateBaseMapTo(_ baseMap: String) {
        DataController.shared.activateMapSource(name: baseMap)
    }
    
    func isCurrentBaseMap(_ baseMap: String) -> Bool {
        if !visibleMapSources.isEmpty {
            return visibleMapSources.first!.name == baseMap
        }

        var baseMapValueToTest = MKMapType.standard.rawValue
        switch baseMap {
        case "Standard":
            baseMapValueToTest = MKMapType.standard.rawValue
        case "Hybrid":
            baseMapValueToTest = MKMapType.hybrid.rawValue
        case "Satellite":
            baseMapValueToTest = MKMapType.satellite.rawValue
        case "Flyover":
            baseMapValueToTest = MKMapType.hybridFlyover.rawValue
        default:
            return false
        }
        return settingsStore.mapTypeDisplay == baseMapValueToTest
    }
    
    var availableMapSources: [String] {
        availableBaseMaps + mapSources.map { $0.name! }
    }
    
    var body: some View {
        Form {
            Group {
                Section(header: Text("Base Map")) {
                    List {
                        ForEach(availableMapSources, id:\.self) { baseMapOption in
                            HStack {
                                if(isCurrentBaseMap(baseMapOption)) {
                                    Image(systemName: "eye.fill")
                                } else {
                                    Image(systemName: "eye.slash")
                                }
                                Text(baseMapOption)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture(perform: { updateBaseMapTo(baseMapOption) })
                        }
                    }
                }
                
                Section(header: Text("Map Options"), footer: Text("May cause a map refresh when toggled")) {
                    List {
                        Toggle("Show traffic when available", isOn: $settingsStore.enableTrafficDisplay)
                        Toggle("Show Contacts as 2525 Icons", isOn: $settingsStore.enable2525ForRoles)
                        Toggle("Truncate Map Labels", isOn: $settingsStore.mapLabelShouldTruncate)
                    }
                }
                
                Section(header: Text("Custom Data")) {
                    NavigationLink(destination: IconsetOptions().environment(\.managedObjectContext, IconDataController.shared.persistentContainer.viewContext)) {
                        Text("Manage Iconsets")
                    }
                    NavigationLink(destination: MapSourceOptions()) {
                        Text("Manage Map Sources")
                    }
                    
                }
            }
        }
    }
}

struct MapSourceOptions: View {
    @State var isShowingFilePicker = false
    @State var isShowingAlert = false
    @State var alertText: String = ""
    
    @FetchRequest(sortDescriptors: [])
    var mapSources: FetchedResults<MapSource>
    
    /*
     Button {
         isShowingFilePicker.toggle()
     } label: {
         HStack {
             Text("Import an iconset")
             Spacer()
             Image(systemName: "square.and.arrow.up")
                 .multilineTextAlignment(.trailing)
         }
         
     }
     .buttonStyle(.plain)
     .contentShape(Rectangle())
     */

    var body: some View {
        List {
            Button {
                isShowingFilePicker.toggle()
            } label: {
                HStack {
                    Text("Import Map Sources")
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .multilineTextAlignment(.trailing)
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            
            Section(
                header: Text("Imported Map Sources"),
                footer: Text("Swipe a file to manage")
            ) {
                if mapSources.isEmpty {
                    Text("No Map Sources Imported")
                } else {
                    ForEach(mapSources) { mapSource in
                        HStack {
                            Image(systemName: "doc.text.fill")
                            VStack(alignment: .leading) {
                                Text(mapSource.name ?? "Unknown Name")
                                    .fontWeight(.bold)
                            }
                        }
                        .swipeActions(allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                DataController.shared.deleteMapSource(mapSource: mapSource)
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                    }
                }
            }
        }
        .fileImporter(isPresented: $isShowingFilePicker, allowedContentTypes: [.xml], allowsMultipleSelection: false, onCompletion: { results in
            switch results {
            case .success(let fileurls):
                for fileurl in fileurls {
                    if(fileurl.startAccessingSecurityScopedResource()) {
                        TAKLogger.debug("Processing file at \(String(describing: fileurl))")
                        let importer = MapSourceImporter(fileLocation: fileurl)
                        Task {
                            let importSucceeded = await importer.process()
                            if importSucceeded {
                                alertText = "Map source processed successfully!"
                            } else {
                                alertText = "Map source could not be imported"
                            }
                            fileurl.stopAccessingSecurityScopedResource()
                        }
                        isShowingAlert = true
                    } else {
                        TAKLogger.error("Unable to securely access \(String(describing: fileurl))")
                    }
                }
            case .failure(let error):
                TAKLogger.debug(String(describing: error))
            }
        })
        .alert(isPresented: $isShowingAlert) {
            Alert(
                title: Text("Map Source Import"),
                message: Text(alertText),
                dismissButton: .default(Text("OK")))
        }
    }
}

struct IconsetOptions: View {
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    @Environment(\.managedObjectContext) var dataContext
    @State var isShowingFilePicker = false
    @State var isShowingAlert = false
    @State var alertText: String = ""
    
    @FetchRequest(sortDescriptors: [])
    var localIconSets: FetchedResults<LocalIconSet>
    
    var body: some View {
        List {
            Button {
                isShowingFilePicker.toggle()
            } label: {
                HStack {
                    Text("Import an iconset")
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .multilineTextAlignment(.trailing)
                }
                
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .fileImporter(isPresented: $isShowingFilePicker, allowedContentTypes: [UTType(filenameExtension: "zip")!], allowsMultipleSelection: false, onCompletion: { results in
                
                switch results {
                case .success(let fileurls):
                    for fileurl in fileurls {
                        if(fileurl.startAccessingSecurityScopedResource()) {
                            TAKLogger.debug("Processing Iconset Zip at \(String(describing: fileurl))")
                            let iconsetImporter = IconsetImporter(iconsetPackage: fileurl)
                            Task {
                                let didSucceed = await iconsetImporter.process()
                                if didSucceed {
                                    alertText = "Iconset imported successfully!"
                                } else {
                                    alertText = "Iconset import failed"
                                }
                                fileurl.stopAccessingSecurityScopedResource()
                            }
                            isShowingAlert = true
                        } else {
                            TAKLogger.error("Unable to securely access \(String(describing: fileurl))")
                            alertText = "Iconset import failed"
                            isShowingAlert = true
                        }
                    }
                case .failure(let error):
                    TAKLogger.debug(String(describing: error))
                }
                
            })
            Section(
                header: Text("Imported Iconsets"),
                footer: Text("Swipe a file to manage")
            ) {
                if localIconSets.isEmpty {
                    Text("No Overlay Files Imported")
                } else {
                    ForEach(localIconSets, id: \.iconsetUUID) { localIconSet in
                        HStack {
                            Image(systemName: "doc.text.fill")
                            VStack(alignment: .leading) {
                                Text(localIconSet.name ?? "Unknown Name")
                                    .fontWeight(.bold)
                            }
                        }
                        .swipeActions(allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                IconDataController.shared.deleteIconset(iconSet: localIconSet)
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                    }
                }
            }
        }
        .alert(isPresented: $isShowingAlert) {
            Alert(
                title: Text("Iconset Import"),
                message: Text(alertText),
                dismissButton: .default(Text("OK")))
        }
    }
}
