//
//  AnnotationDetailView.swift
//  TAKAware
//
//  Created by Cory Foy on 7/27/24.
//

import Foundation
import SwiftUI
import WebKit
import SwiftTAK

enum BaseCot2525Mapping: String, CaseIterable, Identifiable, CustomStringConvertible {
    var id: Self { self }
    
    case FriendlyAirTrack = "a-f-P"
    case FriendlyGroundTrack = "a-f-G"
    case FriendlySeaSurfaceTrack = "a-f-S"
    case FriendlySubsurfaceTrack = "a-f-U"
    
    case NeutralAirTrack = "a-n-P"
    case NeutralGroundTrack = "a-n-G"
    case NeutralSeaSurfaceTrack = "a-n-S"
    case NeutralSubsurfaceTrack = "a-n-U"
    
    case UnknownAirTrack = "a-u-P"
    case UnknownGroundTrack = "a-u-G"
    case UnknownSeaSurfaceTrack = "a-u-S"
    case UnknownSubsurfaceTrack = "a-u-U"
    
    case HostileAirTrack = "a-h-P"
    case HostileGroundTrack = "a-h-G"
    case HostileSeaSurfaceTrack = "a-h-S"
    case HostileSubsurfaceTrack = "a-h-U"
    
    public var description: String {
        switch(self) {
        case .FriendlyAirTrack: "Friendly - Air track"
        case .FriendlyGroundTrack: "Friendly - Ground track"
        case .FriendlySubsurfaceTrack: "Friendly - Subsurface track"
        case .FriendlySeaSurfaceTrack: "Friendly - Sea surface track"
        case .NeutralAirTrack: "Neutral - Air track"
        case .NeutralGroundTrack: "Neutral - Ground track"
        case .NeutralSubsurfaceTrack: "Neutral - Subsurface track"
        case .NeutralSeaSurfaceTrack: "Neutral - Sea surface track"
        case .UnknownAirTrack: "Unknown - Air track"
        case .UnknownGroundTrack: "Unknown - Ground track"
        case .UnknownSubsurfaceTrack: "Unknown - Subsurface track"
        case .UnknownSeaSurfaceTrack: "Unknown - Sea surface track"
        case .HostileAirTrack: "Hostile - Air track"
        case .HostileGroundTrack: "Hostile - Ground track"
        case .HostileSubsurfaceTrack: "Hostile - Subsurface track"
        case .HostileSeaSurfaceTrack: "Hostile - Sea surface track"
        }
    }
}

struct HTMLView: UIViewRepresentable {
    let htmlString: String
    let webView: WKWebView = WKWebView()
//    @Binding var height: Double
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }

    func makeUIView(context: Context) -> WKWebView {
        webView.isOpaque = false
        webView.loadHTMLString(htmlString, baseURL: nil)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
    }
    
//    func webViewConfiguration() -> WKWebViewConfiguration {
//        let configuration = WKWebViewConfiguration()
//        configuration.userContentController = userContentController()
//        return configuration
//    }
//    
//    private func userContentController() -> WKUserContentController {
//        let controller = WKUserContentController()
//        controller.addUserScript(viewPortScript())
//        return controller
//    }
//    
//    private func viewPortScript() -> WKUserScript {
//        let viewPortScript = """
//            var meta = document.createElement('meta');
//            meta.setAttribute('name', 'viewport');
//            meta.setAttribute('content', 'width=device-width');
//            meta.setAttribute('initial-scale', '1.0');
//            meta.setAttribute('maximum-scale', '1.0');
//            meta.setAttribute('minimum-scale', '1.0');
//            meta.setAttribute('user-scalable', 'no');
//            document.getElementsByTagName('head')[0].appendChild(meta);
//        """
//        return WKUserScript(source: viewPortScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
//    }
//    
//    class Coordinator: NSObject, WKNavigationDelegate {
//        var parent: HTMLView
//        init(_ parent: HTMLView) {
//            self.parent = parent
//        }
//        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//            webView.evaluateJavaScript("document.documentElement.scrollHeight", completionHandler: { (height, error) in
//                NSLog("***Height: \(height) Error: \(error)")
//                guard let height = height as? CGFloat else {
//                    self.parent.height = 100.0
//                    return
//                }
//                if height < 30.0 {
//                    self.parent.height = 100.0
//                } else {
//                    self.parent.height = height
//                }
//            })
//        }
//    }
}

