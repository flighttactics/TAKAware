//
//  AwarenessView.swift
//  TAKTracker
//
//  Created by Cory Foy on 6/22/24.
//

import CoreData
import SwiftUI
import MapKit

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

struct AwarenessView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.managedObjectContext) var dataContext
    
    @Binding var displayUIState: DisplayUIState
    
    @FetchRequest(sortDescriptors: []) var mapPointsData: FetchedResults<COTData>
    
    @State private var tracking:MapUserTrackingMode = .none
    @State var selectedSheet: Sheet.SheetType? = nil
    @State var isAcquiringBloodhoundTarget: Bool = false
    @State var currentSelectedAnnotation: MapPointAnnotation? = nil
    @State var conflictedItems: [MapPointAnnotation] = []

    @State var bloodhoundDeselectedCallback: () -> Void = { () in }
    @State var annotationUpdatedCallback: (MapPointAnnotation) -> Void = { (_) in }
    @State var annotationSelectedCallback: (MapPointAnnotation) -> Void = { (_) in }
    
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
        currentSelectedAnnotation = annotation
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
            Sheet(parentView: self, type: $0, conflictedItems: $conflictedItems, currentSelectedAnnotation: $currentSelectedAnnotation)
                .presentationDetents([.medium, .large, .fraction(0.8), .height(200)])
                .presentationBackgroundInteraction(.enabled(upThrough: .height(200)))
                .presentationContentInteraction(.scrolls)
        })
        .background(Color.baseMediumGray)
        .ignoresSafeArea()
        .overlay(alignment: .bottomTrailing, content: {
            serverAndUserInfo
                .padding(.horizontal)
        })
    }
    
    var trackerStatus: some View {
        MapView(
            region: $locationManager.region,
            mapType: $settingsStore.mapTypeDisplay,
            enableTrafficDisplay: $settingsStore.enableTrafficDisplay,
            isAcquiringBloodhoundTarget: $isAcquiringBloodhoundTarget,
            currentSelectedAnnotation: $currentSelectedAnnotation,
            conflictedItems: $conflictedItems,
            parentView: self
        ).ignoresSafeArea(edges: .all)
    }

    var toolbarItemsRight: some View {
        HStack(spacing: 2) {
            Spacer()

            Group {
                Button(action: { bloodhoundDeselectedCallback() }) {
                    navBarImage(imageName: "bloodhoundsvg")
                        .colorMultiply((isAcquiringBloodhoundTarget ? .red : .yellow))
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
                    navBarImage(systemName: "exclamationmark.triangle")
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
            
            ForEach(displayUIState.coordinateValue(location: locationManager.lastLocation).lines, id: \.id) { line in
                HStack {
                    if(line.hasLineTitle()) {
                        Text(line.lineTitle)
                    }
                    Text(line.lineContents)
                }
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
                }.multilineTextAlignment(.trailing)
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
        .onTapGesture {
            displayUIState.nextLocationUnit()
        }
    }
}
