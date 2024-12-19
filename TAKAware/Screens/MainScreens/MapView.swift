//
//  MapView.swift
//  TAKAware
//
//  Created by Cory Foy on 7/27/24.
//

import CoreData
import Foundation
import MapKit
import SwiftTAK
import SwiftUI

class COTMapObject: NSObject {
    static let RECTANGLE_TYPES: [String] = ["u-d-f", "u-d-r"]
    static let CIRCLE_TYPES: [String] = ["u-d-c-c"]
    static let ELLIPSE_TYPES: [String] = ["u-d-c-e"]
    static let LINE_TYPES: [String] = ["b-m-r"]
    static let OVERLAY_TYPES: [String] = RECTANGLE_TYPES + CIRCLE_TYPES + LINE_TYPES + ELLIPSE_TYPES
    
    var cotData: COTData
    var cotEvent: COTEvent?
    
    var cotType: String {
        cotData.cotType ?? ""
    }
    
    var isShape: Bool {
        COTMapObject.OVERLAY_TYPES.contains(cotType)
    }
    
    var isLine: Bool {
        COTMapObject.LINE_TYPES.contains(cotType)
    }
    
    var annotation: MapPointAnnotation {
        if isLine {
            let line = self.shape as! COTMapPolyline
            let centerPoint = line.coordinate
            cotData.latitude = centerPoint.latitude
            cotData.longitude = centerPoint.longitude
            return MapPointAnnotation(mapPoint: cotData, shape: self.shape)
        } else if isShape {
            return MapPointAnnotation(mapPoint: cotData, shape: self.shape)
        } else {
            return MapPointAnnotation(mapPoint: cotData)
        }
    }
    
