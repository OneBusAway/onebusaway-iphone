//
//  MapTableViewController.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 4/29/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit
import IGListKit
import SVProgressHUD
import PromiseKit

class MapTableViewController: UIViewController {

    // MARK: - IGListKit/Collection
    lazy var adapter: ListAdapter = {
        return ListAdapter(updater: ListAdapterUpdater(), viewController: self, workingRangeSize: 1)
    }()

    lazy var collectionViewLayout: UICollectionViewLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = CGSize(width: 375, height: 40)
        layout.itemSize = UICollectionViewFlowLayoutAutomaticSize
        return layout
    }()

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true

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
                performUpdates(animated: false)
            }
        }
    }

    var coordinateRegion: MKCoordinateRegion?
    var centerCoordinate: CLLocationCoordinate2D? {
        return coordinateRegion?.center
    }

    fileprivate let application: OBAApplication

    private var allowUIUpdates = false

    // MARK: - Service Alerts
    fileprivate var agencyAlerts: [AgencyAlert] = [] {
        didSet {
            performUpdates(animated: false)
        }
    }

    // MARK: - Weather
    var weatherForecast: WeatherForecast? {
        didSet {
            performUpdates(animated: false)
        }
    }

    // MARK: - Map Controller

    private lazy var mapContainer: UIView = {
        let view = UIView.init(frame: self.view.bounds)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = OBATheme.mapTableBackgroundColor
        return view
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

        super.init(nibName: nil, bundle: nil)

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
        view.addSubview(collectionView)
        adapter.collectionView = collectionView
        adapter.dataSource = self

        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)

        configureSearchUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshCurrentLocation()
        loadForecast()
        loadAlerts()

        allowUIUpdates = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        allowUIUpdates = false
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
        }.always {
            // nop?
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
        }.always {
            // nop?
        }
    }
}

// MARK: - Layout
extension MapTableViewController {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
    }
}

// MARK: - ListAdapterDataSource (Data Loading)
extension MapTableViewController: ListAdapterDataSource {

    private func performUpdates(animated: Bool) {
        if allowUIUpdates {
            adapter.performUpdates(animated: animated)
        }
    }

    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        guard application.isServerReachable else {
            return [GrabHandleSection(), OfflineSection(), Sweep(collectionViewBounds: view.bounds)]
        }

        var sections: [ListDiffable] = []

//        // Forecast
//        if let forecast = weatherForecast {
//            sections.append(forecast)
//        }
//
        // Grab Handle
        sections.append(GrabHandleSection())

        // Agency Alerts
        let filteredAlerts = agencyAlerts.filter { application.modelDao.isAlertUnread($0) }
        if filteredAlerts.count > 0 {
            let first = filteredAlerts[0]

            let viewModel = RegionalAlert(alertIdentifier: first.id, title: first.title(language: "en"), summary: first.body(language: "en"), url: first.url(language: "en"), date: first.startDate) { [weak self] _ in
                self?.application.modelDao.markAlert(asRead: first)
                self?.performUpdates(animated: true)
            }
            sections.append(viewModel)
        }

        // Bookmarks/Recents
        var nearbyItems = [StopViewModel]()
        nearbyItems.append(contentsOf: buildNearbyBookmarksViewModels(pick: 3))
        nearbyItems.append(contentsOf: buildNearbyRecentStopViewModels(pick: 3))

        if let center = self.centerCoordinate {
            nearbyItems.sort { (s1, s2) -> Bool in
                return OBAMapHelpers.getDistanceFrom(center, to: s1.coordinate) < OBAMapHelpers.getDistanceFrom(center, to: s2.coordinate)
            }
        }

        if nearbyItems.count > 0 {
            let headerText = NSLocalizedString("map_table.bookmarks_and_recent_stops_header", comment: "Header text for the Bookmarks and Recent Stops section of the map table")
            sections.append(SectionHeader(text: headerText))
            sections.append(contentsOf: nearbyItems)
        }

        // Nearby Stops

