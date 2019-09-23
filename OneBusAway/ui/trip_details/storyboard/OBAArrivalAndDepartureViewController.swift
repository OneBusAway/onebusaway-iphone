//
//  OBAArrivalAndDeparture.swift
//  OneBusAway
//
//  Created by Alan Chu on 9/21/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import UIKit
import OBAKit

public protocol OBAArrivalAndDepartureViewDelegate: class {
	var tripDetails: OBATripDetailsV2? { get }
	var arrivalAndDeparture: OBAArrivalAndDepartureV2? { get }
	var modelService: PromisedModelService { get }
	
	var vehicleMapViewIsExpanded: Bool { get set }
	
	func didSelectStop(_ stop: OBAStopV2)
	func didSelectTrip(_ trip: OBATripV2)
}

@objc(OBAArrivalAndDepartureView)
final public class OBAArrivalAndDepartureView: UIViewController, OBAArrivalAndDepartureViewDelegate, OBAVehicleMapDelegate {
	/// This enum compiler-guarentees that only one source of truth exists for this view at any given time.
	public enum DataSourceOfTruth {
		case arrivalAndDeparture(OBAArrivalAndDepartureV2)
		case tripInstance(OBATripInstanceRef)
		case convertible(OBAArrivalAndDepartureConvertible)
	}
	
	// MARK: - Data source
	public fileprivate(set) var sourceOfTruth: DataSourceOfTruth!
	
	public var tripDetails: OBATripDetailsV2?
	public var arrivalAndDeparture: OBAArrivalAndDepartureV2?
	public lazy var modelService: PromisedModelService = {
		return OBAApplication.shared().modelService!
	}()
	
	// MARK: - UI Elements
	var vehicleMapView: OBAVehicleMapController!
	var tripDetailsView: OBATripDetailsViewController!
	var scheduleView: OBATripScheduleTableViewController!
	
	public var vehicleMapViewIsExpanded: Bool {
		get {
			OBAApplication.shared().userDefaults.bool(forKey: OBAVehicleMapController.expandedStateUserDefaultsKey)
		} set {
			OBAApplication.shared().userDefaults.set(newValue, forKey: OBAVehicleMapController.expandedStateUserDefaultsKey)
		}
	}
	
	@IBOutlet var mapViewExpandedConstraint: NSLayoutConstraint!
	@IBOutlet var mapViewShrunkConstraint: NSLayoutConstraint!
	
	// MARK: - Initializers (helpers)
	/// Static initialize methods to interoperate with presenting controllers not originating from another storyboard.
	public static func create(dataSource: DataSourceOfTruth) -> OBAArrivalAndDepartureView {
		let view = UIStoryboard(name: "OBAArrivalAndDepartureViewController", bundle: nil).instantiateInitialViewController() as! OBAArrivalAndDepartureView
		
		view.sourceOfTruth = dataSource
		return view
	}
	
	// MARK: Objc-friendly initializers
	@objc public static func create(withArrivalAndDeparture arrivalAndDeparture: OBAArrivalAndDepartureV2) -> OBAArrivalAndDepartureView {
		return self.create(dataSource: .arrivalAndDeparture(arrivalAndDeparture))
	}
	
	@objc public static func create(withTripInstance tripInstance: OBATripInstanceRef) -> OBAArrivalAndDepartureView {
		return self.create(dataSource: .tripInstance(tripInstance))
	}
	
	@objc public static func create(withArrivalAndDepartureConvertible convertible: OBAArrivalAndDepartureConvertible) -> OBAArrivalAndDepartureView {
		return self.create(dataSource: .convertible(convertible))
	}
	
	// MARK: - UI Actions
	override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "EMBED_TO_MAPVIEW":
			self.vehicleMapView = (segue.destination as! OBAVehicleMapController)
			self.vehicleMapView.arrivalAndDepartureViewDelegate = self
			self.vehicleMapView.delegate = self
			
