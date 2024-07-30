//
//  MapView.swift
//  TAKAware
//
//  Created by Cory Foy on 7/27/24.
//

import CoreData
import Foundation
import MapKit
import SwiftUI

final class MapPointAnnotation: NSObject, MKAnnotation {
    var id: String
    dynamic var title: String?
    dynamic var subtitle: String?
    dynamic var coordinate: CLLocationCoordinate2D
    dynamic var icon: String?
    dynamic var cotType: String?
    dynamic var image: UIImage? = UIImage.init(systemName: "circle.fill")
    dynamic var color: UIColor?
    dynamic var remarks: String?
    
    var annotationIdentifier: String {
        return icon ?? cotType ?? "pli"
    }
    
    init(mapPoint: COTData) {
        self.id = mapPoint.id?.uuidString ?? UUID().uuidString
        self.title = mapPoint.callsign ?? "NO CALLSIGN"
        self.icon = mapPoint.icon ?? ""
        self.cotType = mapPoint.cotType ?? "a-U-G"
        self.coordinate = CLLocationCoordinate2D(latitude: mapPoint.latitude, longitude: mapPoint.longitude)
        if mapPoint.iconColor != nil && mapPoint.iconColor!.isNotEmpty {
            self.color = IconData.colorFromArgb(argbVal: Int(mapPoint.iconColor!)!)
        }
        self.remarks = mapPoint.remarks
    }
}

class SituationalAnnotationView: MKAnnotationView {
    @Binding var isDetailViewOpen: Bool
    
    init(annotation: MapPointAnnotation, reuseIdentifier: String?, isDetailViewOpen: Binding<Bool>) {
        self._isDetailViewOpen = isDetailViewOpen
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.canShowCallout = true
        setUpMenu()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpMenu() {
        let detailsAction = UIAction(title: "Details",
                                                   handler: {_ in
            self.isDetailViewOpen.toggle()
            print("Details action")
        })
                
        let deleteAction = UIAction(title: "Delete",
                                  handler: {_ in
          print("Delete action")
        })
        
        let bloodhoundAction = UIAction(title: "Bloodhound",
                                  handler: {_ in
          print("Bloodhound action")
        })
        
        let menuTitle = self.annotation?.title ?? ""
                
        let button = UIButton(type: .detailDisclosure)
        button.menu = UIMenu(title: menuTitle!,
                           children: [detailsAction, bloodhoundAction, deleteAction])
        button.showsMenuAsPrimaryAction = true
        self.canShowCallout = true
        self.rightCalloutAccessoryView = button
    }
}

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var mapType: UInt
    @Binding var isAcquiringBloodhoundTarget: Bool
    @Binding var isDetailViewOpen: Bool
    @Binding var currentSelectedAnnotation: MapPointAnnotation?
    
    @FetchRequest(sortDescriptors: []) var mapPointsData: FetchedResults<COTData>

    @State var mapView: MKMapView = MKMapView()
    @State var activeBloodhound: MKGeodesicPolyline?
    @State var bloodhoundStartAnnotation: MapPointAnnotation?
    @State var bloodhoundEndAnnotation: MapPointAnnotation?
    @State var activeCircle: MKCircle?

    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.setRegion(region, animated: true)
        mapView.setCenter(region.center, animated: true)
        mapView.showsUserLocation = true
        mapView.showsCompass = false
        mapView.userTrackingMode = .followWithHeading
        mapView.pointOfInterestFilter = .excludingAll
        mapView.mapType = MKMapType(rawValue: UInt(mapType))!
        mapView.layer.borderColor = UIColor.black.cgColor
        mapView.layer.borderWidth = 1.0
        mapView.isHidden = false
        
        let compassBtn = MKCompassButton(mapView: mapView)
        compassBtn.frame.origin = CGPoint(x: 24.0, y: 54.0)
        compassBtn.compassVisibility = .visible
        mapView.addSubview(compassBtn)
        
//        let locateBtn = MKUserTrackingButton(mapView: mapView)
//        locateBtn.frame.origin = CGPoint(x: 27.0, y: 114.0)
//        locateBtn.tintColor = .yellow
//        locateBtn.backgroundColor = .clear
//        mapView.addSubview(locateBtn)

