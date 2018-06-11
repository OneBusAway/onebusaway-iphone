//
//  MapTableViewController.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 4/29/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit
import IGListKit
import MapKit

// https://stackoverflow.com/a/26299473
class PassthroughCollectionView: UICollectionView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let height = bounds.height + contentOffset.y
        let collectionBounds = CGRect.init(x: 0, y: 0, width: bounds.width, height: height)
        return collectionBounds.contains(point)
    }
}

class MapTableViewController: UIViewController {

    // MARK: - IGListKit/Collection
    lazy var adapter: ListAdapter = {
        return ListAdapter(updater: ListAdapterUpdater(), viewController: self, workingRangeSize: 1)
    }()

    let collectionView: PassthroughCollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = CGSize(width: 375, height: 40)
        let collectionView = PassthroughCollectionView(frame: .zero, collectionViewLayout: layout)
        return collectionView
    }()

    var stops: [OBAStopV2]? {
        didSet {
            adapter.performUpdates(animated: false)
        }
    }

    var centerCoordinate: CLLocationCoordinate2D?

    fileprivate let application: OBAApplication
    fileprivate let locationManager: OBALocationManager
    fileprivate let mapDataLoader: OBAMapDataLoader
    fileprivate let mapRegionManager: OBAMapRegionManager
    fileprivate let modelDAO: OBAModelDAO
    fileprivate let modelService: PromisedModelService

    // MARK: - Regional Alerts

    fileprivate let regionalAlertsManager: RegionalAlertsManager

    fileprivate var regionalAlerts: [OBARegionalAlert] {
        didSet {
            adapter.performUpdates(animated: true)
        }
    }

    // MARK: - Weather
    var weatherForecast: WeatherForecast? {
        didSet {
            self.adapter.performUpdates(animated: true, completion: nil)
        }
    }

    // MARK: - Map Controller

    private lazy var mapContainer: UIView = {
        let view = UIView.init(frame: self.view.bounds)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = OBATheme.mapTableBackgroundColor
        return view
    }()

    private var mapController: OBAMapViewController

    private lazy var bottomCover: UIView = {
        let cover = UIView()
        cover.isHidden = true
        cover.backgroundColor = OBATheme.mapTableBackgroundColor
        let coverHeight: CGFloat = 200
        cover.frame = CGRect(x: 0, y: mapContainer.frame.height - coverHeight, width: mapContainer.frame.width, height: coverHeight)
        return cover
    }()

    // MARK: - Search

    private lazy var mapSearchResultsController: MapSearchViewController = {
        let search = MapSearchViewController()
        search.delegate = self
        return search
    }()

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController.init(searchResultsController: mapSearchResultsController)
        searchController.delegate = self
        searchController.searchResultsUpdater = mapSearchResultsController
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false

        // Search Bar
        searchController.searchBar.returnKeyType = .done
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.delegate = self

        return searchController
    }()

    // MARK: - Init

    init(application: OBAApplication) {
        self.application = application
        locationManager = application.locationManager
        mapDataLoader = application.mapDataLoader
        mapRegionManager = application.mapRegionManager
        modelDAO = application.modelDao
        modelService = application.modelService
        regionalAlertsManager = application.regionalAlertsManager
        regionalAlerts = Array(regionalAlertsManager.regionalAlerts.prefix(3))

        self.mapController = OBAMapViewController.init(mapDataLoader: application.mapDataLoader, mapRegionManager: application.mapRegionManager)
        self.mapController.standaloneMode = false

        super.init(nibName: nil, bundle: nil)

        self.mapDataLoader.add(self)
        self.mapRegionManager.add(delegate: self)

        self.title = NSLocalizedString("msg_map", comment: "Map tab title")
        self.tabBarItem.image = UIImage.init(named: "Map")
        self.tabBarItem.selectedImage = UIImage.init(named: "Map_Selected")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.mapDataLoader.cancelOpenConnections()
    }
}

// MARK: - UIViewController
extension MapTableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // We're doing some hacky-spectrum stuff with our content insets
        // so we'll tell iOS to simply let us manage the insets without
        // any intervention.
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        else {
            automaticallyAdjustsScrollViewInsets = false
        }

        oba_addChildViewController(mapController, to: mapContainer)
        view.addSubview(mapContainer)

        view.addSubview(bottomCover)

        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true

        view.addSubview(collectionView)
        adapter.collectionView = collectionView
        adapter.dataSource = self
        adapter.scrollViewDelegate = self

        configureSearchUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        registerRegionalAlertNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        unregisterRegionalAlertNotifications()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshCurrentLocation()
        loadForecast()

        // abxoxo - DELETE ME!
        _ = modelService.requestRegionalAlerts()
    }
}