    func buildRectangle() -> COTMapPolygon {
        let pointLinks = cotEvent?.cotDetail?.cotLinks ?? []
        let strokeColor = cotEvent?.cotDetail?.cotStrokeColor?.value ?? -1
        let strokeWeight = cotEvent?.cotDetail?.cotStrokeWeight?.value ?? -1
        let fillColor = cotEvent?.cotDetail?.cotFillColor?.value ?? -1
        let labelsOn = cotEvent?.cotDetail?.cotLabelsOn?.value ?? true
        let coordinates: [CLLocationCoordinate2D] = pointLinks.map { pointLink in
            let points = pointLink.point.split(separator: ",")
            guard points.count >= 2 else {
                return CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
            }
            let lat = Double(String(points[0])) ?? 0.0
            let lon = Double(String(points[1])) ?? 0.0
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        let polygon = COTMapPolygon(coordinates: coordinates, count: coordinates.count)
        polygon.strokeColor = strokeColor
        polygon.strokeWeight = strokeWeight
        polygon.fillColor = fillColor
        polygon.labelsOn = labelsOn
        return polygon
    }
    
    func buildPolyline() -> COTMapPolyline {
        let pointLinks = cotEvent?.cotDetail?.cotLinks ?? []
        let strokeColor = cotEvent?.cotDetail?.cotStrokeColor?.value ?? -1
        let strokeWeight = cotEvent?.cotDetail?.cotStrokeWeight?.value ?? -1
        let fillColor = cotEvent?.cotDetail?.cotFillColor?.value ?? -1
        let labelsOn = cotEvent?.cotDetail?.cotLabelsOn?.value ?? true
        let coordinates: [CLLocationCoordinate2D] = pointLinks.map { pointLink in
            let points = pointLink.point.split(separator: ",")
            guard points.count >= 2 else {
                return CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
            }
            let lat = Double(String(points[0])) ?? 0.0
            let lon = Double(String(points[1])) ?? 0.0
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        let polyline = COTMapPolyline(coordinates: coordinates, count: coordinates.count)
        polyline.strokeColor = strokeColor
        polyline.strokeWeight = strokeWeight
        polyline.fillColor = fillColor
        polyline.labelsOn = labelsOn
        return polyline
    }
    
    func buildCircle() -> COTMapCircle {
        let cotShape = cotEvent?.cotDetail?.cotShape
        let strokeColor = cotEvent?.cotDetail?.cotStrokeColor?.value ?? -1
        let strokeWeight = cotEvent?.cotDetail?.cotStrokeWeight?.value ?? -1
        let fillColor = cotEvent?.cotDetail?.cotFillColor?.value ?? -1
        let labelsOn = cotEvent?.cotDetail?.cotLabelsOn?.value ?? true
        let major = cotShape?.major ?? 0.0
        let minor = cotShape?.minor ?? 0.0
        let angle = cotShape?.angle ?? 360
        let circle = COTMapCircle(center: CLLocationCoordinate2D(latitude: cotData.latitude, longitude: cotData.longitude), radius: major)
        circle.major = major
        circle.minor = minor
        circle.angle = angle
        circle.strokeColor = strokeColor
        circle.strokeWeight = strokeWeight
        circle.fillColor = fillColor
        circle.labelsOn = labelsOn
        return circle
    }
    
    func buildEllipse() -> COTMapEllipse {
        let cotShape = cotEvent?.cotDetail?.cotShape
        let strokeColor = cotEvent?.cotDetail?.cotStrokeColor?.value ?? -1
        let strokeWeight = cotEvent?.cotDetail?.cotStrokeWeight?.value ?? -1
        let fillColor = cotEvent?.cotDetail?.cotFillColor?.value ?? -1
        let labelsOn = cotEvent?.cotDetail?.cotLabelsOn?.value ?? true
        let major = cotShape?.major ?? 0.0
        let minor = cotShape?.minor ?? 0.0
        let angle = cotShape?.angle ?? 360
        let ellipse = COTMapEllipse(center: CLLocationCoordinate2D(latitude: cotData.latitude, longitude: cotData.longitude), radius: major)
        ellipse.major = major
        ellipse.minor = minor
        ellipse.angle = angle
        ellipse.strokeColor = strokeColor
        ellipse.strokeWeight = strokeWeight
        ellipse.fillColor = fillColor
        ellipse.labelsOn = labelsOn
        return ellipse
    }
    
    var shape: MKOverlay? {
        // Shapes: Circle, Polygon, Polyline
        self.cotEvent = COTXMLParser().parse(cotData.rawXml ?? "")
        if COTMapObject.RECTANGLE_TYPES.contains(cotType) {
            return buildRectangle()
        } else if COTMapObject.CIRCLE_TYPES.contains(cotType) {
            return buildCircle()
        } else if COTMapObject.ELLIPSE_TYPES.contains(cotType) {
            return buildEllipse()
        } else if COTMapObject.LINE_TYPES.contains(cotType) {
            return buildPolyline()
        }
        return nil
    }
    
    init(mapPoint: COTData) {
        self.cotData = mapPoint
    }
}

class COTMapCircle: MKCircle {
    var major: Double = 0.0
    var minor: Double = 0.0
    var angle: Double = 0.0
    var strokeColor: Double = -1
    var strokeWeight: Double = -1
    var fillColor: Double = -1
    var labelsOn: Bool = true
}

// TODO: We'll need a custom renderer for this
// Rendering as a circle for now
class COTMapEllipse: MKCircle {
    var major: Double = 0.0
    var minor: Double = 0.0
    var angle: Double = 0.0
    var strokeColor: Double = -1
    var strokeWeight: Double = -1
    var fillColor: Double = -1
    var labelsOn: Bool = true
}

class COTMapPolygon: MKPolygon {
    var strokeColor: Double = -1
    var strokeWeight: Double = -1
    var fillColor: Double = -1
    var labelsOn: Bool = true
}

class COTMapPolyline: MKPolyline {
    var strokeColor: Double = -1
    var strokeWeight: Double = -1
    var fillColor: Double = -1
    var labelsOn: Bool = true
}

class COTMapBloodhoundLine: MKGeodesicPolyline {}

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
    dynamic var videoURL: URL?
    dynamic var shape: MKOverlay?
    
    var annotationIdentifier: String {
        if icon != nil && !icon!.isEmpty {
            return icon!
        }
        if cotType != nil && !cotType!.isEmpty {
            return cotType!
        }
        return "pli"
    }
    
    var isShape: Bool {
        shape != nil
    }
    
    init(mapPoint: COTData, shape: MKOverlay? = nil) {
        self.shape = shape
        self.id = mapPoint.id?.uuidString ?? UUID().uuidString
        self.title = mapPoint.callsign ?? "NO CALLSIGN"
        self.icon = mapPoint.icon ?? ""
        self.cotType = mapPoint.cotType ?? "a-U-G"
        self.coordinate = CLLocationCoordinate2D(latitude: mapPoint.latitude, longitude: mapPoint.longitude)
        if mapPoint.iconColor != nil
            && mapPoint.iconColor!.isNotEmpty
            && mapPoint.iconColor! != "-1" {
            self.color = IconData.colorFromArgb(argbVal: Int(mapPoint.iconColor!)!)
        }
        self.remarks = mapPoint.remarks
        self.videoURL = mapPoint.videoURL
    }
}

class SituationalAnnotationView: MKAnnotationView {
    var mapView: MapView
    var mapPointAnnotation: MapPointAnnotation
    let annotationLabel: UILabel = UILabel.init(frame:CGRect(x:0, y:-10, width:70, height:10))
    
