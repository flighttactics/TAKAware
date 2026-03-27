//
//  ConnectionOptions.swift
//  TAKTracker
//
//  Created by Cory Foy on 9/22/23.
//

import CodeScanner
import Foundation
import SwiftTAK
import SwiftUI
import AVFoundation

func didDismissCertEnrollment() {
    // Clean up the variables
    let settingsStore = SettingsStore.global
    settingsStore.serverCertificate = Data()
    settingsStore.serverCertificatePassword = ""
    settingsStore.takServerPassword = ""
    settingsStore.takServerUsername = ""
}

struct DataPackageEnrollment: View {
    @Binding var isProcessingDataPackage: Bool
    @StateObject var settingsStore: SettingsStore = SettingsStore.global

    @State var isShowingFilePicker = false
    @State var isShowingAlert = false
    @State var alertText: String = ""
    
    var body: some View {
        Group {
            VStack(alignment: .center) {
                HStack {
                    Button {
                        isShowingFilePicker.toggle()
                    } label: {
                        HStack {
                            Text("Connect with a Data Package")
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .multilineTextAlignment(.trailing)
                        }
                        .contentShape(Rectangle())
                        
                    }
                    .buttonStyle(.plain)
                    .fileImporter(isPresented: $isShowingFilePicker, allowedContentTypes: [.zip], allowsMultipleSelection: false, onCompletion: { results in
                        switch results {
                        case .success(let fileurls):
                            isProcessingDataPackage = true
                            for fileurl in fileurls {
                                if(fileurl.startAccessingSecurityScopedResource()) {
                                    TAKLogger.debug("Processing Package at \(String(describing: fileurl))")
                                    let tdpp = TAKDataPackageParser(
                                        fileLocation: fileurl
                                    )
                                    tdpp.parse()
                                    fileurl.stopAccessingSecurityScopedResource()
                                    isProcessingDataPackage = false
                                    if(tdpp.parsingErrors.isEmpty) {
                                        alertText = "Data package processed successfully!"
                                    } else {
                                        alertText = "Data package could not be processed\n\n\(tdpp.parsingErrors.joined(separator: "\n\n"))"
                                    }
                                    isShowingAlert = true
                                } else {
                                    TAKLogger.error("Unable to securely access  \(String(describing: fileurl))")
                                }
                            }
                            isProcessingDataPackage = false
                        case .failure(let error):
                            isProcessingDataPackage = false
                            TAKLogger.debug(String(describing: error))
                        }
                        
                    })
                }
            }
        }
        .alert(isPresented: $isShowingAlert) {
            Alert(title: Text("Data Package"), message: Text(alertText), dismissButton: .default(Text("OK")))
        }
    }
}

struct ConnectionOptions: View {
    @Binding var isProcessingDataPackage: Bool
    @ObservedObject var settingsStore = SettingsStore.global
    
    var body: some View {
        Group {
            if(!isProcessingDataPackage && settingsStore.takServerUrl != "") {
                ServerInformationDisplay()
            } else {
                NavigationLink(destination: ConnectionOptionsScreen(isProcessingDataPackage: $isProcessingDataPackage)) {
                    Text("Connect to a TAK Server")
                }
            }
        }
        .onAppear {
            isProcessingDataPackage = false
        }
    }
}

struct ConnectionOptionsScreen: View {
    @Binding var isProcessingDataPackage: Bool
    
    @State var isShowingFilePicker = false
    @State var isShowingAlert = false
    @State var alertText: String = ""