// MARK: - Layout
extension MapTableViewController {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let tabBarHeight:CGFloat = 44.0 // abxoxo - fix this for iPhone X.
        mapContainer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height - tabBarHeight)

        let abxoxoRandomConstant:CGFloat = 160.0 /// abxoxo - change this
        collectionView.contentInset = UIEdgeInsetsMake(view.bounds.height - abxoxoRandomConstant, 0, 0, 0)
        collectionView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
    }

    fileprivate var sweepHeight: CGFloat {
        return Sweep.defaultHeight(collectionViewBounds: view.bounds)
    }
}

// MARK: - UIScrollViewDelegate
extension MapTableViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentSize.height > 0 && scrollView.frame.height + scrollView.contentOffset.y >= scrollView.contentSize.height {
            bottomCover.isHidden = false
        }
        else {
            bottomCover.isHidden = true
        }
    }
}

// MARK: - Weather
extension MapTableViewController {
    fileprivate func loadForecast() {
        guard let region = modelDAO.currentRegion else {
            return
        }

        let wrapper = modelService.requestWeather(in: region, location: self.locationManager.currentLocation)
        wrapper.promise.then { networkResponse -> Void in
            let forecast = networkResponse.object as! WeatherForecast
            self.weatherForecast = forecast
        }.catch { error in
            DDLogError("Unable to retrieve regional alerts: \(error)")
        }
    }
}

// MARK: - Alerts
extension MapTableViewController {
    fileprivate func registerRegionalAlertNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(regionalAlertsUpdated(_:)), name: RegionalAlertsManager.regionalAlertsUpdatedNotification, object: nil)
    }

    fileprivate func unregisterRegionalAlertNotifications() {
        NotificationCenter.default.removeObserver(self, name: RegionalAlertsManager.regionalAlertsUpdatedNotification, object: nil)
    }

    @objc func regionalAlertsUpdated(_ note: Notification) {
        regionalAlerts = Array(regionalAlertsManager.regionalAlerts.filter { $0.publishedAt != nil }.prefix(3))
    }
}

// MARK: - ListAdapterDataSource
extension MapTableViewController: ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        guard application.isServerReachable else {
            return [OfflineSection(), Sweep(collectionViewBounds: view.bounds)]
        }

        var sections: [ListDiffable] = []

        // Forecast
        if let forecast = weatherForecast {
            sections.append(forecast)
        }

        // abxoxo: todo add horizontal scrolling and support more than one alert!
        let r = regionalAlerts

        if r.count > 0 {
            let first = r[0]
            let regionalAlertViewModel = RegionalAlert(alertIdentifier: "\(first.identifier)", title: first.title, summary: first.summary, url: first.url)
            sections.append(regionalAlertViewModel)
        }

        // Recent Stops
        let recentNearbyStops = buildNearbyRecentStopViewModels()
        if recentNearbyStops.count > 0 {
            sections.append(SectionHeader(text: NSLocalizedString("map_search.recent_stops_section_title", comment: "Recent Stops")))
            sections.append(contentsOf: recentNearbyStops)
        }

        // Nearby Stops

        if stops == nil {
            sections.append(LoadingSection())
        }
        else {
            sections.append(SectionHeader(text: NSLocalizedString("msg_nearby_stops", comment: "Nearby Stops text")))

            let stopViewModels: [StopViewModel] = stops!.map {
                StopViewModel.init(name: $0.name, stopID: $0.stopId, direction: $0.direction, routeNames: $0.routeNamesAsString())
            }
            sections.append(contentsOf: stopViewModels)
        }

        // Bottom Sweep

        sections.append(Sweep(collectionViewBounds: view.bounds))

        return sections
    }

    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        let sectionController = createSectionController(for: object)
        sectionController.inset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        return sectionController
    }

    func emptyView(for listAdapter: ListAdapter) -> UIView? { return nil }

    private func createSectionController(for object: Any) -> ListSectionController {
        switch object {
        case is LoadingSection: return LoadingSectionController()
        case is OfflineSection: return OfflineSectionController()
        case is RegionalAlert: return RegionalAlertSectionController()
        case is SectionHeader: return SectionHeaderSectionController()
        case is StopViewModel: return StopSectionController()
        case is Sweep: return BottomSweepSectionController()
        case is WeatherForecast: return ForecastSectionController()
        default:
            fatalError()
        }
    }

    private func buildNearbyRecentStopViewModels(pick upTo: Int = 2) -> [StopViewModel] {
        guard let centerCoordinate = centerCoordinate else {
            return []
        }

        let nearbyRecentStops: [OBAStopAccessEventV2] = modelDAO.recentStopsNearCoordinate(centerCoordinate)
        guard nearbyRecentStops.count > 0 else {
            return []
        }

        let viewModels: [StopViewModel] = nearbyRecentStops.map {
            StopViewModel.init(name: $0.title, stopID: $0.stopID, direction: nil, routeNames: $0.subtitle)
        }

        return Array(viewModels.prefix(upTo))
    }
}