        if
            let stops = stops,
            stops.count > 0
        {
            sections.append(SectionHeader(text: NSLocalizedString("msg_nearby_stops", comment: "Nearby Stops text")))

            let stopViewModels: [StopViewModel] = Array(stops.prefix(5)).map {
                StopViewModel.init(name: $0.name, stopID: $0.stopId, direction: $0.direction, routeNames: $0.routeNamesAsString(), coordinate: $0.coordinate)
            }

            sections.append(contentsOf: stopViewModels)

            if let searchResult = application.mapDataLoader.result {
                let rowTitle = NSLocalizedString("map_table.more_nearby_stops", comment: "Title for the More Nearby Stops table row")
                let viewMoreRow = TableRowModel(title: rowTitle) { [weak self] in
                    guard let self = self else {
                        return
                    }
                    let nearby = NearbyStopsViewController(withSearchResult: searchResult)
                    nearby.presentedModally = true
                    let nav = UINavigationController(rootViewController: nearby)
                    self.present(nav, animated: true, completion: nil)
                }
                sections.append(viewMoreRow)
            }
        }
        else {
            sections.append(LoadingSection())
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
        case is GrabHandleSection: return GrabHandleSectionController()
        case is LoadingSection: return LoadingSectionController()
        case is OfflineSection: return OfflineSectionController()
        case is RegionalAlert: return RegionalAlertSectionController()
        case is SectionHeader: return SectionHeaderSectionController()
        case is StopViewModel: return StopSectionController()
        case is TableRowModel: return TableRowController()
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
            return StopViewModel(name: bookmark.name, stopID: bookmark.stopId, direction: nil, routeNames: routeNames, coordinate: bookmark.coordinate, image: UIImage(named: "Favorites"))
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
            StopViewModel(name: $0.title, stopID: $0.stopID, direction: nil, routeNames: $0.subtitle, coordinate: $0.coordinate, image: UIImage(named: "Recent"))
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

    func mapDataLoader(_ mapDataLoader: OBAMapDataLoader, startedUpdatingWith target: OBANavigationTarget) {
        // nop?
    }

    func mapDataLoaderFinishedUpdating(_ mapDataLoader: OBAMapDataLoader) {
        // nop?
    }
}

// MARK: - Map Region Delegate
extension MapTableViewController: OBAMapRegionDelegate {
    func mapRegionManager(_ manager: OBAMapRegionManager, setRegion region: MKCoordinateRegion, animated: Bool) {
        self.coordinateRegion = region
    }
}

// MARK: - Miscellaneous Public Methods
extension MapTableViewController {
    public func displayStop(withID stopID: String) {
        let stopController = StopViewController(stopID: stopID)

        guard let pulleyViewController = pulleyViewController else {
            navigationController?.pushViewController(stopController, animated: true)
            return
        }

        if application.userDefaults.bool(forKey: OBAUseStopDrawerDefaultsKey) {
            stopController.embedDelegate = self
            stopController.inEmbedMode = true
        }

        pulleyViewController.pushViewController(stopController, animated: true)
    }
}

// MARK: - Map Controller Delegate
extension MapTableViewController: MapControllerDelegate {
    func mapController(_ controller: OBAMapViewController, displayStopWithID stopID: String) {
        displayStop(withID: stopID)
    }

    func mapController(_ controller: OBAMapViewController, deselectedAnnotation annotation: MKAnnotation) {
        guard
            OBAApplication.shared().userDefaults.bool(forKey: OBAUseStopDrawerDefaultsKey),
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
        pulleyViewController?.pushViewController(viewController, animated: animated)
    }

    func embeddedStopControllerClosePane(_ stopController: StopViewController) {
        pulleyViewController?.popViewController(animated: true)
        // abxoxo
//        mapController.deselectSelectedAnnotationView()
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
        // abxoxo
        pulleyViewController?.definesPresentationContext = true
        pulleyViewController?.navigationItem.titleView = searchController.searchBar
        searchController.searchBar.sizeToFit()
    }

