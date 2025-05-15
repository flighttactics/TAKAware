//
//  ServerInformation.swift
//  TAKTracker
//
//  Created by Cory Foy on 9/22/23.
//

import Foundation
import SwiftUI
import AVFoundation
import CodeScanner

struct ServerInformation: View {
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    
    var body: some View {
        Group {
            VStack {
                HStack {
                    Text("Host Name")
                        .foregroundColor(.secondary)
                    TextField("Host Name", text: $settingsStore.takServerUrl)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .onSubmit {
                            SettingsStore.global.takServerChanged = true
                        }
                }
            }
            
            VStack {
                HStack {
                    Text("Port")
                        .foregroundColor(.secondary)
                    TextField("Server Port", text: $settingsStore.takServerPort)
                        .keyboardType(.numberPad)
                        .onSubmit {
                            SettingsStore.global.takServerChanged = true
                        }
                }
            }
        }
        .multilineTextAlignment(.trailing)
    }
}

struct ServerUpdateScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    @StateObject var csrRequest: CSRRequestor = CSRRequestor()
    @State var isProcessingDataPackage: Bool = false
    
    @State var isPresentingQRScanner = false
    @State var qrCodeResult: String = ""
    @State var shouldShowQRCodeFailureAlert = false
    @State var isShowingPassword = false
    @State var isShowingAlert = false
    
    @State var formServerURL = ""
    @State var formServerPort = ""
    @State var formUsername = ""
    @State var formPassword = ""
    @State var formCSRPort = ""
    @State var formSecureAPIPort = ""
    @State var forceReenrollment = false
    
    var isAuthorized: Bool {
        get {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            
            // Determine if the user previously authorized camera access.
            var isAuthorized = status == .authorized
            
            // If the system hasn't determined the user's authorization status,
            // explicitly prompt them for approval.
            if status == .notDetermined {
                AVCaptureDevice.requestAccess(for: .video, completionHandler: { accessGranted in
                    guard accessGranted == true else { return }
                    isAuthorized = status == .authorized
                    isPresentingQRScanner = true
                })
            }
            
            return isAuthorized
        }
    }


    func setUpCaptureSession() {
        if isAuthorized {
            isPresentingQRScanner = true
        } else {
            TAKLogger.debug("[ConnectionOptions]: Camera Unauthorized")
        }
    }
    
    func processQRCode(_ scannedString: String) {
        TAKLogger.debug("[ConnectionOptions] Parsing QR code \(scannedString)")
        let response = QRCodeParser.parse(scannedString)
        if(response.wasInvalidString) {
            shouldShowQRCodeFailureAlert = true
            return
        }
        
        formServerURL = response.serverURL
        formServerPort = response.serverPort
        formUsername = response.username
        formPassword = response.password
        
        if(response.shouldAutoSubmit) {
            submitCertEnrollmentForm()
        }
    }
    
    func submitCertEnrollmentForm() {
        settingsStore.takServerUrl = formServerURL
        settingsStore.takServerPort = formServerPort
        settingsStore.takServerUsername = formUsername
        settingsStore.takServerPassword = formPassword
        settingsStore.takServerCSRPort = formCSRPort
        settingsStore.takServerSecureAPIPort = formSecureAPIPort
        if forceReenrollment {
            csrRequest.beginEnrollment()
        } else {
            settingsStore.takServerChanged = true
        }
    }
    
    var body: some View {
        VStack {
            List {
                Group {
                    Section(header:
                                Text("Server Options")
                        .font(.system(size: 14, weight: .medium))
                    ) {
                        VStack {
                            HStack {
                                Text("Host Name")
                                    .foregroundColor(.secondary)
                                TextField("Host Name", text: $formServerURL)
                                    .autocorrectionDisabled(true)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.URL)
                            }
                        }
                        VStack {
                            HStack {
                                Text("Username")
                                    .foregroundColor(.secondary)
                                TextField("Username", text: $formUsername)
                                    .autocorrectionDisabled(true)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.asciiCapable)
                            }
                        }
                        VStack {
                            HStack {
                                Text("Password")
                                    .foregroundColor(.secondary)
                                if isShowingPassword {
                                    Image(systemName: "eye")
                                        .onTapGesture {
                                            isShowingPassword.toggle()
                                        }
                                        .foregroundColor(.secondary)
                                    TextField("Password", text: $formPassword)
                                } else {
                                    Image(systemName: "eye.slash")
                                        .onTapGesture {
                                            isShowingPassword.toggle()
                                        }
                                        .foregroundColor(.secondary)
                                    SecureField("Password", text: $formPassword)
                                }
                                
                            }
                        }
                        VStack {
                            HStack {
                                Text("Server Enabled")
                                    .foregroundColor(.secondary)
                                Toggle("", isOn: $settingsStore.takServerEnabled)
                            }
                        }
                    }
                    
                    Section(header:
                                Text("Advanced Options")
                                .font(.system(size: 14, weight: .medium))
                    ) {
                        VStack {
                            HStack {
                                Text("Port")
                                    .foregroundColor(.secondary)
                                TextField("Server Port", text: $formServerPort)
                                    .keyboardType(.numberPad)
                            }
                        }
                        
                        VStack {
                            HStack {
                                Text("Cert Enroll Port")
                                    .foregroundColor(.secondary)
                                TextField("Cert Enroll Port", text: $formCSRPort)
                                    .keyboardType(.numberPad)
                            }
                        }
                        
                        VStack {
                            HStack {
                                Text("Secure API Port")
                                    .foregroundColor(.secondary)
                                TextField("Secure API Port", text: $formSecureAPIPort)
                                    .keyboardType(.numberPad)
                            }
                        }
                        
                        VStack {
                            HStack {
                                Text("Reenroll Cert")
                                    .foregroundColor(.secondary)
                                Toggle("", isOn: $forceReenrollment)
                            }
                        }
                    }
                }
                .multilineTextAlignment(.trailing)
            }
            
            VStack(alignment: .center) {
                HStack {
                    if(csrRequest.enrollmentStatus == .Succeeded) {
                        Button("Close", role: .none) {
                            isProcessingDataPackage = false
                            dismiss()
                        }
                    } else {
                        Button("Delete Connection", role: .destructive) {
                            SettingsStore.global.clearConnection()
                            isShowingAlert = true
                        }
                        Button("Update Server", role: .none) {
                            submitCertEnrollmentForm()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Text("Status: " + csrRequest.enrollmentStatus.description)
                Text("For Server \(SettingsStore.global.takServerUrl)")
            }
            .sheet(isPresented: $isPresentingQRScanner, onDismiss: {
                processQRCode(qrCodeResult)
            }) {
                NavigationView {
                    Group {
                        if isAuthorized {
                            CodeScannerView(
                                codeTypes: [.qr],
                                showViewfinder: true,
                                simulatedData: "MyTAK,tak.example.com,8089,SSL",
                                shouldVibrateOnSuccess: true,
                                videoCaptureDevice: AVCaptureDevice.zoomedCameraForQRCode()
                            ) { response in
                                if case let .success(result) = response {
                                    qrCodeResult = result.string
                                    isPresentingQRScanner = false
                                }
                            }
                        } else {
                            VStack(alignment: .center) {
                                Text("Camera access has been disabled. Please enable in settings.")
                            }
                                
                        }
                    }
                    .toolbar {
                        ToolbarItem {
                            Button("Cancel", action: { dismiss() })
                        }
                    }
                }
            }
            .alert(isPresented: $shouldShowQRCodeFailureAlert) {
                Alert(title: Text("QR Code Failure"), message: Text("The QR Code you scanned did not contain connection information. Please try a different QR code"), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $isShowingAlert) {
                Alert(title: Text("Server Connection"), message: Text("The TAK Server Connection has been removed"), dismissButton: .default(Text("OK"), action: {
                    dismiss()
                }))
            }
        }
        .onAppear(perform: {
            if(!isProcessingDataPackage) { isProcessingDataPackage = true }
            formServerURL = settingsStore.takServerUrl
            formServerPort = settingsStore.takServerPort
            formUsername = settingsStore.takServerUsername
            formPassword = settingsStore.takServerPassword
            formCSRPort = settingsStore.takServerCSRPort
            formSecureAPIPort = settingsStore.takServerSecureAPIPort
        })
    }
}

struct ServerInformationDisplay: View {
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    @State var isShowingAlert = false
    @State var isShowingEditBox = false
    @State var currentServerUrl: String = SettingsStore.global.takServerUrl
    @State var currentServerPort: String = SettingsStore.global.takServerPort
    
    var body: some View {
        Group {
            VStack {
                NavigationLink(destination: ServerUpdateScreen()) {
                    HStack {
                        Text(settingsStore.takServerUrl)
                    }
                }
            }
        }
    }
    
    func updateServer() {
        var didUpdate = false
        if !currentServerUrl.isEmpty {
            didUpdate = true
            settingsStore.takServerUrl = currentServerUrl
        }
        if !currentServerPort.isEmpty {
            didUpdate = true
            settingsStore.takServerPort = currentServerPort
        }
        settingsStore.takServerChanged = didUpdate
    }
}
