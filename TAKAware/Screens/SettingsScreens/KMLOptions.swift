//
//  KMLOptions.swift
//  TAKAware
//
//  Created by Cory Foy on 12/20/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct KMLOptions: View {
    var body: some View {
        NavigationLink(destination: KMLOptionsDetail()) {
            Text("KML Overlays")
        }
    }
}

struct KMLOptionsDetail: View {
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    @State var isShowingFilePicker = false
    @State var isShowingAlert = false
    @State var alertText: String = ""
    
    @FetchRequest(sortDescriptors: [])
    var kmlFiles: FetchedResults<KMLFile>
    
    var body: some View {
        List {
            Button {
                isShowingFilePicker.toggle()
            } label: {
                HStack {
                    Text("Import a KML")
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .multilineTextAlignment(.trailing)
                }
                
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .fileImporter(isPresented: $isShowingFilePicker, allowedContentTypes: [UTType(filenameExtension: "kml")!, UTType(filenameExtension: "kmz")!], allowsMultipleSelection: false, onCompletion: { results in
                
                switch results {
                case .success(let fileurls):
                    for fileurl in fileurls {
                        if(fileurl.startAccessingSecurityScopedResource()) {
                            TAKLogger.debug("Processing KML at \(String(describing: fileurl))")
                            let kmlImporter = KMLImporter(archiveLocation: fileurl)
                            kmlImporter.process()
                            fileurl.stopAccessingSecurityScopedResource()
                            alertText = "Data package processed successfully!"
                            isShowingAlert = true
                        } else {
                            TAKLogger.error("Unable to securely access  \(String(describing: fileurl))")
                        }
                    }
                case .failure(let error):
                    TAKLogger.debug(String(describing: error))
                }
                
            })
            Section(
                header: Text("Imported KML Files"),
                footer: Text("Swipe a file to manage")
            ) {
                if kmlFiles.isEmpty {
                    Text("No KML Files Imported")
                } else {
                    ForEach(kmlFiles) { kmlFile in
                        HStack {
                            Image(systemName: "doc.text.fill")
                            VStack(alignment: .leading) {
                                Text(kmlFile.fileName ?? "Unknown Name")
                                    .fontWeight(.bold)
                            }
                        }
                        .swipeActions(allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                DataController.shared.deleteKMLFile(kmlFile: kmlFile)
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                            Button {
                                if kmlFile.visible {
                                    DataController.shared.changeKMLFileVisibility(kmlFile: kmlFile, visible: false)
                                } else {
                                    DataController.shared.changeKMLFileVisibility(kmlFile: kmlFile, visible: true)
                                }
                            } label: {
                                if kmlFile.visible {
                                    Label("Shown", systemImage: "eye.fill")
                                } else {
                                    Label("Hidden", systemImage: "eye.slash.fill")
                                }
                            }
                        }
                    }
                }
            }
        }
        .alert(isPresented: $isShowingAlert) {
            Alert(title: Text("KML Import"), message: Text(alertText), dismissButton: .default(Text("OK")))
        }
    }
}

struct DataPackageDetail2: View {
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    @StateObject var dataPackageManager: DataPackageManager = DataPackageManager()
    @State var isShowingFilePicker = false
    @State var isShowingAlert = false
    @State var alertText: String = ""
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.createdAt, order: .reverse)])
    var dataPackages: FetchedResults<DataPackage>

    var body: some View {
        List {
            NavigationLink(destination: DataPackageDownloader()) {
                Text("Download from servers")
            }
            Button {
                isShowingFilePicker.toggle()
            } label: {
                HStack {
                    Text("Import a Data Package")
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .multilineTextAlignment(.trailing)
                }
                
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .fileImporter(isPresented: $isShowingFilePicker, allowedContentTypes: [.zip], allowsMultipleSelection: false, onCompletion: { results in
                
                switch results {
                case .success(let fileurls):
                    for fileurl in fileurls {
                        if(fileurl.startAccessingSecurityScopedResource()) {
                            TAKLogger.debug("Processing Package at \(String(describing: fileurl))")
                            let tdpi = TAKDataPackageImporter(
                                fileLocation: fileurl
                            )
                            tdpi.parse()
                            fileurl.stopAccessingSecurityScopedResource()
                            if(tdpi.parsingErrors.isEmpty) {
                                alertText = "Data package processed successfully!"
                            } else {
                                alertText = "Data package could not be processed\n\n\(tdpi.parsingErrors.joined(separator: "\n\n"))"
                            }
                            isShowingAlert = true
                        } else {
                            TAKLogger.error("Unable to securely access  \(String(describing: fileurl))")
                        }
                    }
                case .failure(let error):
                    TAKLogger.debug(String(describing: error))
                }
                
            })
            Section(
                header: Text("Imported Packages"),
                footer: Text("Swipe a package to manage. Note that KML/KMZ import is not supported at this time")
            ) {
                if dataPackages.isEmpty {
                    Text("No Data Packages Imported")
                } else {
                    ForEach(dataPackages) { dataPackage in
                        NavigationLink {
                            DataPackageFilesList(dataPackage: dataPackage)
                        } label: {
                            HStack {
                                Image(systemName: "shippingbox")
                                VStack(alignment: .leading) {
                                    Text(dataPackage.name ?? "Unknown Name")
                                        .fontWeight(.bold)
                                    Text("\(dataPackage.user!), \(dataPackage.dataPackageFiles!.count) item(s)")
                                        .font(.system(size: 8))
                                }
                            }
                        }
                        .swipeActions(allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                dataPackageManager.deletePackage(dataPackage: dataPackage)
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                            Button {
                                if dataPackage.contentsVisible {
                                    dataPackageManager.hidePackage(dataPackage: dataPackage)
                                } else {
                                    dataPackageManager.showPackage(dataPackage: dataPackage)
                                }
                            } label: {
                                if dataPackage.contentsVisible {
                                    Label("Shown", systemImage: "eye.fill")
                                } else {
                                    Label("Hidden", systemImage: "eye.slash.fill")
                                }
                            }
                        }
                    }
                }
            }
        }
        .alert(isPresented: $isShowingAlert) {
            Alert(title: Text("Data Package"), message: Text(alertText), dismissButton: .default(Text("OK")))
        }
    }
}
