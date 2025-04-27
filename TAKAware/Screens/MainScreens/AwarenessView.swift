//
//  AwarenessView.swift
//  TAKTracker
//
//  Created by Cory Foy on 6/22/24.
//

import CoreData
import SwiftUI
import MapKit
import MessageUI

struct TextMessageComposer: UIViewControllerRepresentable {
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
        }
        
        var parent: TextMessageComposer

        init(_ parent: TextMessageComposer) {
            self.parent = parent
        }
    }
    
    let phoneNumber: String

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.recipients = [phoneNumber]
        controller.messageComposeDelegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    typealias UIViewControllerType = MFMessageComposeViewController
}

private extension AwarenessView {
    func navBarImage(imageName: String) -> some View {
        return Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .colorMultiply(.yellow)
                .frame(width: 25.0)
                .shadow(
                    color: .yellow,
                    radius: CGFloat(0.0),
                    x: CGFloat(0.5), y: CGFloat(0.5))
    }
    
    func navBarImage(systemName: String) -> some View {
        return Image(systemName: systemName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .colorMultiply(.yellow)
                .frame(width: 25.0)
    }
}

class MapViewModel: ObservableObject {
    @Published var currentSelectedAnnotation: MapPointAnnotation? = nil
}

struct AwarenessView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.managedObjectContext) var dataContext
    
    @Binding var displayUIState: DisplayUIState
    
    @FetchRequest(sortDescriptors: []) var mapPointsData: FetchedResults<COTData>
    
    @StateObject var mapViewModel: MapViewModel = MapViewModel()
    
    @State private var tracking:MapUserTrackingMode = .none
    @State var selectedSheet: Sheet.SheetType? = nil
    @State var isAcquiringBloodhoundTarget: Bool = false
    @State var presentPhoneOptions: Bool = false
    @State var presentTextMessageComposer: Bool = false
    @State var phoneOptionsPhoneNumber: String? = nil
    @State var currentSelectedAnnotation: MapPointAnnotation? = nil
    @State var bloodhoundEndPoint: MapPointAnnotation? = nil
    @State var conflictedItems: [MapPointAnnotation] = []

    @State var bloodhoundDeselectedCallback: () -> Void = { () in }
    @State var annotationUpdatedCallback: (MapPointAnnotation) -> Void = { (_) in }
    @State var annotationSelectedCallback: (MapPointAnnotation) -> Void = { (_) in }
    @State var annotationsDeletedCallback: ([MapPointAnnotation]) -> Void = { (_) in }
    
    func formatOrZero(item: Double?, formatter: String = "%.0f") -> String {
        guard let item = item else {
            return "0"
        }

        return String(format: formatter, item)
    }
    
    func openDetailView() {
        selectedSheet = .detail
    }
    
    func openVideoPlayer() {
        selectedSheet = .videoPlayer
    }
    
    func openDeconflictionView() {
        selectedSheet = .deconflictionView
    }
    
    func closeDeconflictionView() {
        if selectedSheet == .deconflictionView {
            selectedSheet = nil
        }
    }
    
    func didSelectAnnotation(_ annotation: MapPointAnnotation) {
        mapViewModel.currentSelectedAnnotation = annotation
        closeDeconflictionView()
        annotationSelectedCallback(annotation)
    }
    
    init(displayUIState: Binding<DisplayUIState>) {
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor.baseDarkGray
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        _displayUIState = displayUIState
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                trackerStatus
                toolbarItemsRight
            }
        }
        .navigationViewStyle(.stack)
        .sheet(item: $selectedSheet, content: {
            Sheet(parentView: self, type: $0, conflictedItems: $conflictedItems, currentSelectedAnnotation: $mapViewModel.currentSelectedAnnotation)
                .presentationDetents([.medium, .large, .fraction(0.8), .height(200)])
                .presentationBackgroundInteraction(.enabled)
                .presentationContentInteraction(.scrolls)
        })
        .background(Color.baseMediumGray)
        .ignoresSafeArea()
        .overlay(alignment: .bottomTrailing, content: {
            serverAndUserInfo
                .padding(.horizontal)
        })
        .overlay(alignment: .bottomLeading, content: {
            bloodhoundInfo
                .padding(.horizontal)
        })
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(AppConstants.NOTIFY_PHONE_ACTION_REQUESTED))) { info in
            guard let phone = info.object as? String else {
                TAKLogger.error("[AwarenessView] Phone Action request notification received with no phone")
                return
            }
            phoneOptionsPhoneNumber = phone
            presentPhoneOptions = true
        }
        .sheet(isPresented: $presentTextMessageComposer, content: {
            let phoneNumber = phoneOptionsPhoneNumber ?? "UNKNOWN NUMBER"
            TextMessageComposer(phoneNumber: phoneNumber)
        })
        .actionSheet(isPresented: $presentPhoneOptions, content: {
            let phoneNumber = phoneOptionsPhoneNumber ?? "UNKNOWN NUMBER"
            var actionButtons: [ActionSheet.Button] = [
                .cancel(),
                .default(
                    Text("Copy"),
                    action: {
                        UIPasteboard.general.setValue(phoneNumber, forPasteboardType: "public.plain-text")
                    }
                )
            ]
            if let telUrl = URL(string: "tel://\(phoneNumber)") {
                if UIApplication.shared.canOpenURL(telUrl) {
                    actionButtons.append(.default(
                        Text("Call"),
                        action: { UIApplication.shared.open(telUrl) }
                    ))
                }
            } else { TAKLogger.debug("[AwarenessView] Call supported not enabled for this device") }
            if (MFMessageComposeViewController.canSendText()) {
                actionButtons.append(.default(
                    Text("Text"),
                    action: {
                        presentTextMessageComposer = true
                    }
                ))
            } else { TAKLogger.debug("[AwarenessView] Text supported not enabled for this device") }
            return ActionSheet(title: Text("\(phoneNumber)"),
                               buttons: actionButtons
            )
        })
    }
    
    var trackerStatus: some View {
        MapView(
            region: $locationManager.region,
            mapType: $settingsStore.mapTypeDisplay,
            enableTrafficDisplay: $settingsStore.enableTrafficDisplay,
            isAcquiringBloodhoundTarget: $isAcquiringBloodhoundTarget,
            conflictedItems: $conflictedItems,
            currentSelectedAnnotation: $mapViewModel.currentSelectedAnnotation,
            parentView: self
        ).ignoresSafeArea(edges: .all)
    }

    var toolbarItemsRight: some View {
        VStack(alignment: .trailing) {
            HStack(spacing: 2) {
                Spacer()

                Group {
                    Button(action: { bloodhoundDeselectedCallback() }) {
                        navBarImage(imageName: "bloodhound")
                            .colorMultiply((isAcquiringBloodhoundTarget ? .red : .clear))
                            .padding(5)
                    }
                    
                    Button(action: { selectedSheet = .channels }) {
                        navBarImage(imageName: "nav_channels")
                            .padding(5)
                    }
                    
                    Button(action: { selectedSheet = .dataPackage }) {
                        navBarImage(imageName: "nav_package")
                            .padding(5)
                    }
                    
                    Button(action: {
                        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                        
                        switch(settingsStore.preferredInterface) {
                        case "portrait":
                            windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
                            settingsStore.preferredInterface = InterfaceOrientation.landscapeRight.id
                        case "landscapeRight":
                            windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
                            settingsStore.preferredInterface = InterfaceOrientation.portrait.id
                        default:
                            if UIDevice.current.orientation.isLandscape {
                                windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
                                settingsStore.preferredInterface = InterfaceOrientation.portrait.id
                            } else {
                                windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
                                settingsStore.preferredInterface = InterfaceOrientation.landscapeRight.id
                            }
                        }
                    }) {
                        navBarImage(imageName: "nav_orientation")
                            .padding(5)
                    }
                    
                    Button(action: { selectedSheet = .emergencySettings }) {
                        navBarImage(imageName: "nav_alert")
                            .foregroundColor(settingsStore.isAlertActivated ? .red : .yellow)
                            .padding(5)
                    }
                    
    //                Button(action: { sheet = .chat }) {
    //                    navBarImage(systemName: "bubble.left")
    //                        .padding(5)
    //                }
                    
                    Button(action: { selectedSheet = .settings }) {
                        navBarImage(systemName: "line.3.horizontal")
                            .padding(5)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top)
            .foregroundColor(.yellow)
            .imageScale(.large)
            .fontWeight(.bold)
            
            selectedAnnotationInfo
                .padding(.horizontal)
        }
    }
    
    var serverStatus: some View {
        VStack {
            HStack {
                if(settingsStore.isConnectedToServer) {
                    Text("Server: Connected")
                        .foregroundColor(.green)
                        .font(.system(size: 15))
                        .padding(.all, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.black)
                        )
                } else {
                    Text("Server: \(settingsStore.connectionStatus)")
                        .foregroundColor(.red)
                        .font(.system(size: 15))
                        .padding(.all, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.black)
                        )
                }
            }
        }
    }
    
    func degreesToRadians(degrees: Double) -> Double { return degrees * .pi / 180.0 }
    func radiansToDegrees(radians: Double) -> Double { return radians * 180.0 / .pi }

    func bearingToBloodhoundTarget(from: CLLocationCoordinate2D?, to: CLLocationCoordinate2D?) -> Double {

        guard let point1 = from,
              let point2 = to else {
            return 0.0
        }
        
        let lat1 = degreesToRadians(degrees: point1.latitude)
        let lon1 = degreesToRadians(degrees: point1.longitude)

        let lat2 = degreesToRadians(degrees: point2.latitude)
        let lon2 = degreesToRadians(degrees: point2.longitude)

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)

        let bearing = radiansToDegrees(radians: radiansBearing)
        if bearing.isLess(than: 0.0) {
            return 360 + bearing
        } else {
            return bearing
        }
    }
    
    func distanceToBloodhoundTarget(from: CLLocationCoordinate2D?, to: CLLocationCoordinate2D?) -> Double {
        guard let point1 = from,
              let point2 = to else {
            return 0.0
        }
        let startLocation = CLLocation(latitude: point1.latitude, longitude: point1.longitude)
        let bloodhoundLocation = CLLocation(latitude: point2.latitude, longitude: point2.longitude)
        return startLocation.distance(from: bloodhoundLocation)
    }
    
    var bloodhoundInfo: some View {
        Group {
            if bloodhoundEndPoint != nil {
                VStack(alignment: .leading) {
                    Text(bloodhoundEndPoint?.title ?? "")
                    
                    Group {
                        ForEach(displayUIState.coordinateValue(location: locationManager.lastLocation).lines, id: \.id) { line in
                            HStack {
                                if(line.hasLineTitle()) {
                                    Text(line.lineTitle)
                                }
                                Text(line.lineContents)
                            }
                        }
                    }
                    .onTapGesture {
                        displayUIState.nextLocationUnit()
                    }
                    
                    HStack {
                        Text("\(String(format: "%.0f", bearingToBloodhoundTarget(from: locationManager.lastLocation?.coordinate, to: bloodhoundEndPoint?.coordinate)))°")
                        Spacer()
                        HStack {
                            Text(displayUIState.distanceValue(distanceMeters: distanceToBloodhoundTarget(from: locationManager.lastLocation?.coordinate, to: bloodhoundEndPoint?.coordinate)))
                        }.multilineTextAlignment(.trailing)
                    }
                    .onTapGesture {
                        displayUIState.nextDistanceUnit()
                    }
                }
                .font(.system(size: 10, weight: .bold))
                .padding(.all, 5)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.black)
                        .opacity(0.7)
                )
                .frame(width: 150)
            }
        }
    }
    
    var selectedAnnotationInfo: some View {
        Group {
            if let currentSelectedAnnotation = mapViewModel.currentSelectedAnnotation {
                VStack(alignment: .leading) {
                    Text(currentSelectedAnnotation.title ?? "")
                    
                    Group {
                        ForEach(displayUIState.coordinateValue(location: currentSelectedAnnotation.coordinate).lines, id: \.id) { line in
                            HStack {
                                if(line.hasLineTitle()) {
                                    Text(line.lineTitle)
                                }
                                Text(line.lineContents)
                            }
                        }
                    }
                    .onTapGesture {
                        displayUIState.nextLocationUnit()
                    }
                    .onLongPressGesture {
                        let coordCopy = "\(currentSelectedAnnotation.coordinate.latitude), \(currentSelectedAnnotation.coordinate.longitude)"
                        UIPasteboard.general.setValue(coordCopy, forPasteboardType: "public.plain-text")
                        let impactHeavy = UINotificationFeedbackGenerator()
                        impactHeavy.notificationOccurred(.success)
                    }
                    
                    HStack {
                        Text(displayUIState.headingValue(heading: currentSelectedAnnotation.course))
                        Spacer()
                        BatteryStatusIcon(battery: currentSelectedAnnotation.battery)
                        Spacer()
                        HStack {
                            Text(displayUIState.speedValue(metersPerSecond: currentSelectedAnnotation.speed))
                            Text("\(displayUIState.speedText())")
                        }
                        .multilineTextAlignment(.trailing)
                        .onTapGesture {
                            displayUIState.nextSpeedUnit()
                        }
                    }
                }
                .font(.system(size: 10, weight: .bold))
                .padding(.all, 5)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.black)
                        .opacity(0.7)
                )
                .frame(width: 150)
            }
        }
    }
    
    var serverAndUserInfo: some View {
        VStack(alignment: .leading) {
            HStack {
                if(settingsStore.isConnectedToServer) {
                    Text("CONNECTED")
                        .foregroundColor(.green)
                } else {
                    Text("\(settingsStore.connectionStatus)")
                        .textCase(.uppercase)
                        .foregroundColor(.red)
                }
            }
            
            Text(settingsStore.callSign)
            
            Group {
                ForEach(displayUIState.coordinateValue(location: locationManager.lastLocation).lines, id: \.id) { line in
                    HStack {
                        if(line.hasLineTitle()) {
                            Text(line.lineTitle)
                        }
                        Text(line.lineContents)
                    }
                }
            }
            .onTapGesture {
                displayUIState.nextLocationUnit()
            }
            
            HStack {
                Text(displayUIState.headingValue(
                    unit: displayUIState.currentHeadingUnit,
                    heading: locationManager.lastHeading))
                Spacer()
                HStack {
                    Text(displayUIState.speedValue(
                        location: locationManager.lastLocation))
                    Text("\(displayUIState.speedText())")
                }
                .multilineTextAlignment(.trailing)
                .onTapGesture {
                    displayUIState.nextSpeedUnit()
                }
            }
        }
        .font(.system(size: 10, weight: .bold))
        .padding(.all, 5)
        .background(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color.black)
                .opacity(0.7)
        )
        .frame(width: 150)
    }
}