        return mapView
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        view.mapType = MKMapType(rawValue: UInt(mapType))!
        updateAnnotations(from: view)
    }
    
    private func updateAnnotations(from mapView: MKMapView) {
        
        if(!isAcquiringBloodhoundTarget && activeBloodhound != nil) {
            mapView.removeOverlay(activeBloodhound!)
            DispatchQueue.main.async { activeBloodhound = nil }
        }
        
        let incomingData = mapPointsData
        
        let existingAnnotations = mapView.annotations.filter { $0 is MapPointAnnotation }
        let current = Set(existingAnnotations.map { ($0 as! MapPointAnnotation).id })
        let new = Set(incomingData.map { $0.id!.uuidString })
        let toRemove = Array(current.symmetricDifference(new))
        let toAdd = Array(new.symmetricDifference(current))

        if !toRemove.isEmpty {
            let removableAnnotations = existingAnnotations.filter {
                toRemove.contains(($0 as! MapPointAnnotation).id)
            }
            mapView.removeAnnotations(removableAnnotations)
        }
        
        for annotation in mapView.annotations.filter({ $0 is MapPointAnnotation }) {
            guard let mpAnnotation = annotation as? MapPointAnnotation else { continue }
            guard let node = incomingData.first(where: {$0.id?.uuidString == mpAnnotation.id}) else { continue }
            let updatedMp = MapPointAnnotation(mapPoint: node)
            mpAnnotation.title = updatedMp.title
            mpAnnotation.color = updatedMp.color
            mpAnnotation.icon = updatedMp.icon
            mpAnnotation.cotType = updatedMp.cotType
            mpAnnotation.coordinate = updatedMp.coordinate
            mpAnnotation.remarks = updatedMp.remarks
        }

        if !toAdd.isEmpty {
            let insertingAnnotations = incomingData.filter { toAdd.contains($0.id!.uuidString)}
            let newAnnotations = insertingAnnotations.map { MapPointAnnotation(mapPoint: $0) }
            mapView.addAnnotations(newAnnotations)
        }
    }
    
    func resetMap() {
        mapView.userTrackingMode = .followWithHeading
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: MapView

        var gRecognizer = UITapGestureRecognizer()

        init(_ parent: MapView) {
            self.parent = parent
            super.init()
            self.gRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapHandler))
            self.gRecognizer.delegate = self
            self.parent.mapView.addGestureRecognizer(gRecognizer)
        }

        @objc func tapHandler(_ gesture: UITapGestureRecognizer) {
            // position on the screen, CGPoint
            let location = gRecognizer.location(in: self.parent.mapView)
            // position on the map, CLLocationCoordinate2D
            let coordinate = self.parent.mapView.convert(location, toCoordinateFrom: self.parent.mapView)
            TAKLogger.debug("Map Tapped! \(String(describing: coordinate))")
            if parent.activeCircle != nil {
                self.parent.mapView.removeOverlay(parent.activeCircle!)
                DispatchQueue.main.async { self.parent.activeCircle = nil }
            }
        }
        
        func mapView(_ mapView: MKMapView, didDeselect annotation: any MKAnnotation) {
            guard annotation is MapPointAnnotation? else {
                TAKLogger.debug("[MapView] Unknown annotation type selected")
                return
            }
            parent.currentSelectedAnnotation = nil
        }
        
        func mapView(_ mapView: MKMapView, didSelect annotation: any MKAnnotation) {
            guard let mpAnnotation = annotation as? MapPointAnnotation? else {
                TAKLogger.debug("[MapView] Unknown annotation type selected")
                return
            }
            TAKLogger.debug("[MapView] annotation selected")
            parent.currentSelectedAnnotation = mpAnnotation
            let userLocation = mapView.userLocation.coordinate
            let endPointLocation = mpAnnotation!.coordinate
            
            let mapReadyForBloodhoundTarget = parent.activeBloodhound == nil ||
                !mapView.overlays.contains(where: { $0.isEqual(parent.activeBloodhound) })
            
            if(parent.isAcquiringBloodhoundTarget &&
               mapReadyForBloodhoundTarget) {
                TAKLogger.debug("[MapView] Adding Bloodhound line")
                parent.bloodhoundEndAnnotation = mpAnnotation
                parent.activeBloodhound = MKGeodesicPolyline(coordinates: [userLocation, endPointLocation], count: 2)
                
                mapView.addOverlay(parent.activeBloodhound!)
                mapView.deselectAnnotation(annotation, animated: false)
            }
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let overlay = overlay as? MKCircle {
                TAKLogger.debug("We have a Circle Overlay!")
                let circleRenderer = MKCircleRenderer(circle: overlay)
                print(overlay.coordinate)
                circleRenderer.strokeColor = .red
                circleRenderer.fillColor = .blue
                return circleRenderer
            }
        
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer()
            }
            
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.lineWidth = 3.0
            renderer.alpha = 0.5
            renderer.strokeColor = UIColor.blue
            
            return renderer
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !annotation.isKind(of: MKUserLocation.self) else {
                // We don't customize the self marker
                return nil
            }
            
            guard let mpAnnotation = annotation as? MapPointAnnotation else { return nil }
            
            let identifier = mpAnnotation.annotationIdentifier
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = SituationalAnnotationView(
                    annotation: mpAnnotation,
                    reuseIdentifier: identifier,
                    isDetailViewOpen: parent.$isDetailViewOpen
                )
//                annotationView!.canShowCallout = true
//                let accessoryView = UIView(frame: CGRect(x: 10, y: 100, width: 300, height: 200))
//                accessoryView.layer.borderWidth = 4
//                accessoryView.layer.borderColor = UIColor.red.cgColor
//                let widthConstraint = NSLayoutConstraint(item: accessoryView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 40)
//                accessoryView.addConstraint(widthConstraint)
//
//                let heightConstraint = NSLayoutConstraint(item: accessoryView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20)
//                accessoryView.addConstraint(heightConstraint)
//                annotationView!.detailCalloutAccessoryView = accessoryView
//                annotationView!.calloutOffset = CGPoint(x: 50.0, y: 50.0)
//                accessoryView.alpha = 0.0

                let icon = IconData.iconFor(type2525: mpAnnotation.cotType ?? "", iconsetPath: mpAnnotation.icon ?? "")
                var pointIcon: UIImage = icon.icon
                
                if let pointColor = mpAnnotation.color {
                    pointIcon = pointIcon.mask(with: pointColor)
                }
                annotationView!.image = pointIcon
            }
            return annotationView
        }
    }
}
