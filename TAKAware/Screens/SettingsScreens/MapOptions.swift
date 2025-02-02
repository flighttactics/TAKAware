//
//  MapOptions.swift
//  TAKTracker
//
//  Created by Cory Foy on 9/22/23.
//

import Foundation
import MapKit
import SwiftUI

struct MapOptions: View {
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    @State var isShowingFilePicker = false
    
    let availableBaseMaps = [
        "Standard",
        "Hybrid",
        "Satellite",
        "Flyover"
    ]
    
    func updateBaseMapTo(_ baseMap: String) {
        switch baseMap {
        case "Standard":
            settingsStore.mapTypeDisplay = MKMapType.standard.rawValue
        case "Hybrid":
            settingsStore.mapTypeDisplay = MKMapType.hybrid.rawValue
        case "Satellite":
            settingsStore.mapTypeDisplay = MKMapType.satellite.rawValue
        case "Flyover":
            settingsStore.mapTypeDisplay = MKMapType.hybridFlyover.rawValue
        default:
            settingsStore.mapTypeDisplay = MKMapType.standard.rawValue
        }
    }
    
    func isCurrentBaseMap(_ baseMap: String) -> Bool {
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
            baseMapValueToTest = MKMapType.standard.rawValue
        }
        return settingsStore.mapTypeDisplay == baseMapValueToTest
    }
    
    var body: some View {
        Form {
            Group {
                Section(header: Text("Base Map")) {
                    List {
                        ForEach(availableBaseMaps, id:\.self) { baseMapOption in
                            Button {
                                updateBaseMapTo(baseMapOption)
                            } label: {
                                HStack {
                                    if(isCurrentBaseMap(baseMapOption)) {
                                        Image(systemName: "eye.fill")
                                    } else {
                                        Image(systemName: "eye.slash")
                                    }
                                    Text(baseMapOption)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Traffic Display")) {
                    List {
                        Toggle("Show traffic when available", isOn: $settingsStore.enableTrafficDisplay)
                    }
                }
                
                Section(header: Text("Contact Icons"), footer: Text("Will cause a map refresh when toggled")) {
                    List {
                        Toggle("Show Contacts as 2525 Icons", isOn: $settingsStore.enable2525ForRoles)
                    }
                }
                
//                Section(header:
//                    HStack {
//                        Text("Custom Map Overlays")
//                        Spacer()
//                    Button(action: { isShowingFilePicker.toggle() }, label: {
//                        Image(systemName: "plus")
//                            .font(.title)
//                    }).buttonStyle(.plain)
//                    }
//                ) {
//                    Text("No Custom Maps Loaded")
//                }
//                .fileImporter(isPresented: $isShowingFilePicker, allowedContentTypes: [.zip, .xml], allowsMultipleSelection: false, onCompletion: { results in
//                    switch results {
//                    case .success(let fileurls):
//                        for fileurl in fileurls {
//                            if(fileurl.startAccessingSecurityScopedResource()) {
//                                TAKLogger.debug("Processing file at \(String(describing: fileurl))")
//    //                                    let tdpi = TAKDataPackageImporter(
//    //                                        fileLocation: fileurl
//    //                                    )
//    //                                    tdpi.parse()
//    //                                    fileurl.stopAccessingSecurityScopedResource()
//    //                                    if(tdpi.parsingErrors.isEmpty) {
//    //                                        alertText = "Data package processed successfully!"
//    //                                    } else {
//    //                                        alertText = "Data package could not be processed\n\n\(tdpi.parsingErrors.joined(separator: "\n\n"))"
//    //                                    }
//    //                                    isShowingAlert = true
//                            } else {
//                                TAKLogger.error("Unable to securely access  \(String(describing: fileurl))")
//                            }
//                        }
//                    case .failure(let error):
//                        TAKLogger.debug(String(describing: error))
//                    }
//                })
            }
        }
    }
}
