//
//  MapView.swift
//  TAKAware
//
//  Created by Cory Foy on 7/27/24.
//

import CoreData
import CoreImage
import CoreImage.CIFilterBuiltins
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
        let ellipseNode = cotShape?.cotEllipse
        let major = ellipseNode?.major ?? 0.0
        let minor = ellipseNode?.minor ?? 0.0
        let angle = ellipseNode?.angle ?? 360
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
        let ellipseNode = cotShape?.cotEllipse
        let major = ellipseNode?.major ?? 0.0
        let minor = ellipseNode?.minor ?? 0.0
        let angle = ellipseNode?.angle ?? 360
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
        guard let rawXml = cotData.rawXml else {
            return nil
        }
        guard !rawXml.isEmpty else { return nil }

        self.cotEvent = COTXMLParser().parse(rawXml)
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
    var strokeColor: Int = -1
    var strokeWeight: Double = -1
    var fillColor: Int = -1
    var labelsOn: Bool = true
}

class COTMapEllipse: MKCircle {
    var major: Double = 0.0
    var minor: Double = 0.0
    var angle: Double = 0.0
    var strokeColor: Int = -1
    var strokeWeight: Double = -1
    var fillColor: Int = -1
    var labelsOn: Bool = true
}

class COTMapPolygon: MKPolygon {
    var strokeColor: Int = -1
    var strokeWeight: Double = -1
    var fillColor: Int = -1
    var labelsOn: Bool = true
}

class COTMapPolyline: MKPolyline {
    var strokeColor: Int = -1
    var strokeWeight: Double = -1
    var fillColor: Int = -1
    var labelsOn: Bool = true
}

class COTImageOverlay: NSObject, MKOverlay {
    var coordinate: CLLocationCoordinate2D
    var boundingMapRect: MKMapRect
    var overlayImage: UIImage
    var alpha: Double = 1.0
    var actualCoords: [MKMapPoint] = []
    var rotation: Double = 0.0
    
    init(image: UIImage, center: CLLocationCoordinate2D, boundingRect: MKMapRect) {
        coordinate = center
        boundingMapRect = boundingRect
        overlayImage = image
    }
}

class COTEllipseRenderer: MKOverlayRenderer {
    
    func degreesToRadians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let overlay = self.overlay as? COTMapEllipse else {
            return
        }

        let rect = self.rect(for: overlay.boundingMapRect)
        UIGraphicsPushContext(context)
        context.setLineWidth((overlay.strokeWeight/10) * MKRoadWidthAtZoomScale(zoomScale)) //
        
        context.setStrokeColor(IconData.colorFromArgb(argbVal: Int(overlay.strokeColor)).cgColor)
        
        let mapPointsPerMeter = MKMapPointsPerMeterAtLatitude(overlay.coordinate.latitude)
        let width = overlay.minor * mapPointsPerMeter
        let height = overlay.major * mapPointsPerMeter

        let y = (rect.height-height)/2
        let x = (rect.width-width)/2
        let finalRect = CGRectMake(x, y, width, height)

        context.translateBy(x: finalRect.midX, y: finalRect.midY)
        context.rotate(by: degreesToRadians(overlay.angle))
        context.translateBy(x: -finalRect.midX, y: -finalRect.midY)
        
        context.strokeEllipse(in: finalRect)
        UIGraphicsPopContext()
    }
}

class COTImageOverlayRenderer: MKOverlayRenderer {
    func degreesToRadians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let overlay = self.overlay as? COTImageOverlay else {
            return
        }

        var rect = self.rect(for: overlay.boundingMapRect)
        UIGraphicsPushContext(context)
        var img = overlay.overlayImage
        if !overlay.actualCoords.isEmpty {
            var ll = self.point(for: overlay.actualCoords[0])
            var lr = self.point(for: overlay.actualCoords[1])
            var ur = self.point(for: overlay.actualCoords[2])
            var ul = self.point(for: overlay.actualCoords[3])
            
            let minAdj = min(ul.x, ll.x, ur.x, lr.x)
            let xAdj = minAdj * -1 // At least one of the Xs needs to be at origin
            ll.x = ll.x-xAdj
            lr.x = lr.x-xAdj
            ur.x = ur.x-xAdj
            ul.x = ul.x-xAdj

            let ciImg = CIImage(image: img)
            let perspectiveTransformFilter = CIFilter.perspectiveTransform()
            perspectiveTransformFilter.inputImage = ciImg
            perspectiveTransformFilter.topRight = cartesianForPoint(point: ur, extent: rect)
            perspectiveTransformFilter.topLeft = cartesianForPoint(point: ul, extent: rect)
            perspectiveTransformFilter.bottomRight = cartesianForPoint(point: lr, extent: rect)
            perspectiveTransformFilter.bottomLeft = cartesianForPoint(point: ll, extent: rect)
            let txImg = perspectiveTransformFilter.outputImage!
            img = UIImage(ciImage: txImg)
            rect.origin = ul
        }

