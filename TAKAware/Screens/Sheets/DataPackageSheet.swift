//
//  DataPackageSheet.swift
//  TAKAware
//
//  Created by Cory Foy on 11/26/24.
//

import Foundation
import SwiftTAK
import SwiftUI

struct DataPackageDownloader: View {
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    @StateObject var dataPackageManager: DataPackageManager = DataPackageManager()
    @State private var isRotating = 0.0
    @State var isShowingAlert = false
    @State var alertText: String = ""
    @FetchRequest(sortDescriptors: [SortDescriptor(\.createdAt, order: .reverse)])
    var dataPackages: FetchedResults<DataPackage>
    
    var loader: some View {
        return Image(systemName: "arrowshape.turn.up.right.circle")
            .rotationEffect(.degrees(isRotating))
            .onAppear {
                withAnimation(.linear(duration: 1)
                        .speed(0.4).repeatForever(autoreverses: false)) {
                    isRotating = 360.0
                }
            }
    }
    
    var body: some View {
        List {
            if dataPackageManager.isLoading {
                loader
            } else {
                ForEach(dataPackageManager.dataPackages, id:\.hash) { package in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(package.name)
                            Text("\(package.size)")
                                .font(.system(size: 10))
                        }
                        Spacer()
                        Button {
                            // On press, download the archive to the file system
                            // Then start the data package importer pointed to the file
                            dataPackageManager.importRemotePackage(missionPackage: package)
                        } label: {
                            if(dataPackages.contains(where: { $0.originalFileHash == package.hash })) {
                                Image(systemName: "checkmark.circle.fill")
                            } else {
                                Image(systemName: "square.and.arrow.down")
                            }
                        }
                        
                    }
                }
            }
        }
        .onAppear {
            dataPackageManager.retrieveDataPackages()
        }
        .alert(isPresented: $dataPackageManager.isFinishedProcessingRemotePackage) {
            Alert(title: Text("Data Package"), message: Text(dataPackageManager.remotePackageProcessStatus), dismissButton: .default(Text("OK")))
        }
    }
}

struct DataPackageFilesList: View {
    @StateObject var dataPackageManager: DataPackageManager = DataPackageManager()
    var dataPackage: DataPackage
    var dataPackageFiles: [DataPackageFile] {
        dataPackage.dataPackageFiles?.allObjects as! [DataPackageFile]
    }
    
    func fileName(dataPackageFile: DataPackageFile) -> String {
        dataPackageFile.cotData?.callsign ??
            String(dataPackageFile.zipEntry?.split(separator: "/").last ?? "No Name")
    }

    var body: some View {
        List {
            Section(header: Text("Files for \(dataPackage.name ?? "Unknown Data Package")")) {
                if dataPackageFiles.isEmpty {
                    Text("No Data Package Files")
                } else {
                    ForEach(dataPackageFiles) { dataPackageFile in
                        HStack {
                            Text(
                                fileName(dataPackageFile: dataPackageFile)
                            )
                            Spacer()
                            Image(systemName: (dataPackageFile.isCoT ? "target" : "doc"))
                        }
                    }
                }
            }
        }
    }
}

struct DataPackageSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    @StateObject var dataPackageManager: DataPackageManager = DataPackageManager()
    @State var isShowingFilePicker = false
    @State var isShowingAlert = false
    @State var alertText: String = ""
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.createdAt, order: .reverse)])
    var dataPackages: FetchedResults<DataPackage>

    var body: some View {
        NavigationStack {
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
                Section(header: Text("Imported Packages")) {
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
                            }
                        }
                    }
                }
            }
            .alert(isPresented: $isShowingAlert) {
                Alert(title: Text("Data Package"), message: Text(alertText), dismissButton: .default(Text("OK")))
            }
            .navigationTitle("Data Packages")
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