struct InfoRowView: View {
    var title: String
    var info: String?
    var alwaysShow: Bool = false
    
    var infoText: String {
        if info == nil { return "" }
        return info!
    }
    
    var shouldDisplay: Bool {
        let emptyVals = [
            "0°", "0 m/s", "0.0 m", "-1", "\(String(COTPoint.DEFAULT_ERROR_VALUE)) m"
        ]
        if alwaysShow { return true }
        if infoText.isEmpty { return false }
        if emptyVals.contains(infoText) {
            return false
        }
        return true
     }
    
    var body: some View {
        Group {
            if shouldDisplay {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .foregroundColor(.primary)
                        .font(.headline)
                    Text(infoText)
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            }
        }
    }
}

struct RemarksRowView: View {
    var title: String
    var info: String?
    
    var infoText: AttributedString {
        if info == nil { return "" }
        return (try? AttributedString(markdown: info!, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(info!)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .foregroundColor(.primary)
                .font(.headline)
            Text(infoText)
                .foregroundColor(.secondary)
                .font(.subheadline)
        }
    }
}

struct TitleRowView: View {
    var annotation: MapPointAnnotation
    
    var infoText: String {
        var finalText = annotation.role ?? ""
        if annotation.cotType != nil && !annotation.cotType!.isEmpty {
            if !finalText.isEmpty {
                finalText = "\(finalText) (\(annotation.cotType!))"
            } else {
                finalText = annotation.cotType!
            }
        }
        return finalText
    }
    
    var body: some View {
        Group {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(annotation.title ?? "")
                        .foregroundColor(.primary)
                        .font(.headline)
                    Text(infoText)
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                Spacer()
                IconImage(annotation: annotation, frameSize: 30.0)
            }
        }
    }
}

