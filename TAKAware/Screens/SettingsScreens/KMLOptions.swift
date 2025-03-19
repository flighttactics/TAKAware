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
                            Task {
                                let didSucceed = await kmlImporter.process()
                                if didSucceed {
                                    alertText = "Overlay imported successfully!"
                                } else {
                                    alertText = "Overlay import failed"
                                }
                            }
                            fileurl.stopAccessingSecurityScopedResource()
                            isShowingAlert = true
                        } else {
                            TAKLogger.error("Unable to securely access \(String(describing: fileurl))")
                            alertText = "Overlay import failed"
                            isShowingAlert = true
                        }
                    }
                case .failure(let error):
                    TAKLogger.debug(String(describing: error))
                }
                
            })
            Section(
                header: Text("Imported Overlay Files"),
                footer: Text("Swipe a file to manage")
            ) {
                if kmlFiles.isEmpty {
                    Text("No Overlay Files Imported")
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
                            Button {
                                NotificationCenter.default.post(name: Notification.Name(AppConstants.NOTIFY_SCROLL_TO_KML), object: kmlFile.id)
                            } label: {
                                Image(systemName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                            }
                        }
                    }
                }
            }
        }
        .alert(isPresented: $isShowingAlert) {
            Alert(
                title: Text("Overlay Import"),
                message: Text(alertText),
                dismissButton: .default(Text("OK")))
        }
    }
}