// MARK: - Location Management
extension MapTableViewController {
    private func refreshCurrentLocation() {
        if let location = locationManager.currentLocation {
            if mapRegionManager.lastRegionChangeWasProgrammatic {
                let radius = max(location.horizontalAccuracy, OBAMinMapRadiusInMeters)
                let region = OBASphericalGeometryLibrary.createRegion(withCenter: location.coordinate, latRadius: radius, lonRadius: radius)
                mapRegionManager.setRegion(region, changeWasProgrammatic: true)
            }
        }
        else if let region = modelDAO.currentRegion {
            let coordinateRegion = MKCoordinateRegionForMapRect(region.serviceRect)
            mapRegionManager.setRegion(coordinateRegion, changeWasProgrammatic: true)
        }
    }
}

// MARK: - Map Data Loader
extension MapTableViewController: OBAMapDataLoaderDelegate {
    func mapDataLoader(_ mapDataLoader: OBAMapDataLoader, didUpdate searchResult: OBASearchResult) {
        let unsortedStops = searchResult.values.filter { $0 is OBAStopV2 } as! [OBAStopV2]
        stops = sort(stops: unsortedStops, byDistanceTo: centerCoordinate)
    }

    // TODO: DRY me up with identical function in NearbyStopsViewController
    fileprivate func sort(stops: [OBAStopV2], byDistanceTo coordinate: CLLocationCoordinate2D?) -> [OBAStopV2] {
        guard let coordinate = coordinate else {
            return stops
        }

        return stops.sorted { (s1, s2) -> Bool in
            let distance1 = OBAMapHelpers.getDistanceFrom(s1.coordinate, to: coordinate)
            let distance2 = OBAMapHelpers.getDistanceFrom(s2.coordinate, to: coordinate)
            return distance1 < distance2
        }
    }
}

// MARK: - Map Region Delegate
extension MapTableViewController: OBAMapRegionDelegate {
    func mapRegionManager(_ manager: OBAMapRegionManager, setRegion region: MKCoordinateRegion, animated: Bool) {
        self.centerCoordinate = region.center
    }
}

// MARK: - Search

extension MapTableViewController: MapSearchDelegate, UISearchControllerDelegate, UISearchBarDelegate {

    fileprivate func configureSearchUI() {
        definesPresentationContext = true
        navigationItem.titleView = searchController.searchBar
        searchController.searchBar.sizeToFit()
    }

    func mapSearch(_ mapSearch: MapSearchViewController, selectedNavigationTarget target: OBANavigationTarget) {
        OBAAnalytics.reportEvent(withCategory: OBAAnalyticsCategoryUIAction, action: "button_press", label: "Search button clicked", value: nil)

        // abxoxo - todo!
//        NSString *analyticsLabel = [NSString stringWithFormat:@"Search: %@", NSStringFromOBASearchType(target.searchType)];
//        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:analyticsLabel value:nil];

        searchController.dismiss(animated: true) { [weak self] in
            // abxoxo - TODO: figure out how to unify -navigateToTarget, this method, and -setNavigationTarget.
            // abxoxo this is ugly and janky. fix it.
            if let visibleRegion = self?.mapController.visibleMapRegion {
                self?.mapDataLoader.searchRegion = visibleRegion
                self?.mapController.setNavigationTarget(target)
            }
        }
    }

    func willPresentSearchController(_ searchController: UISearchController) {
        DispatchQueue.main.async {
            if let controller = searchController.searchResultsController {
                controller.view.isHidden = false
            }
        }
    }

    func didPresentSearchController(_ searchController: UISearchController) {
        if let controller = searchController.searchResultsController {
            controller.view.isHidden = false
        }
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        OBAAnalytics.reportEvent(withCategory: OBAAnalyticsCategoryUIAction, action: "button_press", label: "Search box selected", value: nil)
    }
}