    func mapSearch(_ mapSearch: MapSearchViewController, selectedNavigationTarget target: OBANavigationTarget) {
        OBAAnalytics.reportEvent(withCategory: OBAAnalyticsCategoryUIAction, action: "button_press", label: "Search button clicked", value: nil)
        let analyticsLabel = "Search: \(NSStringFromOBASearchType(target.searchType) ?? "Unknown")"
        OBAAnalytics.reportEvent(withCategory: OBAAnalyticsCategoryUIAction, action: "button_press", label: analyticsLabel, value: nil)

        searchController.dismiss(animated: true) { [weak self] in
            guard let region: MKCoordinateRegion = self?.coordinateRegion else {
                return
            }
            let circularRegion = OBAMapHelpers.convertCoordinateRegion(toCircularRegion: region)

            // abxoxo - todo fixme - this is gross :-\
            self?.application.mapDataLoader.searchRegion = circularRegion
            let appDelegate = UIApplication.shared.delegate as! OBAApplicationDelegate
            appDelegate.navigate(to: target)
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

// MARK: - OBANavigationTargetAware
extension MapTableViewController: OBANavigationTargetAware, VehicleDisambiguationDelegate {
    func disambiguator(_ viewController: VehicleDisambiguationViewController, didSelect matchingVehicle: MatchingAgencyVehicle) {
        viewController.dismiss(animated: true) {
            SVProgressHUD.show()

            // abxoxo - here!
        }
//        [viewController dismissViewControllerAnimated:YES completion:^{
//            [SVProgressHUD show];
//
//            // abxoxo - todo - add this wrapper to a 'disposal bag' or something that can be cancelled
//            // if the user exits this view controller before this operation finishes.
//            PromiseWrapper *wrapper = [self.modelService requestVehicleTrip:matchingVehicle.vehicleID];
//            wrapper.anyPromise.then(^(NetworkResponse *response){
//            OBATripDetailsV2 *tripDetails = (OBATripDetailsV2 *)response.object;
//            OBAArrivalAndDepartureViewController *controller = [[OBAArrivalAndDepartureViewController alloc] initWithTripInstance:tripDetails.tripInstance];
//            [self pushViewController:controller animated:YES];
//            }).catch(^(NSError *error) {
//            [AlertPresenter showError:error presentingController:self];
//            }).always(^{
//            [SVProgressHUD dismiss];
//            });
//            }];
    }

    private func disambiguateMatchingVehicles(_ matchingVehicles: [MatchingAgencyVehicle]) {
        let disambiguator = VehicleDisambiguationViewController(with: matchingVehicles, delegate: self)
        let nav = UINavigationController(rootViewController: disambiguator)

        pulleyViewController?.present(nav, animated: true, completion: nil)
    }

    private func loadVehicleNavigationTarget(_ vehicleNavTarget: OBAVehicleIDNavigationTarget) {
//        guard let region = application.modelDao.currentRegion else {
//            // TODO: better error handling.
//            return
//        }
//        SVProgressHUD.show()

        // abxoxo - todo!

//        let wrapper = application.modelService.requestVehicles(matching: vehicleNavTarget.query, in: region)
//        wrapper.promise.then { [weak self] networkResponse /* -> Promise<NetworkResponse> */ in
//            let matchingVehicles = networkResponse.object as! [MatchingAgencyVehicle]
//
//            if
//                matchingVehicles.count == 1,
//                let first = matchingVehicles.first,
//                let modelService = self?.application.modelService
//            {
//                return modelService.requestVehicleTrip(first.vehicleID).anyPromise
//            }
//            else {
//                // pop up a disambiguation UI.
//                self?.disambiguateMatchingVehicles(matchingVehicles)
//                return AnyPromise.init(Promise<Void>())
//            }
//        }.then {
//
//        }

//        wrapper.anyPromise.then(^(NetworkResponse *response) {
//            NSArray<OBAMatchingAgencyVehicle*> *matchingVehicles = response.object;
//
//            if (matchingVehicles.count == 1) {
//                return [self.modelService requestVehicleTrip:matchingVehicles.firstObject.vehicleID].anyPromise;
//            }
//            else {
//                // pop up a disambiguation UI.
//                [self disambiguateMatchingVehicles:matchingVehicles];
//                return [AnyPromise promiseWithValue:nil];
//            }
//        }).then(^(NetworkResponse *response) {
//            if (response) {
//                OBATripDetailsV2 *tripDetails = (OBATripDetailsV2 *)response.object;
//                OBAArrivalAndDepartureViewController *controller = [[OBAArrivalAndDepartureViewController alloc] initWithTripInstance:tripDetails.tripInstance];
//                [self pushViewController:controller animated:YES];
//            }
//        }).catch(^(NSError *error) {
//            [AlertPresenter showError:error presentingController:self];
//        }).always(^{
//            [SVProgressHUD dismiss];
//        });
    }

    func setNavigationTarget(_ navigationTarget: OBANavigationTarget) {
        if navigationTarget.searchType == .region {
            application.mapDataLoader.searchPending()
            application.mapRegionManager.setRegionFrom(navigationTarget)
        }
        else if
            navigationTarget.searchType == .stopId,
            let stopID = navigationTarget.searchArgument as? String {
            displayStop(withID: stopID)
        }
        else if navigationTarget is OBAVehicleIDNavigationTarget {
            loadVehicleNavigationTarget(navigationTarget as! OBAVehicleIDNavigationTarget)
        }
        else {
            application.mapDataLoader.search(with: navigationTarget)
        }
    }
}