    var body: some View {
        VStack {
            Text("Choose a connection method:")
            Group {
                NavigationLink(destination: CertEnrollmentScreen(isProcessingDataPackage: $isProcessingDataPackage)) {
                    Text("Certificate Enrollment")
                }
                
                NavigationLink(destination: CertEnrollmentScreen(
                    isProcessingDataPackage: $isProcessingDataPackage,
                    isPresentingQRScanner: true
                )) {
                    Text("Scan QR code")
                }

                Button {
                    isShowingFilePicker.toggle()
                } label: {
                    Text("Upload a Data Package")
                }
                .fileImporter(isPresented: $isShowingFilePicker, allowedContentTypes: [.zip], allowsMultipleSelection: false, onCompletion: { results in
                    switch results {
                    case .success(let fileurls):
                        isProcessingDataPackage = true
                        for fileurl in fileurls {
                            if(fileurl.startAccessingSecurityScopedResource()) {
                                TAKLogger.debug("Processing Package at \(String(describing: fileurl))")
                                let tdpp = TAKDataPackageParser(
                                    fileLocation: fileurl
                                )
                                tdpp.parse()
                                fileurl.stopAccessingSecurityScopedResource()
                                isProcessingDataPackage = false
                                if(tdpp.parsingErrors.isEmpty) {
                                    alertText = "Data package processed successfully!"
                                } else {
                                    alertText = "Data package could not be processed\n\n\(tdpp.parsingErrors.joined(separator: "\n\n"))"
                                }
                                isShowingAlert = true
                            } else {
                                TAKLogger.error("Unable to securely access  \(String(describing: fileurl))")
                            }
                        }
                        isProcessingDataPackage = false
                    case .failure(let error):
                        isProcessingDataPackage = false
                        TAKLogger.debug(String(describing: error))
                    }
                })
            }
            .buttonStyle(.borderedProminent)
        }
        .alert(isPresented: $isShowingAlert) {
            Alert(title: Text("Data Package"), message: Text(alertText), dismissButton: .default(Text("OK")))
        }
    }
}