		case "EMBED_TO_TRIPDETAILS":
			self.tripDetailsView = (segue.destination as! OBATripDetailsViewController)
			self.tripDetailsView.arrivalAndDepartureViewDelegate = self
			
		case "EMBED_TO_SCHEDULE":
			self.scheduleView = (segue.destination as! OBATripScheduleTableViewController)
			self.scheduleView.arrivalAndDepartureViewDelegate = self
			
		default: break
		}
	}
	
	override public func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.reloadData()
	}
	
	public func didSelectStop(_ stop: OBAStopV2) {
		print("Selected stop: \(stop.nameWithDirection)")
	}
	
	public func didSelectTrip(_ trip: OBATripV2) {
		print("Selected trip: \(trip.tripShortName)")
		guard let tripInstance = self.arrivalAndDeparture?.tripInstance ?? self.tripDetails?.tripInstance else { return }
		let newTripInstance = tripInstance.copy(withNewTripId: trip.tripId)
		
		self.navigationController?.pushViewController(OBAArrivalAndDepartureView.create(withTripInstance: newTripInstance), animated: true)
	}
	
	// MARK: - Data Loading
	func reloadData(animated: Bool = true) {
		// Get relevant loading Promise
		// TODO: Make model service promises more swifty...
		let tripDetailsPromise: AnyPromise
		
		switch self.sourceOfTruth {
		case .tripInstance(let instance):
			tripDetailsPromise = self.modelService.requestTripDetails(tripInstance: instance).anyPromise
			
		case .arrivalAndDeparture(let arrivalAndDeparture):
			let tripInstancePromise = self.modelService.requestArrivalAndDeparture(arrivalAndDeparture.instance!).then {
				let arrivalAndDeparture = $0 as! OBAArrivalAndDepartureV2
				self.arrivalAndDeparture = arrivalAndDeparture
				return self.modelService.requestTripDetails(tripInstance: arrivalAndDeparture.tripInstance!).anyPromise
			}
			tripDetailsPromise = AnyPromise(tripInstancePromise)
			
		case .convertible(let convertible):
			let convertiblePromise = self.modelService.requestArrivalAndDeparture(with: convertible).then {
				let arrivalAndDeparture = $0 as! OBAArrivalAndDepartureV2
				self.arrivalAndDeparture = arrivalAndDeparture
				return self.modelService.requestTripDetails(tripInstance: arrivalAndDeparture.tripInstance!).anyPromise
			}
			tripDetailsPromise = AnyPromise(convertiblePromise)
			
		default: fatalError()
		}
		
		tripDetailsPromise.then { response -> Void in
			let networkResponse = response as! NetworkResponse
			let tripDetails = networkResponse.object as! OBATripDetailsV2
			self.tripDetails = tripDetails
			
			self.didLoadNewData()
		}.catch {
			AlertPresenter.showError($0 as NSError, presentingController: self)
		}.always {
			print("Hi")
		}
	}
	
	func didLoadNewData() {
		self.vehicleMapView.reloadData()
		self.scheduleView.reloadData()
		self.tripDetailsView.reloadData()
	}
	
	// MARK: - OBAVehicleMapDelegate methods
	func vehicleMapDidToggleSize(_ vehicleMap: OBAVehicleMapController) {
		print(vehicleMapViewIsExpanded)
		
		vehicleMapViewIsExpanded.toggle()
		
		print(vehicleMapViewIsExpanded)
		UIView.animate(withDuration: 0.25) {
			self.mapViewExpandedConstraint.priority = self.vehicleMapViewIsExpanded ? .defaultHigh : .defaultLow
			self.mapViewShrunkConstraint.priority = self.vehicleMapViewIsExpanded ? .defaultLow : .defaultHigh
			
			self.view.layoutIfNeeded()
		}
	}
	
	func vehicleMap(_ vehicleMap: OBAVehicleMapController, didSelect stop: OBAStopV2) {
		
	}
}
