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
                .frame(width: 20.0)
                .shadow(
                    color: .yellow,
                    radius: CGFloat(0.0),
                    x: CGFloat(0.5), y: CGFloat(0.5))
    }
}

struct AwarenessView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var manager: LocationManager
    @Environment(\.managedObjectContext) var dataContext
    
    @Binding var displayUIState: DisplayUIState
    
    @FetchRequest(sortDescriptors: []) var mapPointsData: FetchedResults<COTData>
    
    @State private var tracking:MapUserTrackingMode = .none
    @State private var sheet: Sheet.SheetType?
    @State private var isAcquiringBloodhoundTarget: Bool = false
    @State private var isDetailViewOpen: Bool = false
    @State private var isVideoPlayerOpen: Bool = false
    @State private var currentSelectedAnnotation: MapPointAnnotation?
    
    func formatOrZero(item: Double?, formatter: String = "%.0f") -> String {
        guard let item = item else {
            return "0"
        }
        return String(format: formatter, item)
    }
    
    init(displayUIState: Binding<DisplayUIState>) {
        navBarAppearence.configureWithOpaqueBackground()
        navBarAppearence.backgroundColor = UIColor.baseDarkGray
        navBarAppearence.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearence.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearence
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearence
        
        _displayUIState = displayUIState
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                trackerStatus
                toolbarItemsRight
            }
        }
        .navigationViewStyle(.columns)
        .sheet(item: $sheet, content: {
            Sheet(type: $0)
                .presentationDetents([.medium, .large, .fraction(0.8), .height(200)])
                .presentationBackgroundInteraction(.enabled(upThrough: .height(200)))
                .presentationContentInteraction(.scrolls)
        })
        .sheet(isPresented: $isDetailViewOpen, content: {
            AnnotationDetailView(annotation: $currentSelectedAnnotation)
                .presentationDetents([.medium, .large, .fraction(0.8), .height(200)])
                .presentationBackgroundInteraction(.enabled(upThrough: .height(200)))
                .presentationContentInteraction(.scrolls)
        })
        .sheet(isPresented: $isVideoPlayerOpen, content: {
            VideoPlayerView(annotation: $currentSelectedAnnotation)
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
            region: $manager.region,
            mapType: $settingsStore.mapTypeDisplay,
            isAcquiringBloodhoundTarget: $isAcquiringBloodhoundTarget,
            isDetailViewOpen: $isDetailViewOpen, 
            isVideoPlayerOpen: $isVideoPlayerOpen,
            currentSelectedAnnotation: $currentSelectedAnnotation
        )
        .ignoresSafeArea(edges: .all)
    }

    var toolbarItemsRight: some View {
        HStack {
            Spacer()

//            Button(action: {
//                print("Clearing...")
//                mapPointsData.forEach { row in
//                    dataContext.delete(row)
//                }
//                do {
//                    try dataContext.save()
//                    print("All Clear")
//                } catch {
//                    print("ERROR saving deletes: \(error)")
//                }
//            }) {
//                Image(systemName: "clear.fill")
//            }
//
//            Button(action: {
//                print("Adding...")
//                let mapPointData = COTData(context: dataContext)
//                mapPointData.id = UUID()
//                mapPointData.callsign = "Point \(Int.random(in: 1...1000))"
//                mapPointData.latitude = Double.random(in: 37.5...37.9)
//                mapPointData.longitude = -Double.random(in: 122.1...122.5)
//                try? dataContext.save()
//            }) {
//                Image(systemName: "plus")
//            }

            Button(action: { isAcquiringBloodhoundTarget.toggle() }) {
                navBarImage(imageName: "bloodhound")
                    .colorMultiply((isAcquiringBloodhoundTarget ? .red : .yellow))
            }
            
            Button(action: { sheet = .channels }) {
                navBarImage(imageName: "nav_channels")
            }
            
            Button(action: { sheet = .dataSync }) {
                navBarImage(imageName: "nav_package")
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
            }
            
            Button(action: { sheet = .emergencySettings }) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(settingsStore.isAlertActivated ? .red : .yellow)
            }
            
            Button(action: { sheet = .chat }) {
                Image(systemName: "bubble.left")
            }
            
            Button(action: { sheet = .settings }) {
                Image(systemName: "line.3.horizontal")
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
            
            ForEach(displayUIState.coordinateValue(location: manager.lastLocation).lines, id: \.id) { line in
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
                    heading: manager.lastHeading))
                Spacer()
                HStack {
                    Text(displayUIState.speedValue(
                        location: manager.lastLocation))
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
