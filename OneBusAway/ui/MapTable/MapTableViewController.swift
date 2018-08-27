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
            if oldValue == nil && stops == [] {
                // nop.
            }
            else if oldValue == stops {
                // nop.
            }
            else {
                adapter.performUpdates(animated: false)
            }
        }
    }

    var centerCoordinate: CLLocationCoordinate2D?

    fileprivate let application: OBAApplication

    // MARK: - Service Alerts
    fileprivate var agencyAlerts: [AgencyAlert] = [] {
        didSet {
            adapter.performUpdates(animated: false)
        }
    }

    // MARK: - Weather
    var weatherForecast: WeatherForecast? {
        didSet {
            self.adapter.performUpdates(animated: false)
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

        self.mapController = OBAMapViewController(application: application)
        self.mapController.standaloneMode = false

        super.init(nibName: nil, bundle: nil)

        self.mapController.delegate = self

        self.application.mapDataLoader.add(self)
        self.application.mapRegionManager.add(delegate: self)

        self.title = NSLocalizedString("msg_map", comment: "Map tab title")
        self.tabBarItem.image = UIImage.init(named: "Map")
        self.tabBarItem.selectedImage = UIImage.init(named: "Map_Selected")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.application.mapDataLoader.cancelOpenConnections()
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshCurrentLocation()
        loadForecast()
        loadAlerts()
    }
}

// MARK: - Layout
extension MapTableViewController {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let tabBarHeight: CGFloat = 44.0
        mapContainer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height - tabBarHeight)

        collectionView.contentInset = UIEdgeInsets(top: view.bounds.height - Sweep.collectionViewContentInset, left: 0, bottom: 0, right: 0)
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

// MARK: - Regional Alerts
extension MapTableViewController {
    fileprivate func loadAlerts() {
        application.modelService.requestRegionalAlerts().then { (alerts: [AgencyAlert]) -> Void in
            let now = Date()
            self.agencyAlerts = alerts.filter { alert -> Bool in
                guard let end = alert.endDate else {
                    return false
                }
                return now < end
            }
        }.catch { err in
            DDLogError("Unable to retrieve agency alerts: \(err)")
        }
    }
}

// MARK: - Weather
extension MapTableViewController {
    fileprivate func loadForecast() {
        guard let region = application.modelDao.currentRegion else {
            return
        }

        let wrapper = application.modelService.requestWeather(in: region, location: self.application.locationManager.currentLocation)
        wrapper.promise.then { networkResponse -> Void in
            // swiftlint:disable force_cast
            let forecast = networkResponse.object as! WeatherForecast
            // swiftlint:enable force_cast
            self.weatherForecast = forecast
        }.catch { error in
            DDLogError("Unable to retrieve forecast: \(error)")
        }
    }
}

// MARK: - ListAdapterDataSource (Data Loading)
extension MapTableViewController: ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        guard application.isServerReachable else {
            return [OfflineSection(), Sweep(collectionViewBounds: view.bounds)]
        }

        guard pulleyViewController?.drawerPosition == .closed else {
            return []
        }

        var sections: [ListDiffable] = []

        // Forecast
        if let forecast = weatherForecast {
            sections.append(forecast)
        }

        // Agency Alerts
        if agencyAlerts.count > 0 {
            let first = agencyAlerts[0]
            let viewModel = RegionalAlert.init(alertIdentifier: first.id, title: first.title(language: "en"), summary: first.body(language: "en"), url: first.url(language: "en"))
            sections.append(viewModel)
        }

        // Bookmarks
        let nearbyBookmarks = buildNearbyBookmarksViewModels(pick: 2)
        if nearbyBookmarks.count > 0 {
            sections.append(SectionHeader(text: NSLocalizedString("msg_bookmarks", comment: "Bookmarks")))
            sections.append(contentsOf: nearbyBookmarks)
        }

        // Recent Stops
        let recentNearbyStops = buildNearbyRecentStopViewModels(pick: 2)
        if recentNearbyStops.count > 0 {
            sections.append(SectionHeader(text: NSLocalizedString("map_search.recent_stops_section_title", comment: "Recent Stops")))
            sections.append(contentsOf: recentNearbyStops)
        }

        // Nearby Stops

        if
            let stops = stops,
            stops.count > 0
        {
            sections.append(SectionHeader(text: NSLocalizedString("msg_nearby_stops", comment: "Nearby Stops text")))

            let stopViewModels: [StopViewModel] = Array(stops.prefix(3)).map {
                StopViewModel.init(name: $0.name, stopID: $0.stopId, direction: $0.direction, routeNames: $0.routeNamesAsString())
            }

            sections.append(contentsOf: stopViewModels)

            // Appending this on iOS 10 when there aren't any stop view models
            // was crashing the app. Therefore, we only append the Sweep when
            // there are stop view models to include, too.
            sections.append(Sweep(collectionViewBounds: view.bounds))
        }
        else {
            // abxoxo - this is crashing the app on iOS 10
//            sections.append(LoadingSection())
        }

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

        // handy utilities for debugging:
        //        default:
        //            return LabelSectionController()
        //        case is String: return LabelSectionController()
        }
    }

    private func buildNearbyBookmarksViewModels(pick upTo: Int = 2) -> [StopViewModel] {
        guard let centerCoordinate = centerCoordinate else {
            return []
        }

        let metersIn1Mile = 1609.34
        let nearbyBookmarks: [OBABookmarkV2] = application.modelDao.sortBookmarksByDistance(to: centerCoordinate, withDistance: metersIn1Mile)

        guard nearbyBookmarks.count > 0 else {
            return []
        }

        let viewModels: [StopViewModel] = nearbyBookmarks.map { bookmark in
            let routeNames = bookmark.routeWithHeadsign ?? String(format: NSLocalizedString("map_table.route_prefix", comment: "'Route: {TEXT}' prefix"), bookmark.routeShortName)
            return StopViewModel.init(name: bookmark.name, stopID: bookmark.stopId, direction: nil, routeNames: routeNames)
        }

        return Array(viewModels.prefix(upTo))
    }

    private func buildNearbyRecentStopViewModels(pick upTo: Int = 2) -> [StopViewModel] {
        guard let centerCoordinate = centerCoordinate else {
            return []
        }

        let nearbyRecentStops: [OBAStopAccessEventV2] = application.modelDao.recentStopsNearCoordinate(centerCoordinate)
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
        if let location = application.locationManager.currentLocation {
            if application.mapRegionManager.lastRegionChangeWasProgrammatic {
                let radius = max(location.horizontalAccuracy, OBAMinMapRadiusInMeters)
                let region = OBASphericalGeometryLibrary.createRegion(withCenter: location.coordinate, latRadius: radius, lonRadius: radius)
                application.mapRegionManager.setRegion(region, changeWasProgrammatic: true)
            }
        }
        else if let region = application.modelDao.currentRegion {
            let coordinateRegion = MKCoordinateRegionForMapRect(region.serviceRect)
            application.mapRegionManager.setRegion(coordinateRegion, changeWasProgrammatic: true)
        }
    }
}

