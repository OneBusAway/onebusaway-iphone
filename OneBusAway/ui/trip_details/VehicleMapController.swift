//
//  VehicleMapController.swift
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/19/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

import MapKit
import OBAKit
import SnapKit
import UIKit

@objc protocol VehicleMapDelegate {
    func vehicleMap(_ vehicleMap: VehicleMapController, didToggleSize expanded: Bool)
    func vehicleMap(_ vehicleMap: VehicleMapController, didSelectStop annotation: MKAnnotation)
}

class VehicleMapController: UIViewController, MKMapViewDelegate {

    static let expandedStateUserDefaultsKey = "expandedStateUserDefaultsKey"
    public var expanded: Bool {
        didSet {
            UserDefaults.standard.set(expanded, forKey: VehicleMapController.expandedStateUserDefaultsKey)
            self.toggleButton.isSelected = expanded
        }
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.expanded = UserDefaults.standard.bool(forKey: VehicleMapController.expandedStateUserDefaultsKey)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var tripDetails: OBATripDetailsV2? {
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

    public var arrivalAndDeparture: OBAArrivalAndDepartureV2? {
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
    public var routeType: OBARouteType = .bus

    public weak var delegate: VehicleMapDelegate?

    lazy var modelService: OBAModelService = {
        return OBAApplication.shared().modelService
    }()

    var routePolyline: MKPolyline?

    lazy var routePolylineRenderer: MKPolylineRenderer = {
        let renderer = MKPolylineRenderer.init(polyline: self.routePolyline!)
        renderer.fillColor = UIColor.white
        renderer.strokeColor = UIColor.lightGray
        return renderer
    }()

    let mapView = MKMapView.init()

    var vehicleAnnotationView: SVPulsingAnnotationView?

    lazy var toggleButton: UIButton = {
        let button = OBAUIBuilder.borderedButton(with: UIColor.lightGray)
        button.contentEdgeInsets = OBATheme.defaultEdgeInsets()
        button.accessibilityLabel = NSLocalizedString("vehicle_map_controller.toggle_button_accessibility_label", comment: "An accessibility label for the map size toggle button on the Vehicle Map Controller.")
        button.imageView?.contentMode = .scaleAspectFit

        if let toggleImage = UIImage(named: "back") {
            button.setImage(OBAImageHelpers.rotateImage(toggleImage, degrees: -90.0), for: .normal)
            button.setImage(OBAImageHelpers.rotateImage(toggleImage, degrees: 90.0), for: .selected)
        }

        return button
    }()

    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()

        self.mapView.isRotateEnabled = false
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        self.view.addSubview(self.mapView)
        self.mapView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        let blurContainer = OBAVibrantBlurContainerView.init(frame: CGRect.zero)
        self.view.addSubview(blurContainer)
        blurContainer.snp.makeConstraints { (make) in
            make.width.equalTo(40)
            make.height.equalTo(30)
            make.right.bottom.equalToSuperview().offset(-OBATheme.defaultPadding())
        }

        blurContainer.vibrancyEffectView.addSubview(self.toggleButton)
        self.toggleButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.toggleButton.addTarget(self, action: #selector(toggleButtonTapped), for: .touchUpInside)
        self.toggleButton.isSelected = self.expanded
    }

    // MARK: - Data Loading

    func downloadRoutePolyline(shapeID: String) {
        self.modelService.requestShape(forID: shapeID).then { polyline -> Void in
            self.routePolyline = polyline as! MKPolyline?
            self.mapView.add(self.routePolyline!)
            self.mapView.setRegion(MKCoordinateRegionForMapRect(self.routePolyline!.boundingMapRect), animated: false)
        }.catch { error in
            // TODO: Handle error!
            DDLogError("Unable to render polyline on map: \(error)")
        }
    }

    // MARK: - Delegate

    func toggleButtonTapped() {
        self.expanded = !self.expanded
        self.delegate?.vehicleMap(self, didToggleSize: self.expanded)
    }

    // MARK: - MKMapViewDelegate

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
            color = OBATheme.userLocationFillColor()
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
            color = OBATheme.userLocationFillColor()
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
            annotationView?.annotationColor = OBATheme.obaDarkGreen()
            annotationView?.canShowCallout = true
            annotationView?.headingImage = UIImage(named: "vehicleHeading")
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
