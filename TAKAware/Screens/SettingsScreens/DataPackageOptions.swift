//
//  DataPackageOptions.swift
//  TAKAware
//
//  Created by Cory Foy on 11/15/24.
//

import Foundation
import MapKit
import SwiftUI

struct DataPackageOptionsDetail: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    @State private var isRotating = 0.0
    @State var isShowingFilePicker = false
    @State var isShowingAlert = false
    @State var alertText: String = ""
    
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
}

struct DataPackageOptions: View {
    var body: some View {
        NavigationLink(destination: DataPackageOptionsDetail()) {
            Text("Data Packages")
        }
    }
}
