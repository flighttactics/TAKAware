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
    
    static func typeToDescriptor(_ cotType: String) -> String {
        switch(cotType) {
        case "u-d-f":
            "Polygon"
        case "u-d-r":
            "Rectangle"
        case "u-d-c-c":
            "Circle"
        case "u-d-c-e":
            "Ellipse"
        case "b-m-r":
            "Line"
        default:
            "Unknown Shape"
        }
    }
    
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
        if isLine, let line = self.shape as? COTMapPolyline {
            let centerPoint = line.coordinate
            let mpa = MapPointAnnotation(mapPoint: cotData, shape: self.shape)
            mpa.coordinate = centerPoint
            return mpa
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

class MapPointAnnotation: NSObject, MKAnnotation {
    dynamic var id: String
    dynamic var dbObjectId: NSManagedObjectID?
    dynamic var cotUid: String
    dynamic var title: String?
    dynamic var subtitle: String?
    dynamic var coordinate: CLLocationCoordinate2D
    dynamic var altitude: Double? // In meters
    dynamic var speed: Double?
    dynamic var course: Double?
    dynamic var battery: Double?
    dynamic var icon: String?
    dynamic var cotType: String?
    dynamic var cotHow: String?
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
    dynamic var updateDate: Date?
    
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
        self.dbObjectId = mapPoint.objectID
        self.cotUid = mapPoint.cotUid ?? UUID().uuidString
        self.title = mapPoint.callsign ?? "NO CALLSIGN"
        self.icon = mapPoint.icon ?? ""
        self.cotType = mapPoint.cotType ?? "a-U-G"
        self.cotHow = mapPoint.cotHow ?? HowType.HumanGIGO.rawValue
        self.coordinate = CLLocationCoordinate2D(latitude: mapPoint.latitude, longitude: mapPoint.longitude)
        self.altitude = mapPoint.altitude
        self.speed = mapPoint.speed
        self.course = mapPoint.course
        self.battery = mapPoint.battery
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
        self.updateDate = mapPoint.updateDate
    }
    
    init(id: String, title: String, icon: String, coordinate: CLLocationCoordinate2D, remarks: String) {
        self.id = id
        self.cotUid = UUID().uuidString
        self.title = title
        self.cotType = "a-U-G"
        // TODO: We need to use the KMLIcon instead of this
        self.icon = IconData.DEFAULT_KML_ICON
        self.coordinate = coordinate
        self.remarks = remarks
        self.kmlIcon = icon
    }
    
    static func !=(lhs: MapPointAnnotation, rhs: MapPointAnnotation) -> Bool {
        return !(lhs == rhs)
    }
    
    static func ==(lhs: MapPointAnnotation, rhs: MapPointAnnotation) -> Bool {
        return lhs.id == rhs.id &&
        lhs.dbObjectId == rhs.dbObjectId &&
        lhs.cotUid == rhs.cotUid &&
        lhs.title == rhs.title &&
        lhs.subtitle == rhs.subtitle &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.altitude == rhs.altitude &&
        lhs.speed == rhs.speed &&
        lhs.course == rhs.course &&
        lhs.battery == rhs.battery &&
        lhs.icon == rhs.icon &&
        lhs.cotType == rhs.cotType &&
        lhs.image == rhs.image &&
        lhs.color == rhs.color &&
        lhs.remarks == rhs.remarks &&
        lhs.videoURL == rhs.videoURL &&
        lhs.groupID == rhs.groupID &&
        lhs.kmlIcon == rhs.kmlIcon &&
        lhs.role == rhs.role &&
        lhs.phone == rhs.phone &&
        lhs.updateDate == rhs.updateDate
    }
    
    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(id)
        hasher.combine(dbObjectId)
        hasher.combine(cotUid)
        return hasher.finalize()
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
        var newWidth = afterReframe.width
        if SettingsStore.global.mapLabelDisplayOption == .Truncate {
            newWidth = (afterReframe.width > 70) ? 70 : afterReframe.width
        }
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
    
    @objc func makeCall(sender: UIButton) {
        guard let phone = mapPointAnnotation.phone else {
            TAKLogger.error("[MapView] Attempted to make a phone call with no annotation / phone")
            return
        }
        NotificationCenter.default.post(name: Notification.Name(AppConstants.NOTIFY_PHONE_ACTION_REQUESTED), object: phone)
    }
    
    @objc func videoPressed(sender: UIButton) {
        mapView.parentView.openVideoPlayer()
    }
    
    @objc func bloodhoundPressed(sender: UIButton) {
        mapView.createBloodhound(annotation: mapPointAnnotation)
    }
    
    @objc func deletePressed(sender: UIButton) {
        mapView.deleteAnnotations([mapPointAnnotation])
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
    @Binding var conflictedItems: [MapPointAnnotation]
    @Binding var currentSelectedAnnotation: MapPointAnnotation?

    var parentView: AwarenessView
    var dataContext = DataController.shared.backgroundContext
    
    @State var mapView: CompassMapView = CompassMapView()
    @State var activeBloodhound: COTMapBloodhoundLine?
    @State var drawingLine: COTMapPolyline?
    @State var bloodhoundStartAnnotation: MapPointAnnotation?
    @State var bloodhoundEndAnnotation: MapPointAnnotation?
    @State var bloodhoundStartCoordinate: CLLocationCoordinate2D?
    @State var bloodhoundEndCoordinate: CLLocationCoordinate2D?
    @State var showingAnnotationLabels: Bool = false
    @State var loadedKmlAnnotations: [String] = []
    @State var shouldUpdateMap: Bool = true
    @State var activeCustomMapOverlay: MKTileOverlay?
    
    private static var mapSourceFetchRequest: NSFetchRequest<MapSource> {
        let fetchSource: NSFetchRequest<MapSource> = MapSource.fetchRequest()
        fetchSource.sortDescriptors = []
        fetchSource.predicate = NSPredicate(format: "visible = YES")
        return fetchSource
    }
    
    @FetchRequest(fetchRequest: mapSourceFetchRequest)
    private var visibleMapSources: FetchedResults<MapSource>
    
    @State private var fetchedResultsController: NSFetchedResultsController<COTData>!
    
    var shouldForceInitialTracking: Bool {
        return region.center.latitude == 0.0 || region.center.longitude == 0.0
    }
    
    func setupFetchedResultsController(context: Context) async {
        let fetchRequest: NSFetchRequest<COTData> = COTData.fetchRequest()
        fetchRequest.sortDescriptors = []
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: dataContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        fetchedResultsController.delegate = context.coordinator
        
        do {
            try await dataContext.perform {
                try fetchedResultsController.performFetch()
            }
        } catch {
            TAKLogger.error("[MapView] Failed to set up FRC: \(error)")
        }
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
        parentView.annotationsDeletedCallback = deleteAnnotations(_:)

        syncAnnotations()
        didUpdateRegion()
        updateKmlOverlays()
        Task {
            await setupFetchedResultsController(context: context)
        }
        
        let nc = NotificationCenter.default
        
        nc.addObserver(forName: Notification.Name(AppConstants.NOTIFY_KML_FILE_ADDED), object: nil, queue: nil, using: kmlChangeNotified)
        nc.addObserver(forName: Notification.Name(AppConstants.NOTIFY_KML_FILE_UPDATED), object: nil, queue: nil, using: kmlChangeNotified)
        nc.addObserver(forName: Notification.Name(AppConstants.NOTIFY_KML_FILE_REMOVED), object: nil, queue: nil, using: kmlChangeNotified)
        nc.addObserver(forName: Notification.Name(AppConstants.NOTIFY_SCROLL_TO_KML), object: nil, queue: nil, using: scrollToKml)
        nc.addObserver(forName: Notification.Name(AppConstants.NOTIFY_MAP_SOURCE_UPDATED), object: nil, queue: nil, using: mapSourceUpdatedCallback)
        nc.addObserver(forName: Notification.Name(AppConstants.NOTIFY_SCROLL_TO_COORDINATE), object: nil, queue: nil, using: scrollToCoordinate)
        nc.addObserver(forName: Notification.Name(AppConstants.NOTIFY_SCROLL_TO_CONTACT), object: nil, queue: nil, using: scrollToContact)
        
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

                let mapSourceOverlay = CacheableTileOverlay(urlTemplate: sourceUrl)
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
    
    func deleteAnnotations(_ annotations: [MapPointAnnotation]) {
        annotations.forEach { annotation in
            parentView.conflictedItems.removeAll(where: {$0.id == annotation.id})
            if(parentView.conflictedItems.isEmpty) {
                parentView.closeDeconflictionView()
            }
            if annotation.isShape {
                mapView.removeOverlays(annotation.shapes)
            }
            if annotation == currentSelectedAnnotation {
                currentSelectedAnnotation = nil
            }
            DispatchQueue.main.async {
                DataController.shared.deleteCot(cotId: annotation.id)
            }
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
            updateKmlOverlays()
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
    
    private func scrollToCoordinate(notification: Notification) {
        guard let coordinate: CLLocationCoordinate2D = notification.object as? CLLocationCoordinate2D else {
            TAKLogger.debug("[MapView] Scroll to Coordinate requested but no Coordinate provided")
            return
        }
        mapView.setCenter(coordinate, animated: true)
    }
    
    private func scrollToContact(notification: Notification) {
        guard let cotUid = notification.object as? String else {
            TAKLogger.debug("[MapView] Scroll to Contact requested but no ID provided")
            return
        }
        guard let contact = mapView.annotations.first(where: {
            ($0 as? MapPointAnnotation)?.cotUid == cotUid
        }) as? MapPointAnnotation else {
            TAKLogger.debug("[MapView] Scroll to Contact requested but no contact found")
            return
        }
        mapView.setCenter(contact.coordinate, animated: false)
        annotationSelected(mapView, annotation: contact)
    }
    
    private func updateKmlOverlays() {
        var processedKmlFiles: [String] = []
        
        dataContext.perform {
            let fetchKml: NSFetchRequest<KMLFile> = KMLFile.fetchRequest()
            fetchKml.predicate = NSPredicate(format: "visible = YES")
            let fetchedKml: [KMLFile]? = try? dataContext.fetch(fetchKml)
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
                        TAKLogger.debug("[MapView] KML GroundOverlay icon was not located at \(imgUrl.path(percentEncoded: false))")
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
    
    func removeMapAnnotation(dataRecord: COTData) {
        guard let existingAnnotation: MapPointAnnotation = annotationForDBId(dataRecord.objectID) else {
            TAKLogger.debug("[MapView] Attempted to delete an annotation that could not be found \(dataRecord.callsign ?? "NO CALLSIGN")")
            return
        }
        
        if(bloodhoundEndAnnotation == existingAnnotation) {
            bloodhoundDeselected()
        }
        
        DispatchQueue.main.async {
            mapView.removeOverlays(existingAnnotation.shapes)
            mapView.removeAnnotation(existingAnnotation)
        }
    }
    
    func updateMapAnnotation(dataRecord: COTData) {
        guard let existingAnnotation: MapPointAnnotation = annotationForDBId(dataRecord.objectID) else {
            addMapAnnotation(dataRecord: dataRecord)
            return
        }
        
        let updatedMp = COTMapObject(mapPoint: dataRecord).annotation
        guard existingAnnotation != updatedMp else {
            return
        }
        DispatchQueue.main.async {
            existingAnnotation.title = updatedMp.title
            existingAnnotation.color = updatedMp.color
            existingAnnotation.icon = updatedMp.icon
            existingAnnotation.cotType = updatedMp.cotType
            existingAnnotation.coordinate = updatedMp.coordinate
            existingAnnotation.remarks = updatedMp.remarks
            existingAnnotation.updateDate = updatedMp.updateDate
            existingAnnotation.battery = updatedMp.battery
            existingAnnotation.course = updatedMp.course
            existingAnnotation.speed = updatedMp.speed
            if existingAnnotation.id == bloodhoundEndAnnotation?.id {
                let userLocation = mapView.userLocation.coordinate
                let endPointLocation = existingAnnotation.coordinate
                if(userLocation.latitude != bloodhoundStartCoordinate?.latitude ||
                   userLocation.longitude != bloodhoundStartCoordinate?.longitude ||
                   endPointLocation.latitude != bloodhoundEndCoordinate?.latitude ||
                   endPointLocation.longitude != bloodhoundEndCoordinate?.longitude
                ){
                    TAKLogger.debug("Bloodhound endpoint being updated! \(existingAnnotation.title!)")
                    if(activeBloodhound != nil) {
                        TAKLogger.debug("[MapView] Removing old bloodhound line")
                        mapView.removeOverlay(activeBloodhound!)
                    } else {
                        TAKLogger.debug("[MapView] Updated Bloodhound line but no activeBloodhound")
                    }
                    createBloodhound(annotation: updatedMp)
                }
            }
            updateCurrentSelectedAnnotation(updatedMp: updatedMp)
            annotationUpdatedCallback(annotation: existingAnnotation)
        }
    }
    
    func addMapAnnotation(dataRecord: COTData) {
        guard dataRecord.cotUid != AppConstants.getClientID() else {
            TAKLogger.debug("[MapView] Attempted to add an annotation for the current user. Skipping.")
            return
        }
        guard annotationForDBId(dataRecord.objectID) == nil else {
            TAKLogger.debug("[MapView] Attempted to add an annotation that is already on the map (\(dataRecord.callsign ?? "NO TITLE")). Skipping.")
            return
        }
        let mpa = COTMapObject(mapPoint: dataRecord).annotation
        DispatchQueue.main.async {
            mapView.addAnnotation(mpa)
            mapView.addOverlays(mpa.shapes)
        }
    }
    
    func annotationForDBId(_ dbObjectId: NSManagedObjectID) -> MapPointAnnotation? {
        let existingAnnotation: MapPointAnnotation? = DispatchQueue.main.sync {
            mapView.annotations.first {
                $0 is MapPointAnnotation &&
                ($0 as! MapPointAnnotation).dbObjectId == dbObjectId
            } as? MapPointAnnotation
        }
        return existingAnnotation
    }
    
    func cleanBloodhoundLine() {
        if(!isAcquiringBloodhoundTarget && activeBloodhound != nil) {
            DispatchQueue.main.async {
                mapView.removeOverlay(activeBloodhound!)
                activeBloodhound = nil
                bloodhoundStartCoordinate = nil
                bloodhoundEndCoordinate = nil
                bloodhoundEndAnnotation = nil
            }
        }
    }
    
    private func syncAnnotations() {
        let context = DataController.shared.backgroundContext
        context.perform {
            cleanBloodhoundLine()
            let fetchData: NSFetchRequest<COTData> = COTData.fetchRequest()
            fetchData.predicate = NSPredicate(format: "visible = YES")

            let incomingData: [COTData] = (try? context.fetch(fetchData)) ?? []
            
            incomingData.forEach { dataRecord in addMapAnnotation(dataRecord: dataRecord) }
        }
    }
    
    func updateCurrentSelectedAnnotation(updatedMp: MapPointAnnotation) {
        if currentSelectedAnnotation != nil
            && currentSelectedAnnotation!.id == updatedMp.id {
            currentSelectedAnnotation = updatedMp
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
        currentSelectedAnnotation = mpAnnotation
        
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
    
    func didUpdateUserLocation() {
        let userLocation = mapView.userLocation.coordinate
        if(
            activeBloodhound != nil &&
            bloodhoundEndAnnotation != nil &&
            (userLocation.latitude != bloodhoundStartCoordinate?.latitude ||
           userLocation.longitude != bloodhoundStartCoordinate?.longitude)
        ){
            TAKLogger.debug("Bloodhound endpoint being updated due to user move")
            DispatchQueue.main.async {
                if(activeBloodhound != nil) {
                    TAKLogger.debug("[MapView] Removing old bloodhound line")
                    mapView.removeOverlay(activeBloodhound!)
                } else {
                    TAKLogger.debug("[MapView] Updated Bloodhound line but no activeBloodhound")
                }
                createBloodhound(annotation: bloodhoundEndAnnotation!)
            }
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
    
    // struct StrokeSample {
    //     let location: CGPoint
     
    //     init(location: CGPoint) {
    //         self.location = location
    //     }
    // }
    
    // @objc(MapTouchCaptureGesture)class MapTouchCaptureGesture: UIGestureRecognizer, NSCoding {
    //    var trackedTouch: UITouch? = nil
    //    var samples = [StrokeSample]()
     
    //    required init?(coder aDecoder: NSCoder) {
    //       super.init(target: nil, action: nil)
     
    //       self.samples = [StrokeSample]()
    //    }
       
    //     override init(target: Any?, action: Selector?) {
    //         super.init(target: target, action: action)
    //         self.samples = [StrokeSample]()
    //     }
        
    //    func encode(with aCoder: NSCoder) { }
        
    //     override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    //        if touches.count != 1 {
    //           self.state = .failed
    //        }
         
    //        // Capture the first touch and store some information about it.
    //        if self.trackedTouch == nil {
    //           if let firstTouch = touches.first {
    //              self.trackedTouch = firstTouch
    //              self.addSample(for: firstTouch)
    //              state = .began
    //           }
    //        } else {
    //           // Ignore all but the first touch.
    //           for touch in touches {
    //              if touch != self.trackedTouch {
    //                 self.ignore(touch, for: event)
    //              }
    //           }
    //        }
    //     }
         
    //     func addSample(for touch: UITouch) {
    //        let newSample = StrokeSample(location: touch.location(in: self.view))
    //        self.samples.append(newSample)
    //     }
       
    //     override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    //        self.addSample(for: touches.first!)
    //        state = .changed
    //     }
         
    //     override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    //        self.addSample(for: touches.first!)
    //        state = .ended
    //     }
        
    //     override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    //        self.samples.removeAll()
    //        state = .cancelled
    //     }
         
    //     override func reset() {
    //        self.samples.removeAll()
    //        self.trackedTouch = nil
    //     }
    // }

    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate {
        var parent: MapView

        var mapTapRecognizer = UITapGestureRecognizer()
        var longPressRecognizer = UILongPressGestureRecognizer()
        // var mapTouchCapture: MapTouchCaptureGesture = MapTouchCaptureGesture()

        init(_ parent: MapView) {
            self.parent = parent
            super.init()
            self.mapTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapHandler))
            self.mapTapRecognizer.delegate = self
            self.parent.mapView.addGestureRecognizer(mapTapRecognizer)
            
            self.longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressHandler))
            self.longPressRecognizer.delegate = self
            self.parent.mapView.addGestureRecognizer(longPressRecognizer)
            
//            self.mapTouchCapture = MapTouchCaptureGesture(target: self, action: #selector(mapTouchCaptureHandler))
//            self.mapTouchCapture.delegate = self
//            self.parent.mapView.addGestureRecognizer(mapTouchCapture)
        }
        
        // @objc func mapTouchCaptureHandler(_ gesture: MapTouchCaptureGesture) {
        //     // TODO: Used for either freeform drawings, or lassos
        //     if parent.parentView.isDrawing {
        //         if gesture.samples.count > 1 {
        //             let coords = gesture.samples.map { self.parent.mapView.convert($0.location, toCoordinateFrom: parent.mapView) }
        //             if parent.drawingLine != nil {
        //                 parent.mapView.removeOverlay(parent.drawingLine!)
        //             }
        //             parent.drawingLine = COTMapPolyline(coordinates: coords, count: coords.count)
        //             parent.mapView.addOverlay(parent.drawingLine!)
        //         }
        //     }
        // }
        
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

            if parent.parentView.isDrawing {
                TAKLogger.debug("[MapView] Draw Location Tapped! \(String(describing: coordinate)), Lat: \(mapView.region.span.latitudeDelta), Lon: \(mapView.region.span.longitudeDelta)")
                parent.parentView.drawingPoints.append(coordinate)
                if parent.parentView.drawingPoints.count > 1 {
                    if parent.drawingLine != nil {
                        mapView.removeOverlay(parent.drawingLine!)
                    }
                    parent.drawingLine = COTMapPolyline(coordinates: parent.parentView.drawingPoints, count: parent.parentView.drawingPoints.count)
                    mapView.addOverlay(parent.drawingLine!)
                }
            } else {
                if parent.drawingLine != nil {
                    mapView.removeOverlay(parent.drawingLine!)
                }
                TAKLogger.debug("[MapView] Map Tapped! \(String(describing: coordinate)), Lat: \(mapView.region.span.latitudeDelta), Lon: \(mapView.region.span.longitudeDelta)")
                let tapRadius = 5000 * mapView.region.span.latitudeDelta
                let closeMarkers: [MapPointAnnotation] = mapView.annotations.filter { $0 is MapPointAnnotation && tappedLocation.distance(from: CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)) < tapRadius } as? [MapPointAnnotation] ?? []
                TAKLogger.debug("[MapView] There are \(closeMarkers.count) markers within \(tapRadius) meters")
                if(closeMarkers.count > 1) {
                    parent.conflictedItems = closeMarkers
                    parent.parentView.openDeconflictionView()
                } else if(closeMarkers.count == 1) {
                    parent.parentView.closeDeconflictionView()
                    parent.annotationSelected(mapView, annotation: closeMarkers.first!)
                } else if(parent.currentSelectedAnnotation != nil) {
                    parent.parentView.closeDeconflictionView()
                    mapView.selectedAnnotations.forEach { sa in mapView.deselectAnnotation(sa, animated: false)}
                    parent.currentSelectedAnnotation = nil
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            parent.didUpdateUserLocation()
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
        
        func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
            guard let point = anObject as? COTData else {
                preconditionFailure("All changes observed in the map view controller should be for COTData instances")
            }
            let context = DataController.shared.backgroundContext
            context.perform {
                self.parent.cleanBloodhoundLine()
                switch type {
                case .insert:
                    self.parent.addMapAnnotation(dataRecord: point)
                case .delete:
                    self.parent.removeMapAnnotation(dataRecord: point)
                case .update:
                    self.parent.updateMapAnnotation(dataRecord: point)
                default:
                    TAKLogger.debug("[MapView] Unknown object update received")
                }
            }
        }
    }
}