    init(mapView: MapView, annotation: MapPointAnnotation, reuseIdentifier: String?) {
        self.mapView = mapView
        self.mapPointAnnotation = annotation
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.canShowCallout = true
        if annotation.shape == nil {
            setUpLabel()
        }
        setUpMenu()
    }
    
    func updateForAnnotation(annotation: MapPointAnnotation) {
        self.mapPointAnnotation = annotation
        if annotation.shape == nil {
            setUpLabel()
        }
        setUpMenu()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpLabel() {
        annotationLabel.text = mapPointAnnotation.title
        annotationLabel.backgroundColor = .black
        annotationLabel.textColor = .white
        annotationLabel.font = .systemFont(ofSize: 10)
        annotationLabel.lineBreakMode = .byTruncatingTail
        annotationLabel.sizeToFit()
        annotationLabel.preferredMaxLayoutWidth = 70
        let afterReframe = annotationLabel.frame
        let newWidth = (afterReframe.width > 70) ? 70 : afterReframe.width
        let xPos = -(newWidth/2) + 15
        annotationLabel.frame = CGRect(x: xPos, y: -10, width: newWidth, height: afterReframe.height)
        self.addSubview(annotationLabel)
    }
    
    private func setUpMenu() {
        let ICON_SIZE = 23.0
        let VERTICAL_SPACING = 5.0
        let HORIZONTAL_SPACING = 10.0
        let actionView = UIStackView()
        actionView.translatesAutoresizingMaskIntoConstraints = false
        actionView.distribution = .fillEqually
        actionView.axis = .horizontal
        actionView.spacing = HORIZONTAL_SPACING
        
        let bloodhoundImage = UIImage(named: "bloodhound")!
        let infoImage = UIImage(named: "details")!
        let trashImage = UIImage(named: "ic_menu_delete")!
        let videoImage = UIImage(named: "video")!
                
        let infoButton = UIButton.systemButton(with: infoImage, target: nil, action: nil)
        infoButton.addTarget(self, action: #selector(self.detailsPressed), for: .touchUpInside)
        infoButton.contentMode = .scaleAspectFit
        actionView.addArrangedSubview(infoButton)
        
        let bloodhoundButton = UIButton.systemButton(with: bloodhoundImage, target: nil, action: nil)
        bloodhoundButton.addTarget(self, action: #selector(self.bloodhoundPressed), for: .touchUpInside)
        bloodhoundButton.contentMode = .scaleAspectFit
        actionView.addArrangedSubview(bloodhoundButton)
        
        let deleteButton = UIButton.systemButton(with: trashImage, target: nil, action: nil)
        deleteButton.addTarget(self, action: #selector(self.deletePressed), for: .touchUpInside)
        deleteButton.contentMode = .scaleAspectFit
        actionView.addArrangedSubview(deleteButton)
        
        if(mapPointAnnotation.videoURL != nil) {
            //let videoButton = UIButton.systemButton(with: UIImage(systemName: "video.circle")!, target: nil, action: nil)
            let videoButton = UIButton.systemButton(with: videoImage, target: nil, action: nil)
            videoButton.addTarget(self, action: #selector(self.videoPressed), for: .touchUpInside)
            videoButton.contentMode = .scaleAspectFit
            actionView.addArrangedSubview(videoButton)
        }
        
        let widthConstraint = NSLayoutConstraint(item: actionView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: (ICON_SIZE+HORIZONTAL_SPACING) * CGFloat(actionView.arrangedSubviews.count))
        actionView.addConstraint(widthConstraint)
        
        let heightConstraint = NSLayoutConstraint(item: actionView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: (ICON_SIZE+VERTICAL_SPACING))
        actionView.addConstraint(heightConstraint)
        
        self.canShowCallout = true
        self.detailCalloutAccessoryView = actionView
    }
    
    @objc func videoPressed(sender: UIButton) {
        mapView.parentView.openVideoPlayer()
    }
    
    @objc func bloodhoundPressed(sender: UIButton) {
        mapView.createBloodhound(annotation: mapPointAnnotation)
    }
    
    @objc func deletePressed(sender: UIButton) {
        mapView.parentView.conflictedItems.removeAll(where: {$0.id == mapPointAnnotation.id})
        if(mapView.parentView.conflictedItems.isEmpty) {
            mapView.parentView.closeDeconflictionView()
        }
        if mapView.parentView.currentSelectedAnnotation?.shape != nil {
            mapView.mapView.removeOverlay(mapView.parentView.currentSelectedAnnotation!.shape!)
        }
        mapView.parentView.currentSelectedAnnotation = nil
        DispatchQueue.main.async {
            DataController.shared.deleteCot(cotId: self.mapPointAnnotation.id)
        }
    }
    
    @objc func detailsPressed(sender: UIButton) {
        mapView.parentView.openDetailView()
    }
}

class CompassMapView: MKMapView {
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    // TODO: Allow staying locked on user location
    // We effectively want a two or three stage option here
    // * If map is not centered on the user, center them *without zooming*
    //   (MapKit will auto-zoom as it decides when you set userTrackingMode)
    // * If map is centered on the user, lock on to their location
    //    Even if they move the map, snap back to their location when done moving
    // * If they are locked on to their location, unlock and stop tracking
    @objc func centerOnUser(sender: UIButton) {
        //self.setCenter(self.userLocation.coordinate, animated: true)
        self.userTrackingMode = .follow
    }
    
    lazy var centerOnUserButton: UIButton = {
        let largeTitle = UIImage.SymbolConfiguration(textStyle: .title1)
        let black = UIImage.SymbolConfiguration(weight: .medium)
        let combined = largeTitle.applying(black)
        
        var buttonConfig = UIButton.Configuration.borderless()
        if self.userTrackingMode == .none {
            buttonConfig.image = UIImage(systemName: "scope", withConfiguration: combined)?.withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
        } else {
            buttonConfig.image = UIImage(systemName: "lock.circle", withConfiguration: combined)?.withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
        }
        let centerOnUserButton = UIButton(configuration: buttonConfig)
        centerOnUserButton.addTarget(self, action: #selector(self.centerOnUser), for: .touchUpInside)
        addSubview(centerOnUserButton)
        return centerOnUserButton
    }()

    lazy var compassButton: MKCompassButton = {
        let compassView = MKCompassButton(mapView: self)
        compassView.isUserInteractionEnabled = true
        compassView.compassVisibility = .visible
        addSubview(compassView)
        return compassView
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        showsCompass = false
        let safeArea = self.safeAreaInsets
        var topPadding = safeArea.top + 10
        if topPadding == 10 { topPadding = 24 }
        let leftPadding = safeArea.left
        compassButton.frame = CGRect(
            origin: CGPoint(x: leftPadding + 24, y: topPadding),
            size: compassButton.bounds.size)
        centerOnUserButton.frame = CGRect(
            origin: CGPoint(x: leftPadding + 24, y: topPadding + 55.0),
            size: compassButton.bounds.size)
    }
}

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var mapType: UInt
    @Binding var enableTrafficDisplay: Bool
    @Binding var isAcquiringBloodhoundTarget: Bool
    @Binding var currentSelectedAnnotation: MapPointAnnotation?
    @Binding var conflictedItems: [MapPointAnnotation]
    var parentView: AwarenessView
    
    @State var mapView: CompassMapView = CompassMapView()
    @State var activeBloodhound: COTMapBloodhoundLine?
    @State var bloodhoundStartAnnotation: MapPointAnnotation?
    @State var bloodhoundEndAnnotation: MapPointAnnotation?
    @State var bloodhoundStartCoordinate: CLLocationCoordinate2D?
    @State var bloodhoundEndCoordinate: CLLocationCoordinate2D?
    @State var showingAnnotationLabels: Bool = true
    
    private static var mapPointsFetchRequest: NSFetchRequest<COTData> {
        let fetchUser: NSFetchRequest<COTData> = COTData.fetchRequest()
        fetchUser.sortDescriptors = []
        fetchUser.predicate = NSPredicate(format: "visible == YES")
        return fetchUser
    }
    
    @FetchRequest(fetchRequest: mapPointsFetchRequest)
    private var mapPointsData: FetchedResults<COTData>
    
    var shouldForceInitialTracking: Bool {
        return region.center.latitude == 0.0 || region.center.longitude == 0.0
    }

    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.setRegion(region, animated: true)
        mapView.setCenter(region.center, animated: true)
        mapView.showsUserLocation = true
        mapView.userTrackingMode = shouldForceInitialTracking ? .follow : .none
        mapView.showsCompass = false
        mapView.pointOfInterestFilter = .excludingAll
        mapView.mapType = MKMapType(rawValue: UInt(mapType))!
        mapView.layer.borderColor = UIColor.black.cgColor
        mapView.layer.borderWidth = 1.0
        mapView.isHidden = false
        mapView.showsTraffic = enableTrafficDisplay
        
        parentView.bloodhoundDeselectedCallback = bloodhoundDeselected
        parentView.annotationUpdatedCallback = annotationUpdatedCallback
        parentView.annotationSelectedCallback = annotationSelected(_:)

        didUpdateRegion()
        
//        let templateUrl = "https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}&s=Gal&apistyle=s.t:2|s.e:l|p.v:off"
//        //let templateUrl = "https://tile.openstreetmap.org/{z}/{x}/{y}.png?scale={scale}"
//        let googleHybridOverlay = MKTileOverlay(urlTemplate:templateUrl)
//        googleHybridOverlay.canReplaceMapContent = true
//        mapView.addOverlay(googleHybridOverlay, level: .aboveLabels)

        return mapView
    }
    
    func annotationUpdatedCallback(annotation: MapPointAnnotation) {
        guard let annotationView = mapView.view(for: annotation) else { return }
        prepareAnnotationView(annotation: annotation, annotationView: annotationView)
    }
    
    func prepareAnnotationView(annotation: MapPointAnnotation, annotationView: MKAnnotationView) {
        if annotation.shape == nil {
            let iconSetPath = annotation.icon ?? ""
            let icon = IconData.iconFor(type2525: annotation.cotType ?? "", iconsetPath: iconSetPath)
            var pointIcon: UIImage = icon.icon
            
            if let pointColor = annotation.color {
                if pointIcon.isSymbolImage {
                    pointIcon = pointIcon.maskSymbol(with: pointColor)
                } else {
                    pointIcon = pointIcon.maskImage(with: pointColor)
                }
            }
            annotationView.image = pointIcon
        } else {
            annotationView.image = nil
        }
        
        annotationView.annotation = annotation
        if let awarenessAnnotationView = annotationView as? SituationalAnnotationView {
            awarenessAnnotationView.updateForAnnotation(annotation: annotation)
        }
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        view.mapType = MKMapType(rawValue: UInt(mapType))!
        view.showsTraffic = enableTrafficDisplay
        updateAnnotations(from: view)
    }
    
    private func updateAnnotations(from mapView: MKMapView) {
        
        if(!isAcquiringBloodhoundTarget && activeBloodhound != nil) {
            mapView.removeOverlay(activeBloodhound!)
            DispatchQueue.main.async {
                activeBloodhound = nil
                bloodhoundStartCoordinate = nil
                bloodhoundEndCoordinate = nil
                bloodhoundEndAnnotation = nil
            }
        }
        
        let incomingData = mapPointsData
        
        let existingAnnotations = mapView.annotations.filter { $0 is MapPointAnnotation }
        let current = Set(existingAnnotations.map { ($0 as! MapPointAnnotation).id })
        let new = Set(incomingData.map { $0.id?.uuidString ?? "" }.filter { !$0.isEmpty })
        let toRemove = Array(current.symmetricDifference(new))
        let toAdd = Array(new.symmetricDifference(current))

        if !toRemove.isEmpty {
            let removableAnnotations = existingAnnotations.filter {
                toRemove.contains(($0 as! MapPointAnnotation).id)
            }

            if(bloodhoundEndAnnotation != nil && toRemove.contains(bloodhoundEndAnnotation!.id)) {
                bloodhoundDeselected()
            }
            
            let overlaysToRemove = removableAnnotations.map { ($0 as! MapPointAnnotation).shape }.filter { $0 != nil } as! [MKOverlay]
            mapView.removeOverlays(overlaysToRemove)
            
            mapView.removeAnnotations(removableAnnotations)
        }
        
        for annotation in mapView.annotations.filter({ $0 is MapPointAnnotation }) {
            guard let mpAnnotation = annotation as? MapPointAnnotation else { continue }
            guard let node = incomingData.first(where: {$0.id?.uuidString == mpAnnotation.id}) else { continue }
            let updatedMp = COTMapObject(mapPoint: node).annotation
            let willNeedIconUpdate = (mpAnnotation.cotType != updatedMp.cotType || mpAnnotation.icon != updatedMp.icon)
            mpAnnotation.title = updatedMp.title
            mpAnnotation.color = updatedMp.color
            mpAnnotation.icon = updatedMp.icon
            mpAnnotation.cotType = updatedMp.cotType
            mpAnnotation.coordinate = updatedMp.coordinate
            mpAnnotation.remarks = updatedMp.remarks
            if mpAnnotation.id == bloodhoundEndAnnotation?.id {
                let userLocation = mapView.userLocation.coordinate
                let endPointLocation = mpAnnotation.coordinate
                if(userLocation.latitude != bloodhoundStartCoordinate?.latitude ||
                   userLocation.longitude != bloodhoundStartCoordinate?.longitude ||
                   endPointLocation.latitude != bloodhoundEndCoordinate?.latitude ||
                   endPointLocation.longitude != bloodhoundEndCoordinate?.longitude
                ){
                    TAKLogger.debug("Bloodhound endpoint being updated! \(mpAnnotation.title!)")
                    DispatchQueue.main.async {
                        if(activeBloodhound != nil) {
                            TAKLogger.debug("[MapView] Removing old bloodhound line")
                            mapView.removeOverlay(activeBloodhound!)
                        } else {
                            TAKLogger.debug("[MapView] Updated Bloodhound line but no activeBloodhound")
                        }
                        createBloodhound(annotation: updatedMp)
                    }
                }
            }
            if willNeedIconUpdate {
                annotationUpdatedCallback(annotation: mpAnnotation)
            }
        }

        if !toAdd.isEmpty {
            let insertingAnnotations = incomingData.filter { toAdd.contains($0.id!.uuidString)}
            let newMapPoints = insertingAnnotations.map { COTMapObject(mapPoint: $0) }
            let newAnnotations = newMapPoints.map { $0.annotation }
            mapView.addAnnotations(newAnnotations)
            
            let newOverlays = newAnnotations.map { $0.shape }.filter { $0 != nil } as! [MKOverlay]
            mapView.addOverlays(newOverlays)
        }
    }
    
    func addMarker(at: CLLocationCoordinate2D) {
        DataController.shared.createMarker(latitude: at.latitude, longitude: at.longitude)
    }
    
    func resetMap() {
        mapView.userTrackingMode = .followWithHeading
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func createBloodhound(annotation: MapPointAnnotation) {
        isAcquiringBloodhoundTarget = true
        let userLocation = mapView.userLocation.coordinate
        let endPointLocation = annotation.coordinate
        parentView.bloodhoundEndPoint = annotation
        TAKLogger.debug("[MapView] Adding Bloodhound line to \(annotation.title!)")
        bloodhoundStartCoordinate = userLocation
        bloodhoundEndCoordinate = endPointLocation
        bloodhoundEndAnnotation = annotation
        if(activeBloodhound != nil) {
            let bloodhoundLines = mapView.overlays.filter { $0 is MKGeodesicPolyline }
            mapView.removeOverlays(bloodhoundLines)
        }
        activeBloodhound = COTMapBloodhoundLine(coordinates: [userLocation, endPointLocation], count: 2)
        mapView.addOverlay(activeBloodhound!, level: .aboveLabels)
        mapView.deselectAnnotation(annotation, animated: false)
    }
    
    func annotationSelected(_ annotation: MapPointAnnotation) {
        annotationSelected(mapView, annotation: annotation)
    }
    
    func bloodhoundDeselected() {
        if(activeBloodhound != nil) {
            let bloodhoundLines = mapView.overlays.filter { $0 is MKGeodesicPolyline }
            mapView.removeOverlays(bloodhoundLines)
            DispatchQueue.main.async {
                activeBloodhound = nil
                bloodhoundStartCoordinate = nil
                bloodhoundEndCoordinate = nil
                bloodhoundEndAnnotation = nil
                isAcquiringBloodhoundTarget = false
                parentView.bloodhoundEndPoint = nil
            }
        }
    }
    
    func annotationSelected(_ mapView: MKMapView, annotation: any MKAnnotation) {
        mapView.selectAnnotation(annotation, animated: false)
        guard let mpAnnotation = annotation as? MapPointAnnotation? else {
            TAKLogger.debug("[MapView] Unknown annotation type selected")
            return
        }
        TAKLogger.debug("[MapView] annotation selected")
        parentView.currentSelectedAnnotation = mpAnnotation
        
        let mapReadyForBloodhoundTarget = activeBloodhound == nil ||
        !mapView.overlays.contains(where: { $0.isEqual(activeBloodhound) })
        
        if(isAcquiringBloodhoundTarget &&
           mapReadyForBloodhoundTarget) {
            createBloodhound(annotation: mpAnnotation!)
        }
    }
    
    func initializeOrUpdateAnnotationView(mapView: MKMapView, annotation: MKAnnotation) -> MKAnnotationView? {
        guard !annotation.isKind(of: MKUserLocation.self) else {
            var selfView = mapView.dequeueReusableAnnotationView(withIdentifier: "UserLocation")
            if selfView == nil {
                selfView = MKUserLocationView(annotation: annotation, reuseIdentifier: "UserLocation")
            }
            selfView!.zPriority = .max
            return selfView
        }
        
        guard let mpAnnotation = annotation as? MapPointAnnotation else {
            TAKLogger.error("[MapView] Unknown Annotation present on map \(annotation.debugDescription ?? "")")
            return nil
        }
        
        let identifier = mpAnnotation.annotationIdentifier
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = SituationalAnnotationView(
                mapView: self,
                annotation: mpAnnotation,
                reuseIdentifier: identifier
            )
        }
        
        prepareAnnotationView(annotation: mpAnnotation, annotationView: annotationView!)
        return annotationView
    }
    
    func didUpdateTrackingMode() {
        let largeTitle = UIImage.SymbolConfiguration(textStyle: .title1)
        let black = UIImage.SymbolConfiguration(weight: .medium)
        let combined = largeTitle.applying(black)

        if(mapView.userTrackingMode == .none) {
            mapView.centerOnUserButton.setImage(UIImage(systemName: "scope", withConfiguration: combined)?.withTintColor(.systemYellow, renderingMode: .alwaysOriginal), for: .normal)
        } else {
            mapView.centerOnUserButton.setImage(UIImage(systemName: "lock.circle", withConfiguration: combined)?.withTintColor(.systemYellow, renderingMode: .alwaysOriginal), for: .normal)
        }
    }
    
    func didUpdateRegion() {
        let BORDER_POINT = 0.60
        let latDelta = mapView.region.span.latitudeDelta
        if latDelta > BORDER_POINT {
            DispatchQueue.main.async {
                showingAnnotationLabels = false
            }
            //mapView.annotations(in: mapView.visibleMapRect).forEach { annotation in
            mapView.annotations.forEach { annotation in
                if let mpAnnotation = annotation as? MapPointAnnotation {
                    (mapView.view(for: mpAnnotation) as? SituationalAnnotationView)?.annotationLabel.isHidden = true
                }
            }
        } else if latDelta <= BORDER_POINT {
            DispatchQueue.main.async {
                showingAnnotationLabels = true
            }
            mapView.annotations.forEach { annotation in
                if let mpAnnotation = annotation as? MapPointAnnotation {
                    (mapView.view(for: mpAnnotation) as? SituationalAnnotationView)?.annotationLabel.isHidden = false
                }
            }
        }
    }

    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: MapView

        var mapTapRecognizer = UITapGestureRecognizer()
        var longPressRecognizer = UILongPressGestureRecognizer()

        init(_ parent: MapView) {
            self.parent = parent
            super.init()
            self.mapTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapHandler))
            self.mapTapRecognizer.delegate = self
            self.parent.mapView.addGestureRecognizer(mapTapRecognizer)
            
            self.longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressHandler))
            self.longPressRecognizer.delegate = self
            self.parent.mapView.addGestureRecognizer(longPressRecognizer)
        }
        