struct AnnotationDetailReadOnly: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var takManager: TAKManager
    @Binding var currentSelectedAnnotation: MapPointAnnotation?
    @Binding var isEditing: Bool
    @State private var showingAlert = false
    @State private var htmlContentHeight: Double = 200.0
    
    func broadcastPoint() {
        guard currentSelectedAnnotation != nil else { return }
        takManager.broadcastPoint(annotation: currentSelectedAnnotation!)
        showingAlert = true
    }

    var body: some View {
        List {
            if let annotation = currentSelectedAnnotation {
                if annotation.isKML {
                    VStack {
                        HStack(alignment: .top) {
                            VStack {
                                Group {
                                    Text(annotation.title ?? "")
                                    Text("Type: \(annotation.cotType ?? "")")
                                    Text("Latitude: \(NSString(format: "%.6f", annotation.coordinate.latitude))")
                                    Text("Longitude: \(NSString(format: "%.6f", annotation.coordinate.longitude))")
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            IconImage(annotation: annotation, frameSize: 40.0)
                        }
                        // TODO: Be smarter about when to show HTML (check for CDATA)
                        HTMLView(htmlString: annotation.remarks!)
                            .frame(height: htmlContentHeight)
                    }
                } else {
                    TitleRowView(annotation: annotation)
                    InfoRowView(title: "Location", info: "\(String(format: "%.6f", annotation.coordinate.latitude)), \(String(format: "%.6f", annotation.coordinate.longitude))", alwaysShow: true)
                    InfoRowView(title: "Height Above Elevation", info: String(format: "%.1f m", annotation.altitude!))
                    InfoRowView(title: "Speed", info: String(format: "%.0f m/s", annotation.speed!))
                    InfoRowView(title: "Course", info: String(format: "%.0f°", annotation.course!))
                    if annotation.battery != nil && annotation.battery! != 0.0 {
                        HStack {
                            InfoRowView(title: "Battery", info: String(format: "%.0f%%", annotation.battery!))
                            Spacer()
                            BatteryStatusIcon(battery: annotation.battery!)
                        }
                    }
                    RemarksRowView(title: "Remarks", info: annotation.remarks)
                }
                HStack {
                    Spacer()
                    Button(action: { isEditing = true }) {
                        HStack {
                            Text("Edit")
                            Image(systemName: "square.and.pencil")
                        }
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                    Button(action: { broadcastPoint() }) {
                        HStack {
                            Text("Broadcast")
                            Image(systemName: "square.and.arrow.up.fill")
                        }
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                }
            } else {
                Text("No Map Item Selected")
            }
        }
        .alert("Marker broadcast to server", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}

struct AnnotationDetailView: View {
    @Environment(\.dismiss) var dismiss
    @State var isEditing: Bool = false
    @Binding var currentSelectedAnnotation: MapPointAnnotation?
    let parentView: AwarenessView

    var body: some View {
        NavigationStack {
            Group {
                if currentSelectedAnnotation == nil {
                    Text("No Map Item Selected")
                } else if(isEditing) {
                    AnnotationEditView(currentSelectedAnnotation: $currentSelectedAnnotation, parentView: parentView)
                } else {
                    AnnotationDetailReadOnly(currentSelectedAnnotation: $currentSelectedAnnotation, isEditing: $isEditing)
                }
            }
            .navigationBarItems(trailing: HStack {
                Button(action: {
                    if isEditing {
                        isEditing.toggle()
                    } else {
                        dismiss()
                    }
                }, label: {
                    if isEditing {
                        Text("Save")
                    } else {
                        Text("Close")
                    }
                })
            })
            .navigationTitle(currentSelectedAnnotation?.title ?? "Item Detail")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AnnotationEditView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var currentSelectedAnnotation: MapPointAnnotation?
    var parentView: AwarenessView
    @State var title: String = ""
    @State var remarks: String = ""
    @State var cotType: String = ""
    @State private var selectedCotType: BaseCot2525Mapping = .UnknownGroundTrack
    @State var icon: String = ""
    
    var annotation: MapPointAnnotation? {
        currentSelectedAnnotation
    }
    
    var annotationId: String {
        annotation?.id ?? UUID().uuidString
    }
    
    func updateAnnotation() {
        DataController.shared.updateMarker(id: annotationId, title: title, remarks: remarks, cotType: selectedCotType.rawValue)
        if(annotation != nil) {
            parentView.annotationUpdatedCallback(annotation!)
        }
    }
    
    var body: some View {
        Group {
            HStack {
                Text("Call Sign")
                    .foregroundColor(.secondary)
                TextField("Call Sign", text: $title, onEditingChanged: { isEditing in
                    if(!isEditing) {
                        annotation?.title = title
                        updateAnnotation()
                    }
                })
                    .keyboardType(.asciiCapable)
                    .multilineTextAlignment(.trailing)
            }
            HStack {
                Text("Remarks")
                    .foregroundColor(.secondary)
                TextField("Remarks", text: $remarks, onEditingChanged: { isEditing in
                    if(!isEditing) {
                        annotation?.remarks = remarks
                        updateAnnotation()
                    }
                })
                    .keyboardType(.asciiCapable)
                    .multilineTextAlignment(.trailing)
            }
            if annotation != nil && !annotation!.isShape {
                HStack {
                    Picker("Type", selection: $selectedCotType) {
                        ForEach(BaseCot2525Mapping.allCases) { option in
                            Text(String(describing: option))

                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedCotType) { _ in
                        annotation?.cotType = selectedCotType.rawValue
                        updateAnnotation()
                    }
                }
            }
        }
        .onAppear {
            title = annotation?.title ?? "UNKNOWN"
            remarks = annotation?.remarks ?? ""
            cotType = annotation?.cotType ?? "a-U-G"
            selectedCotType = BaseCot2525Mapping(rawValue: cotType) ?? .UnknownGroundTrack
            icon = annotation?.icon ?? ""
        }
    }
}
