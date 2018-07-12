//
//  VehicleMapController.swift
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/19/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

import MapKit
import OBAKit

@objc protocol VehicleMapDelegate {
    func vehicleMap(_ vehicleMap: VehicleMapController, didToggleSize expanded: Bool)
    func vehicleMap(_ vehicleMap: VehicleMapController, didSelectStop annotation: MKAnnotation)
}

class VehicleMapController: UIViewController, MKMapViewDelegate {

    static let expandedStateUserDefaultsKey = "expandedStateUserDefaultsKey"
    @objc public var expanded: Bool {
        didSet {
            OBAApplication.shared().userDefaults.set(expanded, forKey: VehicleMapController.expandedStateUserDefaultsKey)
            self.toggleButton.isSelected = expanded
        }
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.expanded = OBAApplication.shared().userDefaults.bool(forKey: VehicleMapController.expandedStateUserDefaultsKey)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.promiseWrapper?.cancel()
    }

    @objc private var promiseWrapper: PromiseWrapper?

    @objc public var tripDetails: OBATripDetailsV2? {
        didSet {
            guard let tripDetails = self.tripDetails else {
                return
            }

            let annotations = self.tripDetails?.schedule.stopTimes.map {
                return OBATripStopTimeMapAnnotation.init(tripDetails: tripDetails, stopTime: $0)
            }

            self.mapView.addAnnotations(annotations!)
        }
    }

    @objc public var tripInstance: OBATripInstanceRef? {
        willSet {
            // TODO: there's no reason to remove all of the annotations every time
            // the tripInstance object is updated. This will just cause an
            // annoying flicker. However, it's easier than doing the right thing and
            // I just want to get this done for now. So someone please improve this!
            self.mapView.removeAnnotations(self.mapView.annotations)
        }
        didSet {
            if self.routePolyline != nil {
                return
            }

            guard let tripInstance = self.tripInstance else {
                return
            }

            let wrapper = self.modelService.requestTripDetails(tripInstance: tripInstance)
            wrapper.promise.then { resp -> Void in
                let tripDetails = resp.object as! OBATripDetailsV2
                self.tripDetails = tripDetails

                guard let shapeID = tripDetails.trip?.shapeId else {
                    return
                }

                self.downloadRoutePolyline(shapeID: shapeID)
            }

            self.promiseWrapper = wrapper
        }
    }

    @objc public var arrivalAndDeparture: OBAArrivalAndDepartureV2? {
        willSet {
            // TODO: there's no reason to remove all of the annotations every time
            // the ArrivalAndDeparture object is updated. This will just cause an
            // annoying flicker. However, it's easier than doing the right thing and
            // I just want to get this done for now. So someone please improve this!
            self.mapView.removeAnnotations(self.mapView.annotations)
        }
        didSet {
            // TODO: color this stop differently somehow.
            if let stop = self.arrivalAndDeparture?.stop {
                self.mapView.addAnnotation(stop)
            }

            if let tripStatus = self.arrivalAndDeparture?.tripStatus {
                self.mapView.addAnnotation(tripStatus)
            }

            if self.routePolyline == nil, let shapeID = self.arrivalAndDeparture?.trip?.shapeId {
                self.downloadRoutePolyline(shapeID: shapeID)
            }
        }
    }

    @objc public var routeType: OBARouteType = .bus

    @objc public weak var delegate: VehicleMapDelegate?

    lazy var modelService: PromisedModelService = {
        return OBAApplication.shared().modelService
    }()

    var routePolyline: MKPolyline?

    lazy var routePolylineRenderer: MKPolylineRenderer = {
        let renderer = MKPolylineRenderer.init(polyline: self.routePolyline!)
        renderer.strokeColor = OBATheme.obaGreen(withAlpha: 0.5)
        return renderer
    }()

    let mapView = MKMapView.init()

    var vehicleAnnotationView: SVPulsingAnnotationView?

    lazy var toggleButton: UIButton = {
        let button = UIButton()
        button.contentEdgeInsets = OBATheme.defaultEdgeInsets
        button.accessibilityLabel = NSLocalizedString("vehicle_map_controller.toggle_button_accessibility_label", comment: "An accessibility label for the map size toggle button on the Vehicle Map Controller.")
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(toggleButtonTapped), for: .touchUpInside)

        let toggleImage = #imageLiteral(resourceName: "back")
        button.setImage(OBAImageHelpers.rotateImage(toggleImage, degrees: -90.0), for: .normal)
        button.setImage(OBAImageHelpers.rotateImage(toggleImage, degrees: 90.0), for: .selected)

        button.isSelected = self.expanded

        return button
    }()
}

// MARK: - UIViewController
extension VehicleMapController {
    override func viewDidLoad() {
        super.viewDidLoad()

        self.createMapView()
        self.createHoverBar()
    }
}

// MARK: - Data Loading
extension VehicleMapController {
    func downloadRoutePolyline(shapeID: String) {
        self.modelService.requestShape(forID: shapeID).then { polyline -> Void in
            self.routePolyline = polyline as! MKPolyline?
            self.mapView.add(self.routePolyline!)
            self.mapView.setRegion(MKCoordinateRegionForMapRect(self.routePolyline!.boundingMapRect), animated: false)
        }.catch { error in
            DDLogError("Unable to render polyline on map: \(error)")
        }
    }
}