struct CertEnrollmentScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var settingsStore: SettingsStore = SettingsStore.global
    @StateObject var csrRequest: CSRRequestor = CSRRequestor()
    @Binding var isProcessingDataPackage: Bool
    
    @State var isPresentingQRScanner = false
    @State var qrCodeResult: String = ""
    @State var shouldShowQRCodeFailureAlert = false
    @State var qrCodeFailureMessage: String = "The QR Code you scanned did not contain connection information. Please try a different QR code"
    @State var isShowingPassword = false
    
    @State var formServerURL = ""
    @State var formServerPort = ""
    @State var formUsername = ""
    @State var formPassword = ""
    @State var formCSRPort = ""
    @State var formSecureAPIPort = ""
    
    // CloudTAK import state
    @State var isShowingHostConfirmation = false
    @State var cloudTAKURL: URL? = nil
    @State var cloudTAKPassword: String? = nil
    @State var isShowingPasswordPrompt = false
    @State var p12PasswordInput = ""
    @State var downloadedZipURL: URL? = nil
    @StateObject var downloader = CloudTAKDownloader()
    @State var isDownloading = false
    @State var importStatusMessage = ""
    @State var isShowingCloudTAKAlert = false
    @State var cloudTAKAlertTitle = ""
    @State var cloudTAKAlertMessage = ""
    @State var cloudTAKImportSucceeded = false
    
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
        TAKLogger.debug("[ConnectionOptions] Parsing QR code")
        let result = QRCodeParser.parseExtended(scannedString)
        
        switch result {
        case .certificateEnrollment(let response):
            if response.wasInvalidString {
                qrCodeFailureMessage = "The QR Code you scanned did not contain connection information. Please try a different QR code"
                shouldShowQRCodeFailureAlert = true
                return
            }
            formServerURL = response.serverURL
            formServerPort = response.serverPort
            formUsername = response.username
            formPassword = response.password
            if response.shouldAutoSubmit {
                submitCertEnrollmentForm()
            }
            
        case .cloudTAKURL(let url, let password):
            cloudTAKURL = url
            cloudTAKPassword = password
            isShowingHostConfirmation = true
            
        case .invalid(let message):
            qrCodeFailureMessage = message
            shouldShowQRCodeFailureAlert = true
        }
    }
    
    func startCloudTAKDownload() {
        guard let url = cloudTAKURL else { return }
        guard !isDownloading else { return }
        isDownloading = true
        importStatusMessage = "Downloading configuration..."
        
        Task {
            do {
                // Simple async download
                let (tempURL, response) = try await URLSession.shared.download(from: url)
                
                // IMPORTANT: URLSession temp file is deleted after this scope.
                // Copy it to our own temp location before it disappears.
                let destDir = (NSTemporaryDirectory() as NSString).appendingPathComponent("com.takaware.pkg-import")
                try? FileManager.default.createDirectory(atPath: destDir, withIntermediateDirectories: true)
                let destPath = (destDir as NSString).appendingPathComponent(UUID().uuidString + ".zip")
                let destURL = URL(fileURLWithPath: destPath)
                try FileManager.default.copyItem(at: tempURL, to: destURL)
                
                // Check HTTP status
                if let httpResponse = response as? HTTPURLResponse,
                   !(200...299).contains(httpResponse.statusCode) {
                    try? FileManager.default.removeItem(at: destURL)
                    throw NSError(domain: "CloudTAK", code: httpResponse.statusCode,
                                  userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
                }
                
                TAKLogger.debug("[CertEnrollment] Downloaded to: \(destURL)")
                
                // Parse on background thread
                let tdpp = TAKDataPackageParser(fileLocation: destURL)
                let errors: [String] = await withCheckedContinuation { continuation in
                    DispatchQueue.global(qos: .userInitiated).async {
                        tdpp.parse()
                        Thread.sleep(forTimeInterval: 1.0)
                        continuation.resume(returning: tdpp.parsingErrors)
                    }
                }
                
                // Clean up temp file
                try? FileManager.default.removeItem(at: destURL)
                
                await MainActor.run {
                    isDownloading = false
                    importStatusMessage = ""
                    if errors.isEmpty {
                        cloudTAKImportSucceeded = true
                        cloudTAKAlertTitle = "Success"
                        cloudTAKAlertMessage = "Configuration imported. Server connection will be established."
                    } else {
                        cloudTAKAlertTitle = "Import Result"
                        cloudTAKAlertMessage = errors.joined(separator: "\n")
                    }
                    isShowingCloudTAKAlert = true
                }
            } catch {
                TAKLogger.error("[CertEnrollment] Error: \(error)")
                await MainActor.run {
                    isDownloading = false
                    importStatusMessage = ""
                    cloudTAKAlertTitle = "Error"
                    cloudTAKAlertMessage = error.localizedDescription
                    isShowingCloudTAKAlert = true
                }
            }
        }
    }
    
    /// Try standard parse — password is in the .pref file inside the zip.
    /// Runs off the main thread to avoid watchdog kill during zip extraction.
    func importStandardAsync(zipURL: URL) async {
        let tdpp = TAKDataPackageParser(fileLocation: zipURL)
        
        // Run zip extraction + cert import on background thread
        let errors: [String] = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                tdpp.parse()
                // Wait briefly for the async storeUserCertificate to complete
                Thread.sleep(forTimeInterval: 1.0)
                continuation.resume(returning: tdpp.parsingErrors)
            }
        }
        
        await MainActor.run {
            if errors.isEmpty {
                cloudTAKImportSucceeded = true
                cloudTAKAlertTitle = "Success"
                cloudTAKAlertMessage = "Configuration imported successfully. The server connection will be established."
                isShowingCloudTAKAlert = true
                downloader.cleanup()
                downloadedZipURL = nil
                importStatusMessage = ""
            } else {
                // Standard parse failed — try with URL password if available, otherwise prompt
                TAKLogger.debug("[CertEnrollment] Standard parse failed: \(errors). Trying password fallback.")
                importStatusMessage = ""
                downloadedZipURL = zipURL
                if let password = cloudTAKPassword, !password.isEmpty {
                    p12PasswordInput = password
                    importWithPassword()
                } else {
                    isShowingPasswordPrompt = true
                }
            }
        }
    }
    
    func importWithPassword() {
        guard let zipURL = downloadedZipURL else { return }
        guard !p12PasswordInput.isEmpty else { return }
        
        let passwordData = Data(p12PasswordInput.utf8)
        p12PasswordInput = ""
        
        importStatusMessage = "Importing certificates..."
        
        let tdpp = TAKDataPackageParser(fileLocation: zipURL)
        tdpp.parse(p12Password: passwordData)
        
        if tdpp.parsingErrors.isEmpty {
            cloudTAKImportSucceeded = true
            cloudTAKAlertTitle = "Success"
            cloudTAKAlertMessage = "Configuration imported successfully. The server connection will be established."
            isShowingCloudTAKAlert = true
            downloader.cleanup()
            downloadedZipURL = nil
        } else {
            let errors = tdpp.parsingErrors.joined(separator: "\n\n")
            // Check if it's a password error (keep zip for retry)
            if errors.lowercased().contains("password") || errors.lowercased().contains("certificate") {
                cloudTAKAlertTitle = "Import Error"
                cloudTAKAlertMessage = "Incorrect password. Please try again."
                isShowingCloudTAKAlert = true
                // Don't cleanup — allow retry
            } else {
                cloudTAKAlertTitle = "Import Failed"
                cloudTAKAlertMessage = "Data package could not be processed\n\n\(errors)"
                isShowingCloudTAKAlert = true
                downloader.cleanup()
                downloadedZipURL = nil
            }
        }
        importStatusMessage = ""
    }
    
    func cancelCloudTAKImport() {
        downloader.cancel()
        downloadedZipURL = nil
        cloudTAKURL = nil
        cloudTAKPassword = nil
        isDownloading = false
        isShowingPasswordPrompt = false
        importStatusMessage = ""
        p12PasswordInput = ""
    }
    
    func submitCertEnrollmentForm() {
        settingsStore.takServerUrl = formServerURL
        settingsStore.takServerPort = formServerPort
        settingsStore.takServerUsername = formUsername
        settingsStore.takServerPassword = formPassword
        settingsStore.takServerCSRPort = formCSRPort
        settingsStore.takServerSecureAPIPort = formSecureAPIPort
        csrRequest.beginEnrollment()
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
                        Button("Scan QR", role: .none) {
                            setUpCaptureSession()
                        }
                        Button("Start Enrollment", role: .none) {
                            submitCertEnrollmentForm()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Text("Status: " + csrRequest.enrollmentStatus.description)
                Text("For Server \(SettingsStore.global.takServerUrl)")
                
                if isDownloading {
                    ProgressView("Downloading configuration...")
                        .padding(.top, 8)
                }
                if !importStatusMessage.isEmpty && !isDownloading {
                    Text(importStatusMessage)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
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
                Alert(title: Text("QR Code Failure"), message: Text(qrCodeFailureMessage), dismissButton: .default(Text("OK")))
            }
            .alert("Confirm Download", isPresented: $isShowingHostConfirmation) {
                Button("Cancel", role: .cancel) {
                    cloudTAKURL = nil
                }
                Button("Download") {
                    startCloudTAKDownload()
                }
            } message: {
                Text("Download configuration from \(cloudTAKURL?.host ?? "unknown host")?")
            }
            .alert(cloudTAKAlertTitle, isPresented: $isShowingCloudTAKAlert) {
                if downloadedZipURL != nil && cloudTAKAlertTitle == "Import Error" {
                    Button("Retry") {
                        isShowingPasswordPrompt = true
                    }
                    Button("Cancel", role: .cancel) {
                        cancelCloudTAKImport()
                    }
                } else if cloudTAKImportSucceeded {
                    Button("OK") {
                        isProcessingDataPackage = false
                        dismiss()
                    }
                } else {
                    Button("OK", role: .cancel) { }
                }
            } message: {
                Text(cloudTAKAlertMessage)
            }
            .sheet(isPresented: $isShowingPasswordPrompt) {
                NavigationView {
                    VStack(spacing: 20) {
                        Text("Enter the password set when generating the configuration file in CloudTAK.")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        SecureField("P12 Password", text: $p12PasswordInput)
                            .autocorrectionDisabled(true)
                            .textContentType(.password)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                        
                        Button("Import") {
                            isShowingPasswordPrompt = false
                            importWithPassword()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(p12PasswordInput.isEmpty)
                        
                        Spacer()
                    }
                    .padding(.top, 30)
                    .navigationTitle("P12 Password")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                isShowingPasswordPrompt = false
                                cancelCloudTAKImport()
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
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
