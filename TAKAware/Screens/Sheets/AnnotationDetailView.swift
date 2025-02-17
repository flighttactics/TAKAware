//
//  AnnotationDetailView.swift
//  TAKAware
//
//  Created by Cory Foy on 7/27/24.
//

import Foundation
import SwiftUI
import WebKit

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
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(htmlString, baseURL: nil)
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

struct AnnotationDetailReadOnly: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var takManager: TAKManager
    @Binding var currentSelectedAnnotation: MapPointAnnotation?
    @Binding var isEditing: Bool
    @State private var showingAlert = false
    @State private var htmlContentHeight: Double = 100.0
    
    var annotation: MapPointAnnotation? {
        currentSelectedAnnotation
    }
    
    func broadcastPoint() {
        guard currentSelectedAnnotation != nil else { return }
        takManager.broadcastPoint(annotation: currentSelectedAnnotation!)
        showingAlert = true
    }

    var body: some View {
        Group {
            if annotation == nil {
                Text("No Map Item Selected")
            } else {
                HStack(alignment: .top) {
                    VStack {
                        Group {
                            Text(annotation!.title ?? "")
                            // TODO: Be smarter about when to show HTML (check for CDATA)
                            if annotation!.isKML {
                                Text("Type: \(annotation!.cotType ?? "")")
                                Text("Latitude: \(annotation!.coordinate.latitude.description)")
                                Text("Longitude: \(annotation!.coordinate.longitude.description)")
                                HTMLView(htmlString: annotation!.remarks!)
                                    .frame(height: htmlContentHeight)
                            } else {
                                Text("Remarks: \(annotation!.remarks!)")
                                Text("Type: \(annotation!.cotType ?? "")")
                                Text("Latitude: \(annotation!.coordinate.latitude.description)")
                                Text("Longitude: \(annotation!.coordinate.longitude.description)")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    IconImage(annotation: annotation, frameSize: 40.0)
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
    
    var annotation: MapPointAnnotation? {
        currentSelectedAnnotation
    }

    var body: some View {
        NavigationStack {
            List {
                if annotation == nil {
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
            .navigationTitle(annotation?.title ?? "Item Detail")
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