// MARK: - Actions
extension VehicleMapController {

    @objc func toggleButtonTapped() {
        self.expanded = !self.expanded
        self.delegate?.vehicleMap(self, didToggleSize: self.expanded)
    }
    
    @objc func recenterMap() {
        self.mapView.setUserTrackingMode(MKUserTrackingMode.follow, animated: true)
    }

}

// MARK: - MKMapViewDelegate
extension VehicleMapController {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return self.routePolylineRenderer
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else {
            return;
        }

        self.delegate?.vehicleMap(self, didSelectStop: annotation)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is OBAStopV2 {
            return self.stopAnnotation(stop: annotation as! OBAStopV2, mapView: mapView)
        }
        else if annotation is OBATripStatusV2 {
            self.vehicleAnnotationView = self.vehicleAnnotation(vehicle: annotation as! OBATripStatusV2, mapView: mapView)
            return self.vehicleAnnotationView
        }
        else if annotation is OBATripStopTimeMapAnnotation {
            return self.otherStopAnnotation(annotation as! OBATripStopTimeMapAnnotation, mapView: mapView)
        }
        else {
            return nil
        }
    }

    // TODO: DRY this up with stopAnnotation().
    func otherStopAnnotation(_ annotation: OBATripStopTimeMapAnnotation, mapView: MKMapView) -> MKAnnotationView? {
        let identifier = "stopAnnotation"

        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

        if annotationView == nil {
            annotationView = MKAnnotationView.init(annotation: annotation, reuseIdentifier: identifier)
        }

        var color: UIColor
        if self.arrivalAndDeparture?.stopId == annotation.stopID {
            color = OBATheme.userLocationFillColor
        }
        else {
            color = UIColor.lightGray
        }

        annotationView?.image = OBAImageHelpers.circleImage(with: CGSize.init(width: 12, height: 12), contents: nil, stroke: color)

        return annotationView
    }

    func stopAnnotation(stop: OBAStopV2, mapView: MKMapView) -> MKAnnotationView? {
        let identifier = "stopAnnotation"

        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

        if annotationView == nil {
            annotationView = MKAnnotationView.init(annotation: stop, reuseIdentifier: identifier)
        }

        var color: UIColor
        if self.arrivalAndDeparture?.stopId == stop.stopId {
            color = OBATheme.userLocationFillColor
        }
        else {
            color = UIColor.lightGray
        }

        annotationView?.image = OBAImageHelpers.circleImage(with: CGSize.init(width: 12, height: 12), contents: nil, stroke: color)

        return annotationView
    }

    func vehicleAnnotation(vehicle: OBATripStatusV2, mapView: MKMapView) -> SVPulsingAnnotationView? {
        let identifier = "vehicleAnnotation"

        var annotationView: SVPulsingAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? SVPulsingAnnotationView

        if annotationView == nil {
            annotationView = SVPulsingAnnotationView.init(annotation: vehicle, reuseIdentifier: identifier, size: CGSize(width: 32, height: 32))
            annotationView?.canShowCallout = true
            annotationView?.headingImage = UIImage(named: "vehicleHeading")
            annotationView?.isUserInteractionEnabled = false
        }

        if vehicle.predicted {
            annotationView?.annotationColor = OBATheme.obaDarkGreen
            annotationView?.delayBetweenPulseCycles = 0
        }
        else {
            annotationView?.annotationColor = UIColor.lightGray
            annotationView?.delayBetweenPulseCycles = Double.infinity
        }

        // n.b. The coordinate system that Core Graphics uses on iOS for transforms is backwards from what
        // you would normally expect, and backwards from what the OBA API vends. Long story short: instead
        // of generating *exactly backwards* data at the model layer, we'll just flip it here instead.
        // Long story short, negate your orientation in order to have it look right.
        annotationView?.headingImageView.transform = CGAffineTransform(rotationAngle: -vehicle.orientationInRadians)
        annotationView?.image = OBAStopIconFactory.image(for: self.routeType)

        return annotationView
    }
}

// MARK: - UI Configurations
extension VehicleMapController {
    func createMapView() {
        self.mapView.isRotateEnabled = false
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        self.view.addSubview(self.mapView)
        self.mapView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    func createHoverBar() {
        let hoverBar = ISHHoverBar()

        let toggleBarButton = UIBarButtonItem()
        toggleBarButton.customView = self.toggleButton

        let recenterMapButton = UIBarButtonItem(image: #imageLiteral(resourceName: "Map_Selected"), style: .plain, target: self, action: #selector(recenterMap))

        hoverBar.items = [recenterMapButton, toggleBarButton]
        self.view.addSubview(hoverBar)
        hoverBar.snp.makeConstraints { make in
            let insets = UIEdgeInsets(top: 0, left: 0, bottom: OBATheme.defaultPadding, right: OBATheme.defaultPadding)
            make.trailing.bottom.equalToSuperview().inset(insets)
        }
    }
}