        @objc func longPressHandler(_ gesture: UILongPressGestureRecognizer) {
            if gesture.state == .began {
                let impactHeavy = UINotificationFeedbackGenerator()
                impactHeavy.notificationOccurred(.success)
                let mapView = self.parent.mapView
                let location = mapTapRecognizer.location(in: mapView)
                let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
                let tappedLocation = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
                self.parent.addMarker(at: tappedLocation)
                TAKLogger.debug("[MapView] Map Long Pressed! \(String(describing: coordinate)), Lat: \(mapView.region.span.latitudeDelta), Lon: \(mapView.region.span.longitudeDelta)")
            }
        }

        @objc func tapHandler(_ gesture: UITapGestureRecognizer) {
            let mapView = self.parent.mapView
            // position on the screen, CGPoint
            let location = mapTapRecognizer.location(in: mapView)
            // position on the map, CLLocationCoordinate2D
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            let tappedLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            TAKLogger.debug("[MapView] Map Tapped! \(String(describing: coordinate)), Lat: \(mapView.region.span.latitudeDelta), Lon: \(mapView.region.span.longitudeDelta)")
            let tapRadius = 5000 * mapView.region.span.latitudeDelta
            let closeMarkers = mapView.annotations.filter { $0 is MapPointAnnotation && tappedLocation.distance(from: CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)) < tapRadius }
            TAKLogger.debug("[MapView] There are \(closeMarkers.count) markers within \(tapRadius) meters")
            if(closeMarkers.count > 1) {
                parent.conflictedItems = closeMarkers as! [MapPointAnnotation]
                parent.parentView.openDeconflictionView()
            } else if(closeMarkers.count == 1) {
                parent.parentView.closeDeconflictionView()
                parent.annotationSelected(mapView, annotation: closeMarkers.first!)
            } else if(parent.currentSelectedAnnotation != nil) {
                parent.parentView.closeDeconflictionView()
                mapView.deselectAnnotation(parent.currentSelectedAnnotation, animated: false)
                parent.currentSelectedAnnotation = nil
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.didUpdateRegion()
        }
        
