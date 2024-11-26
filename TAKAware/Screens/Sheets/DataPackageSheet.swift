//
//  DataPackageSheet.swift
//  TAKAware
//
//  Created by Cory Foy on 11/26/24.
//

import Foundation
import SwiftTAK
import SwiftUI

struct DataPackageSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    @State private var isRotating = 0.0
    @State var isShowingFilePicker = false
    @State var isShowingAlert = false
    @State var alertText: String = ""
    var dataContext = DataController.shared.backgroundContext
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.createdAt, order: .reverse)])
    var dataPackages: FetchedResults<DataPackage>
    
    var loader: some View {
        return Image(systemName: "arrowshape.turn.up.right.circle")
            .rotationEffect(.degrees(isRotating))
            .onAppear {
                withAnimation(.linear(duration: 1)
                        .speed(0.1).repeatForever(autoreverses: false)) {
                    isRotating = 360.0
                }
            }
    }

    var body: some View {
        NavigationView {
            List {
                VStack(alignment: .center) {
                    HStack {
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
                                TAKLogger.debug("**SUCCESS")
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
                    }
                    ForEach(dataPackages) { dataPackage in
                        VStack {
                            HStack {
                                Image(systemName: "eye.fill")
                                Image(systemName: "shippingbox")
                                VStack(alignment: .leading) {
                                    Text(dataPackage.name ?? "Unknown Name")
                                        .fontWeight(.bold)
                                    Text("\(SettingsStore.global.callSign), 9 items")
                                }
                                Spacer()
                                Image(systemName: "arrow.up.square.fill")
                                Image(systemName: "trash.square")
                            }
                        }
                        .padding(.top, 20)
                    }
                }
                .alert(isPresented: $isShowingAlert) {
                    Alert(title: Text("Data Package"), message: Text(alertText), dismissButton: .default(Text("OK")))
                }
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
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