        if overlay.rotation != 0.0 {
            context.scaleBy(x: 1.0, y: -1.0)
            context.translateBy(x: 0.0, y: -rect.size.height)
            context.translateBy(x: rect.size.width / 2, y: rect.size.height / 2)
            context.rotate(by: degreesToRadians(overlay.rotation))
            context.translateBy(x: -rect.size.width / 2, y: -rect.size.height / 2)
            context.translateBy(x: 0.0, y: rect.size.height)
            context.scaleBy(x: 1.0, y: -1.0)
        }
        
        let alpha = overlay.alpha
        img.draw(in: rect, blendMode: .normal, alpha: alpha)
        UIGraphicsPopContext()
    }
    
    func cartesianForPoint(point:CGPoint, extent:CGRect) -> CGPoint {
        return CGPoint(x: point.x,y: extent.height - point.y)
    }
}

class COTMapBloodhoundLine: MKGeodesicPolyline {}

final class MapPointAnnotation: NSObject, MKAnnotation {
    var id: String
    dynamic var title: String?
    dynamic var subtitle: String?
    dynamic var coordinate: CLLocationCoordinate2D
    dynamic var altitude: Double? // In meters
    dynamic var icon: String?
    dynamic var cotType: String?
    dynamic var image: UIImage? = UIImage.init(systemName: "circle.fill")
    dynamic var color: UIColor?
    dynamic var remarks: String?
    dynamic var videoURL: URL?
    dynamic var shapes: [MKOverlay] = []
    dynamic var isKML: Bool = false
    dynamic var groupID: UUID?
    dynamic var kmlIcon: String?
    dynamic var role: String?
    dynamic var phone: String?
    
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
        !shapes.isEmpty
    }
    
    convenience init(mapPoint: COTData, shape: MKOverlay? = nil) {
        var shapes: [MKOverlay] = []
        if shape != nil {
            shapes.append(shape!)
        }
        self.init(mapPoint: mapPoint, shapes: shapes)
    }
    
    init(mapPoint: COTData, shapes: [MKOverlay]) {
        self.shapes = shapes
        self.id = mapPoint.id?.uuidString ?? UUID().uuidString
        self.title = mapPoint.callsign ?? "NO CALLSIGN"
        self.icon = mapPoint.icon ?? ""
        self.cotType = mapPoint.cotType ?? "a-U-G"
        self.coordinate = CLLocationCoordinate2D(latitude: mapPoint.latitude, longitude: mapPoint.longitude)
        self.altitude = mapPoint.altitude
        if mapPoint.iconColor != nil
            && mapPoint.iconColor!.isNotEmpty
            && mapPoint.iconColor! != "-1" {
            self.color = IconData.colorFromArgb(argbVal: Int(mapPoint.iconColor!)!)
        }
        if mapPoint.team != nil && !SettingsStore.global.enable2525ForRoles {
            self.color = IconData.colorForTeam(mapPoint.team!)
        }
        self.remarks = mapPoint.remarks
        self.videoURL = mapPoint.videoURL
        self.role = mapPoint.role
        self.phone = mapPoint.phone
    }
    
    init(id: String, title: String, icon: String, coordinate: CLLocationCoordinate2D, remarks: String) {
        self.id = id
        self.title = title
        self.cotType = "a-U-G"
        // TODO: We need to use the KMLIcon instead of this
        self.icon = IconData.DEFAULT_KML_ICON
        self.coordinate = coordinate
        self.remarks = remarks
        self.kmlIcon = icon
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
        if !annotation.isShape {
            setUpLabel()
        }
        setUpMenu()
    }
    
    func updateForAnnotation(annotation: MapPointAnnotation) {
        self.mapPointAnnotation = annotation
        if !annotation.isShape {
            setUpLabel()
        } else {
            annotationLabel.removeFromSuperview()
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
        let phoneImage = UIImage(systemName: "phone.fill")!
                
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
        
        if(mapPointAnnotation.phone != nil && !mapPointAnnotation.phone!.isEmpty) {
            let phoneButton = UIButton.systemButton(with: phoneImage, target: nil, action: nil)
            phoneButton.addTarget(self, action: #selector(self.makeCall), for: .touchUpInside)
            phoneButton.contentMode = .scaleAspectFit
            actionView.addArrangedSubview(phoneButton)
        }
        
        if(mapPointAnnotation.videoURL != nil) {
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
    
    // TODO: Do something meaningful on devices that can't make calls (like iPads)
    // TODO: Enable the menu to copy the number or send a text
    @objc func makeCall(sender: UIButton) {
        guard let phone = mapPointAnnotation.phone else {
            TAKLogger.error("[MapView] Attempted to make a phone call with no annotation / phone")
            return
        }
        if let telUrl = URL(string: "tel://\(phone)") {
            UIApplication.shared.open(telUrl, options: [:])
        }
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
        let removeShapes = mapView.parentView.currentSelectedAnnotation?.isShape ?? false
        if removeShapes {
            mapView.mapView.removeOverlays(mapView.parentView.currentSelectedAnnotation!.shapes)
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
    @Environment(\.scenePhase) var scenePhase
    @Binding var region: MKCoordinateRegion
    @Binding var mapType: UInt
    @Binding var enableTrafficDisplay: Bool
    @Binding var isAcquiringBloodhoundTarget: Bool
    @Binding var currentSelectedAnnotation: MapPointAnnotation?
    @Binding var conflictedItems: [MapPointAnnotation]
    var parentView: AwarenessView
    var dataContext = DataController.shared.backgroundContext
    
    @State var mapView: CompassMapView = CompassMapView()
    @State var activeBloodhound: COTMapBloodhoundLine?
    @State var bloodhoundStartAnnotation: MapPointAnnotation?
    @State var bloodhoundEndAnnotation: MapPointAnnotation?
    @State var bloodhoundStartCoordinate: CLLocationCoordinate2D?
    @State var bloodhoundEndCoordinate: CLLocationCoordinate2D?
    @State var showingAnnotationLabels: Bool = false
    @State var loadedKmlAnnotations: [String] = []
    @State var shouldUpdateMap: Bool = true
    @State var activeCustomMapOverlay: MKTileOverlay?
    
    private static var mapPointsFetchRequest: NSFetchRequest<COTData> {
        let fetchUser: NSFetchRequest<COTData> = COTData.fetchRequest()
        fetchUser.sortDescriptors = []
        fetchUser.predicate = NSPredicate(format: "visible = YES")
        return fetchUser
    }
    
    @FetchRequest(fetchRequest: mapPointsFetchRequest)
    private var mapPointsData: FetchedResults<COTData>
    
    private static var mapSourceFetchRequest: NSFetchRequest<MapSource> {
        let fetchSource: NSFetchRequest<MapSource> = MapSource.fetchRequest()
        fetchSource.sortDescriptors = []
        fetchSource.predicate = NSPredicate(format: "visible = YES")
        return fetchSource
    }
    
    @FetchRequest(fetchRequest: mapSourceFetchRequest)
    private var visibleMapSources: FetchedResults<MapSource>
    
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
        updateKmlOverlays()
        
        let nc = NotificationCenter.default
        
        nc.addObserver(forName: Notification.Name(AppConstants.NOTIFY_KML_FILE_ADDED), object: nil, queue: nil, using: kmlChangeNotified)
        nc.addObserver(forName: Notification.Name(AppConstants.NOTIFY_KML_FILE_UPDATED), object: nil, queue: nil, using: kmlChangeNotified)
        nc.addObserver(forName: Notification.Name(AppConstants.NOTIFY_KML_FILE_REMOVED), object: nil, queue: nil, using: kmlChangeNotified)
        nc.addObserver(forName: Notification.Name(AppConstants.NOTIFY_COT_ADDED), object: nil, queue: nil, using: cotChangeNotified)
        nc.addObserver(forName: Notification.Name(AppConstants.NOTIFY_COT_UPDATED), object: nil, queue: nil, using: cotChangeNotified)
        nc.addObserver(forName: Notification.Name(AppConstants.NOTIFY_COT_REMOVED), object: nil, queue: nil, using: cotChangeNotified)
        nc.addObserver(forName: Notification.Name(AppConstants.NOTIFY_SCROLL_TO_KML), object: nil, queue: nil, using: scrollToKml)
        nc.addObserver(forName: Notification.Name(AppConstants.NOTIFY_MAP_SOURCE_UPDATED), object: nil, queue: nil, using: mapSourceUpdatedCallback)
        
        overlayActiveMapSources()

        return mapView
    }
    
    private func overlayActiveMapSources() {
        TAKLogger.debug("[MapView] Updating active map sources overlays")
        if !visibleMapSources.isEmpty {
            let mapSource = visibleMapSources.first!
            if let sourceUrl = URLComponents(string: mapSource.url!)?.string?.removingPercentEncoding {
                TAKLogger.debug("[MapView] Active Custom Map Source located, activating")
                if activeCustomMapOverlay != nil {
                    TAKLogger.debug("[MapView] Clearing the existing custom map source")
                    mapView.removeOverlay(activeCustomMapOverlay!)
                }
                let cleanedFromGoogleUrl = sourceUrl.replacingOccurrences(of: "{$", with: "{")
                let mapSourceOverlay = MKTileOverlay(urlTemplate: cleanedFromGoogleUrl)
                mapSourceOverlay.canReplaceMapContent = true
                
                DispatchQueue.main.async {
                    // We need to force the background map to satellite (so no Apple Maps labels show)
                    // but we don't want to trigger the standard callback if we use SettingsStore
                    UserDefaults.standard.set(MKMapType.satellite.rawValue, forKey: "mapTypeDisplay")
                    
                    TAKLogger.debug("[MapView] Adding the map source overlay")
                    // Place Tile Overlays at the bottom
                    mapView.removeOverlays(mapView.overlays.filter({$0 is MKTileOverlay}))
                    mapView.insertOverlay(mapSourceOverlay, at: 0, level: .aboveRoads)
                    activeCustomMapOverlay = mapSourceOverlay
                }
                
            }
        } else {
            if activeCustomMapOverlay != nil {
                DispatchQueue.main.async {
                    TAKLogger.debug("[MapView] No custom map sources visible, clearing existing ones")
                    mapView.removeOverlays(mapView.overlays.filter({$0 is MKTileOverlay}))
                    activeCustomMapOverlay = nil
                }
            }
        }
    }
    
    private func mapSourceUpdatedCallback(notification: Notification) {
        TAKLogger.debug("[MapView] mapSourceUpdatedCallback received!")
        DispatchQueue.main.async {
            overlayActiveMapSources()
        }
    }
    
    func annotationUpdatedCallback(annotation: MapPointAnnotation) {
        guard let annotationView = mapView.view(for: annotation) else { return }
        Task {
            await prepareAnnotationView(annotation: annotation, annotationView: annotationView)
        }
    }
    
    // Note: This code is somewhat duplicated in IconImage
    func prepareAnnotationView(annotation: MapPointAnnotation, annotationView: MKAnnotationView) async {
        if !annotation.isShape {
            let icon = await IconData.iconFor(annotation: annotation)
            var pointIcon: UIImage = icon.icon
            
            if let pointColor = annotation.color {
                if icon.isCircularImage {
                    pointIcon = pointIcon.maskCircularImage(with: pointColor)
                } else if pointIcon.isSymbolImage {
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
    }
    
    private func appSceneChangeNotified(notification: Notification) {
        TAKLogger.debug("[MapView] Notified of an App Scene change \(notification.debugDescription)")
        if notification.name == Notification.Name(AppConstants.NOTIFY_APP_ACTIVE) {
            shouldUpdateMap = true
        } else {
            shouldUpdateMap = false
        }
    }
    
    private func kmlChangeNotified(notification: Notification) {
        TAKLogger.debug("[MapView] Notified of a KML change \(notification.debugDescription)")
        if shouldUpdateMap {
            updateKmlOverlays()
        }
    }
    
    private func cotChangeNotified(notification: Notification) {
        if shouldUpdateMap {
            DispatchQueue.main.async {
                updateAnnotations()
            }
        }
    }
    
    private func scrollToKml(notification: Notification) {
        guard let kmlId: UUID = notification.object as? UUID else {
            TAKLogger.debug("[MapView] Scroll to KML requested but no UUID provided")
            return
        }
        let kmlAnnotations: [MapPointAnnotation] = mapView.annotations.filter {
            ($0 as? MapPointAnnotation)?.groupID == kmlId
        } as! [MapPointAnnotation]
        if kmlAnnotations.isEmpty {
            TAKLogger.debug("[MapView] Scroll to KML requested but no annotations found to scroll to")
        } else {
            mapView.setCenter(kmlAnnotations.first!.coordinate, animated: true)
        }
    }
    
    private func updateKmlOverlays() {
        var processedKmlFiles: [String] = []
        
        dataContext.perform {
            let fetchKml: NSFetchRequest<KMLFile> = KMLFile.fetchRequest()
            fetchKml.predicate = NSPredicate(format: "visible = YES")
            let fetchedKml = try? dataContext.fetch(fetchKml)
            let incomingKml = (fetchedKml == nil) ? [] : fetchedKml!

            incomingKml.forEach { kmlRecord in
                guard let fileId = kmlRecord.id else {
                    TAKLogger.debug("[MapView] KMLRecord had no record ID")
                    return
                }
                processedKmlFiles.append(fileId.uuidString)
                
                if loadedKmlAnnotations.contains(fileId.uuidString) {
                    let existingAnnotations: [MapPointAnnotation] = mapView.annotations.filter {
                        ($0 as? MapPointAnnotation)?.groupID == fileId
                    } as! [MapPointAnnotation]
                    TAKLogger.debug("[MapView] Found \(existingAnnotations.count) existing annotations for this KML")
                    if !kmlRecord.visible {
                        let overlaysToRemove = Array(existingAnnotations.map { $0.shapes }.joined()) as! [MKOverlay]
                        TAKLogger.debug("[MapView] KML marked as not visible, removing \(existingAnnotations.count) annotations and \(overlaysToRemove.count) overlays")
                        DispatchQueue.main.async {
                            mapView.removeOverlays(overlaysToRemove)
                            mapView.removeAnnotations(existingAnnotations)
                        }
                        return
                    } else {
                        if !existingAnnotations.isEmpty {
                            TAKLogger.debug("[MapView] KML marked as visible, but annotations exist, so ignoring")
                            // We don't need to recreate them
                            return
                        }
                        TAKLogger.debug("[MapView] KML marked as visible, but no annotations exist. Continuing")
                    }
                }
                
                DispatchQueue.main.async {
                    loadedKmlAnnotations.append(fileId.uuidString)
                }
                
                if !kmlRecord.visible {
                    TAKLogger.debug("[MapView] KMLRecord marked as not visible. Skipping.")
                }
                
                let kmlData = KMLData(kmlRecord: kmlRecord)
                
                kmlData.placemarks.forEach { placemark in
                    guard !placemark.mapKitShapes.isEmpty else {
                        return
                    }
                    let mpa = MapPointAnnotation(id: UUID().uuidString, title: placemark.name, icon: "", coordinate: placemark.coordinate, remarks: placemark.description)
                    mpa.isKML = true
                    mpa.groupID = fileId
                    DispatchQueue.main.async {
                        mapView.addAnnotation(mpa)
                        mpa.shapes = placemark.mapKitShapes.compactMap { $0 as? MKOverlay }
                        mapView.addOverlays(mpa.shapes)
                        annotationUpdatedCallback(annotation: mpa)
                    }
                }
                
                kmlData.groundOverlays.forEach { groundOverlay in
                    guard let icon = groundOverlay.icon,
                          let iconBasePath = kmlData.iconBasePath
                    else {
                        TAKLogger.debug("[MapView] KML GroundOverlay has no icon. Skipping.")
                        return
                    }
                    
                    let latLongBox = groundOverlay.latLonBox
                    let latLongQuad = groundOverlay.latLonQuad
                    
                    if icon.href.hasPrefix("http") {
                        TAKLogger.debug("[MapView] KML GroundOverlay image is using http - skipping")
                        return
                    }
                    
                    var mapRect: MKMapRect? = nil
                    var actualCoords: [MKMapPoint] = []
                    
                    if latLongBox != nil {
                        let coordinates = groundOverlay.latLonBoxCoordinates
                        let northEast = MKMapPoint(coordinates.first!)
                        let southWest = MKMapPoint(coordinates.last!)
                        mapRect = MKMapRect(x: fmin(northEast.x,southWest.x), y: fmin(northEast.y,southWest.y), width: fabs(northEast.x-southWest.x), height: fabs(northEast.y-southWest.y))
                    } else if latLongQuad != nil {
                        let coordinateQuad = groundOverlay.latLonQuadCoordinates
                        if coordinateQuad.count < 4 {
                            TAKLogger.debug("[MapView] KML GroundOverlay has invalid LatLonQuad. Skipping.")
                            return
                        }

                        let ll = MKMapPoint(coordinateQuad[0])
                        let lr = MKMapPoint(coordinateQuad[1])
                        let ur = MKMapPoint(coordinateQuad[2])
                        let ul = MKMapPoint(coordinateQuad[3])
                        actualCoords = [ll, lr, ur, ul]

                        let maxWidth = max(ll.x, lr.x, ur.x, ul.x) - min(ll.x, lr.x, ur.x, ul.x)
                        let maxHeight = max(ll.y, lr.y, ur.y, ul.y) - min(ll.y, lr.y, ur.y, ul.y)
                        mapRect = MKMapRect(x: ul.x, y: ul.y, width: maxWidth, height: maxHeight);
                    } else {
                        TAKLogger.debug("[MapView] KML GroundOverlay has no LatLonBox or LatLonQuad. Skipping.")
                        return
                    }
                    
                    let imgUrl = iconBasePath.appendingPathComponent(icon.href)
                    let fileManager = FileManager()
                    if fileManager.fileExists(atPath: imgUrl.path(percentEncoded: false)) {
                        do {
                            let imgData = try Data(contentsOf: imgUrl)
                            let img = UIImage(data: imgData)!
                            
                            let imgOverlay = COTImageOverlay(image: img, center: mapRect!.origin.coordinate, boundingRect: mapRect!)
                            imgOverlay.actualCoords = actualCoords
                            imgOverlay.rotation = groundOverlay.latLonBox?.rotation ?? 0.0
                            let mpa = MapPointAnnotation(id: UUID().uuidString, title: kmlData.docTitle, icon: "", coordinate: mapRect!.origin.coordinate, remarks: kmlData.docDescription)
                            mpa.isKML = true
                            mpa.groupID = fileId
                            DispatchQueue.main.async {
                                mapView.addAnnotation(mpa)
                                mpa.shapes = [imgOverlay]
                                mapView.addOverlay(imgOverlay)
                                annotationUpdatedCallback(annotation: mpa)
                            }
                            
                        } catch {
                            TAKLogger.error("[MapView] Error loading KML GroundOverlay icon \(error)")
                        }
                    } else {
                        TAKLogger.debug("[MapView] KML GroundOverlay icon was not located at \(imgUrl.path())")
                    }
                }
            }
            
            let current = Set(loadedKmlAnnotations)
            let incoming = Set(processedKmlFiles)
            let toRemove = current.filter { !incoming.contains($0) }
            TAKLogger.debug("[MapView] Found \(toRemove.count) KMLs that need cleaned up")
            toRemove.forEach { fileId in
                let existingAnnotations: [MapPointAnnotation] = mapView.annotations.filter {
                    ($0 as? MapPointAnnotation)?.groupID?.uuidString == fileId
                } as! [MapPointAnnotation]
                let overlaysToRemove = Array(existingAnnotations.map { $0.shapes }.joined()) as! [MKOverlay]
                TAKLogger.debug("[MapView] Loaded KML file deleted. Removing \(existingAnnotations.count) annotations and \(overlaysToRemove.count) overlays")
                DispatchQueue.main.async {
                    mapView.removeOverlays(overlaysToRemove)
                    mapView.removeAnnotations(existingAnnotations)
                }
            }
        }
    }
    
    private func updateAnnotations() {
        let origUpdateVal = shouldUpdateMap
        shouldUpdateMap = false
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
                !($0 as! MapPointAnnotation).isKML &&
                toRemove.contains(($0 as! MapPointAnnotation).id)
            }
            
            if !removableAnnotations.isEmpty {
                if(bloodhoundEndAnnotation != nil && toRemove.contains(bloodhoundEndAnnotation!.id)) {
                    bloodhoundDeselected()
                }
                
                let overlaysToRemove = Array(removableAnnotations.map { ($0 as! MapPointAnnotation).shapes }.joined()) as! [MKOverlay]
                mapView.removeOverlays(overlaysToRemove)
                
                mapView.removeAnnotations(removableAnnotations)
            }
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
            let insertingAnnotations = incomingData.filter { toAdd.contains($0.id?.uuidString ?? "")}
            let newMapPoints = insertingAnnotations.map { COTMapObject(mapPoint: $0) }
            let newAnnotations = newMapPoints.map { $0.annotation }
            mapView.addAnnotations(newAnnotations)
            
            let newOverlays = Array(newAnnotations.map { $0.shapes }.joined()) as! [MKOverlay]
            mapView.addOverlays(newOverlays)
        }
        shouldUpdateMap = origUpdateVal
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
        
        Task {
            await prepareAnnotationView(annotation: mpAnnotation, annotationView: annotationView!)
        }
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
        
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            parent.updateAnnotations()
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
        
        func degreesToRadians(_ degrees: Double) -> Double {
            degrees * .pi / 180
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            switch overlay {
            case let overlay as OfflineTileOverlay:
                return TileOverlayRenderer(overlay: overlay)
            case let overlay as MKTileOverlay:
                return MKTileOverlayRenderer(tileOverlay: overlay)
            case let overlay as COTMapCircle:
                let circleRenderer = MKCircleRenderer(circle: overlay)
                circleRenderer.lineWidth = overlay.strokeWeight
                circleRenderer.strokeColor = IconData.colorFromArgb(argbVal: Int(overlay.strokeColor))
                if overlay.fillColor != -1 {
                    circleRenderer.fillColor = IconData.colorFromArgb(argbVal: Int(overlay.fillColor))
                }
                return circleRenderer
            case let overlay as COTMapEllipse:
                return COTEllipseRenderer(overlay: overlay)
            case let overlay as COTMapPolygon:
                let renderer = MKPolygonRenderer(overlay: overlay)
                renderer.lineWidth = overlay.strokeWeight
                renderer.strokeColor = IconData.colorFromArgb(argbVal: Int(overlay.strokeColor))
                if overlay.fillColor != -1 {
                    renderer.fillColor = IconData.colorFromArgb(argbVal: Int(overlay.fillColor))
                }
                return renderer
            case let overlay as COTMapPolyline:
                let renderer = MKPolylineRenderer(polyline: overlay)
                renderer.lineWidth = overlay.strokeWeight
                renderer.strokeColor = IconData.colorFromArgb(argbVal: Int(overlay.strokeColor))
                if overlay.fillColor != -1 {
                    renderer.fillColor = IconData.colorFromArgb(argbVal: Int(overlay.fillColor))
                }
                return renderer
            case let overlay as COTMapBloodhoundLine:
                let renderer = MKPolylineRenderer(polyline: overlay)
                renderer.lineWidth = 3.0
                renderer.strokeColor = UIColor(red: 0.729, green: 0.969, blue: 0.2, alpha: 1) // #baf733
                return renderer
            case let overlay as COTImageOverlay:
                return COTImageOverlayRenderer(overlay: overlay)
            case let overlay as MKGeodesicPolyline:
                let renderer = MKPolylineRenderer(polyline: overlay)
                renderer.lineWidth = 3.0
                renderer.strokeColor = UIColor(red: 0.729, green: 0.969, blue: 0.2, alpha: 1) // #baf733
                return renderer
            case let overlay as MKPolyline:
                let renderer = MKPolylineRenderer(polyline: overlay)
                renderer.lineWidth = 3.0
                renderer.strokeColor = UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1)
                return renderer
            case let overlay as MKPolygon:
                let renderer = MKPolygonRenderer(overlay: overlay)
                renderer.lineWidth = 1.0
                renderer.strokeColor = UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1)
                return renderer
            default:
                return MKOverlayRenderer()
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            return parent.initializeOrUpdateAnnotationView(mapView: mapView, annotation: annotation)
        }
    }
}