        func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
            parent.didUpdateTrackingMode()
        }
        
        func mapView(_ mapView: MKMapView, didDeselect annotation: any MKAnnotation) {
            guard annotation is MapPointAnnotation? else {
                TAKLogger.debug("[MapView] Unknown annotation type selected")
                return
            }
            parent.currentSelectedAnnotation = nil
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            switch overlay {
            case let overlay as MKTileOverlay:
                return MKTileOverlayRenderer(tileOverlay: overlay)
            case let overlay as COTMapCircle:
                let circleRenderer = MKCircleRenderer(circle: overlay)
                circleRenderer.lineWidth = overlay.strokeWeight
                circleRenderer.strokeColor = IconData.colorFromArgb(argbVal: Int(overlay.strokeColor))
                circleRenderer.fillColor = IconData.colorFromArgb(argbVal: Int(overlay.fillColor))
                return circleRenderer
            case let overlay as COTMapEllipse:
                // TODO: Render as an ellipse, not a circle
                let circleRenderer = MKCircleRenderer(circle: overlay)
                circleRenderer.lineWidth = overlay.strokeWeight
                circleRenderer.strokeColor = IconData.colorFromArgb(argbVal: Int(overlay.strokeColor))
                circleRenderer.fillColor = IconData.colorFromArgb(argbVal: Int(overlay.fillColor))
                return circleRenderer
            case let overlay as COTMapPolygon:
                let renderer = MKPolygonRenderer(overlay: overlay)
                renderer.lineWidth = overlay.strokeWeight
                renderer.strokeColor = IconData.colorFromArgb(argbVal: Int(overlay.strokeColor))
                renderer.fillColor = IconData.colorFromArgb(argbVal: Int(overlay.fillColor))
                return renderer
            case let overlay as COTMapPolyline:
                let renderer = MKPolylineRenderer(polyline: overlay)
                renderer.lineWidth = overlay.strokeWeight
                renderer.strokeColor = IconData.colorFromArgb(argbVal: Int(overlay.strokeColor))
                renderer.fillColor = IconData.colorFromArgb(argbVal: Int(overlay.fillColor))
                return renderer
            case let overlay as COTMapBloodhoundLine:
                let renderer = MKPolylineRenderer(polyline: overlay)
                renderer.lineWidth = 3.0
                renderer.strokeColor = UIColor(red: 0.729, green: 0.969, blue: 0.2, alpha: 1) // #baf733
                return renderer
            case let overlay as MKGeodesicPolyline:
                let renderer = MKPolylineRenderer(polyline: overlay)
                renderer.lineWidth = 3.0
                renderer.strokeColor = UIColor(red: 0.729, green: 0.969, blue: 0.2, alpha: 1) // #baf733
                return renderer
            default:
                return MKOverlayRenderer()
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            return parent.initializeOrUpdateAnnotationView(mapView: mapView, annotation: annotation)
//            guard !annotation.isKind(of: MKUserLocation.self) else {
//                var selfView = mapView.dequeueReusableAnnotationView(withIdentifier: "UserLocation")
//                if selfView == nil {
//                    selfView = MKUserLocationView(annotation: annotation, reuseIdentifier: "UserLocation")
//                }
//                selfView!.zPriority = .max
//                return selfView
//            }
//            
//            guard let mpAnnotation = annotation as? MapPointAnnotation else { return nil }
//            
//            let identifier = mpAnnotation.annotationIdentifier
//            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
//            
//            if annotationView == nil {
//                annotationView = SituationalAnnotationView(
//                    mapView: parent,
//                    annotation: mpAnnotation,
//                    reuseIdentifier: identifier
//                )
//            }
//
//            let icon = IconData.iconFor(type2525: mpAnnotation.cotType ?? "", iconsetPath: mpAnnotation.icon ?? "")
//            var pointIcon: UIImage = icon.icon
//            
//            if let pointColor = mpAnnotation.color {
//                if pointIcon.isSymbolImage {
//                    pointIcon = pointIcon.maskSymbol(with: pointColor)
//                } else {
//                    pointIcon = pointIcon.maskImage(with: pointColor)
//                }
//            }
//            
//            annotationView!.image = pointIcon
//            annotationView!.annotation = mpAnnotation
//            return annotationView
        }
    }
}