// MARK: - Map Data Loader
extension MapTableViewController: OBAMapDataLoaderDelegate {
    func mapDataLoader(_ mapDataLoader: OBAMapDataLoader, didUpdate searchResult: OBASearchResult) {
        //swiftlint:disable force_cast
        let unsortedStops = searchResult.values.filter { $0 is OBAStopV2 } as! [OBAStopV2]
        stops = unsortedStops.sortByDistance(coordinate: centerCoordinate)
    }
}

// MARK: - Map Region Delegate
extension MapTableViewController: OBAMapRegionDelegate {
    func mapRegionManager(_ manager: OBAMapRegionManager, setRegion region: MKCoordinateRegion, animated: Bool) {
        self.centerCoordinate = region.center
    }
}

// MARK: - Map Controller Delegate
extension MapTableViewController: MapControllerDelegate {
    func mapController(_ controller: OBAMapViewController, displayStopWithID stopID: String) {
        let stopController = StopViewController.init(stopID: stopID)

        guard
            let pulleyViewController = pulleyViewController,
            application.userDefaults.bool(forKey: OBAUseStopDrawerDefaultsKey)
        else {
            navigationController?.pushViewController(stopController, animated: true)
            return
        }

        stopController.embedDelegate = self
        stopController.inEmbedMode = true

        pulleyViewController.setDrawerContentViewController(controller: stopController, animated: true)
        pulleyViewController.setDrawerPosition(position: .partiallyRevealed, animated: true)

        adapter.reloadData()
    }

    func mapController(_ controller: OBAMapViewController, deselectedAnnotation annotation: MKAnnotation) {
        guard
            let stop = annotation as? OBAStopV2,
            let nav = pulleyViewController?.drawerContentViewController as? UINavigationController,
            let stopController = nav.topViewController as? StopViewController
        else {
            return
        }

        if stopController.stopID == stop.stopId {
            pulleyViewController?.setDrawerPosition(position: .closed, animated: true)
        }
    }
}

// MARK: - EmbeddedStopDelegate
extension MapTableViewController: EmbeddedStopDelegate {
    func embeddedStop(_ stopController: StopViewController, push viewController: UIViewController, animated: Bool) {
        mapController.deselectSelectedAnnotationView()
        pulleyViewController?.setDrawerPosition(position: .closed, animated: true) { _ in
            self.navigationController?.pushViewController(viewController, animated: animated)
        }
    }

    func embeddedStopControllerClosePane(_ stopController: StopViewController) {
        mapController.deselectSelectedAnnotationView()
        pulleyViewController?.setDrawerPosition(position: .closed, animated: true) { _ in
            self.adapter.performUpdates(animated: false)
        }
    }

    func embeddedStopControllerBottomLayoutGuideLength() -> CGFloat {
        // TODO: figure out why tacking on an extra 20pt to the tab bar size fixes the underlap issue that we see otherwise.
        // is it because of the height of the status bar or something equally irritating?
        return bottomLayoutGuide.length + 20.0
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
        let analyticsLabel = "Search: \(NSStringFromOBASearchType(target.searchType) ?? "Unknown")"
        OBAAnalytics.reportEvent(withCategory: OBAAnalyticsCategoryUIAction, action: "button_press", label: analyticsLabel, value: nil)

        searchController.dismiss(animated: true) { [weak self] in
            if let visibleRegion = self?.mapController.visibleMapRegion {
                self?.application.mapDataLoader.searchRegion = visibleRegion
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

// MARK: - Miscellaneous Public Methods
extension MapTableViewController {
    public func recenterMap() {
        mapController.recenterMap()
    }
}

// MARK: - OBANavigationTargetAware
extension MapTableViewController: OBANavigationTargetAware {
    func setNavigationTarget(_ navigationTarget: OBANavigationTarget) {
        mapController.setNavigationTarget(navigationTarget)
    }
}
