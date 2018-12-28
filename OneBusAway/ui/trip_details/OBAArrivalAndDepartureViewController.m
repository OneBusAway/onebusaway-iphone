//
//  OBAArrivalAndDepartureViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/18/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAArrivalAndDepartureViewController.h"
#import "OBAStaticTableViewController+Builders.h"
#import "OBAReportProblemWithTripViewController.h"
#import "OBASeparatorSectionView.h"
#import "OBATripScheduleSectionBuilder.h"
#import "OBAArrivalDepartureRow.h"
#import "UIViewController+OBAContainment.h"
#import "OneBusAway-Swift.h"
#import "OBATimelineBarRow.h"
#import "OBAPushManager.h"
#import "OBAArrivalDepartureOptionsSheet.h"
#import "UIViewController+OBAAdditions.h"
#import "EXTScope.h"
@import Masonry;
@import MarqueeLabel;
@import SVProgressHUD;
@import OBAKit;

static CGFloat const kCollapsedMapHeight = 225.f;
static CGFloat const kExpandedMapHeight = 350.f;

static NSTimeInterval const kRefreshTimeInterval = 30;

@interface OBAArrivalAndDepartureViewController ()<VehicleMapDelegate, OBAArrivalDepartureOptionsSheetDelegate>
@property(nonatomic,strong) OBAArrivalAndDepartureV2* arrivalAndDeparture;
@property(nonatomic,copy,nullable) OBATripInstanceRef *tripInstance;
@property(nonatomic,copy) id<OBAArrivalAndDepartureConvertible> convertible;

@property(nonatomic,strong) PromiseWrapper *promiseWrapper;

@property(nonatomic,strong) OBATripDetailsV2 *tripDetails;
@property(nonatomic,strong) UIView *tableHeaderView;
@property(nonatomic,strong) OBAClassicDepartureView *departureView;
@property(nonatomic,strong) NSTimer *refreshTimer;
@property(nonatomic,strong) NSLock *reloadLock;
@property(nonatomic,strong) UIStackView *stackView;

@property(nonatomic,strong) OBAVehicleMapController *mapController;

@property(nonatomic,strong) OBAStackedMarqueeLabels *titleLabels;

@property(nonatomic,strong) OBAArrivalDepartureOptionsSheet *departureSheetHelper;
@end

@implementation OBAArrivalAndDepartureViewController

- (instancetype)init {
    return [self initWithArrivalDeparture:nil tripInstance:nil convertible:nil];
}

- (instancetype)initWithArrivalDeparture:(nullable OBAArrivalAndDepartureV2*)arrivalDeparture tripInstance:(nullable OBATripInstanceRef*)tripInstance convertible:(nullable NSObject<OBAArrivalAndDepartureConvertible,NSCopying>*)convertible {
    self = [super init];

    if (self) {
        _arrivalAndDeparture = arrivalDeparture;
        _tripInstance = [tripInstance copy];
        _convertible = [convertible copy];

        _reloadLock = [[NSLock alloc] init];

        CGFloat titleViewWidth = 178.f;
        _titleLabels = [[OBAStackedMarqueeLabels alloc] initWithWidth:titleViewWidth];
        self.navigationItem.titleView = _titleLabels;

        [self updateTitleViewWithArrivalAndDeparture:_arrivalAndDeparture];
    }

    return self;
}

- (instancetype)initWithTripInstance:(OBATripInstanceRef *)tripInstance {
    return [self initWithArrivalDeparture:nil tripInstance:tripInstance convertible:nil];
}

- (instancetype)initWithArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    return [self initWithArrivalDeparture:arrivalAndDeparture tripInstance:nil convertible:nil];
}

- (instancetype)initWithArrivalAndDepartureConvertible:(NSObject<OBAArrivalAndDepartureConvertible,NSCopying>*)convertible {
    return [self initWithArrivalDeparture:nil tripInstance:nil convertible:convertible];
}

- (void)dealloc {
    [self.promiseWrapper cancel];
}

#pragma mark - View Controller

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadData:)];

    self.view.backgroundColor = [UIColor whiteColor];

    self.stackView = [[UIStackView alloc] initWithFrame:self.view.bounds];
    self.stackView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.stackView.axis = UILayoutConstraintAxisVertical;
    self.stackView.spacing = 0.f;
    
    self.mapController = [[OBAVehicleMapController alloc] initWithApplication:[OBAApplication sharedApplication]];
    self.mapController.delegate = self;
    [self oba_prepareChildViewController:self.mapController];
    [self.stackView addArrangedSubview:self.mapController.view];

    if (self.arrivalAndDeparture) {
        self.departureView = [[OBAClassicDepartureView alloc] initWithFrame:CGRectZero];
        self.departureView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.departureView.contextMenuButton addTarget:self action:@selector(showActionMenu:) forControlEvents:UIControlEventTouchUpInside];
        self.tableHeaderView = [self.class buildTableHeaderViewWrapperWithHeaderView:self.departureView];
        [self.stackView addArrangedSubview:self.tableHeaderView];
    }
    else {
        [self.stackView addArrangedSubview:OBAUIBuilder.lineView];
    }

    [self.tableView removeFromSuperview];
    [self.stackView addArrangedSubview:self.tableView];

    [self.view addSubview:self.stackView];
    [self.mapController didMoveToParentViewController:self];
    [self updateMapConstraints];

    // This will hide the map if the user launched this
    // view controller in landscape on an iPhone.
    [self updateMapVisibilityForTraitCollection:self.traitCollection];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    UIApplication.sharedApplication.idleTimerDisabled = YES;

    OBALogFunction();

    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:kRefreshTimeInterval target:self selector:@selector(reloadData:) userInfo:nil repeats:YES];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

    [self reloadDataAnimated:NO];
    
    OBATripDeepLink *deepLink = [[OBATripDeepLink alloc] initWithArrivalAndDeparture:self.arrivalAndDeparture region:self.modelDAO.currentRegion];
    self.userActivity = [OBAHandoff createUserActivityForTripWithName:self.arrivalAndDeparture.bestAvailableName URL:deepLink.deepLinkURL];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    UIApplication.sharedApplication.idleTimerDisabled = NO;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];

    [self cancelTimer];
}

#pragma mark - Traits

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];

    [self updateMapVisibilityForTraitCollection:newCollection];
}

#pragma mark - Action Menu

- (void)showActionMenu:(UIButton*)sender {
    OBADepartureRow *departureRow = self.departureView.departureRow;

    if (!departureRow) {
        return;
    }

    [self.departureSheetHelper showActionMenuForDepartureRow:departureRow fromPresentingView:sender];
}

#pragma mark - OBADepartureSheetDelegate

- (void)optionsSheet:(OBAArrivalDepartureOptionsSheet*)departureSheetHelpers presentViewController:(UIViewController*)viewController fromView:(nullable UIView *)presentingView {
    [self oba_presentViewController:viewController fromView:presentingView];
}

- (UIView*)optionsSheetPresentationView:(OBAArrivalDepartureOptionsSheet*)departureSheetHelpers {
    return self.view;
}

- (UIView*)optionsSheet:(OBAArrivalDepartureOptionsSheet*)optionsSheet viewForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    return self.departureView.contextMenuButton;
}

#pragma mark - Map/VehicleMapDelegate

- (void)updateMapVisibilityForTraitCollection:(UITraitCollection*)traitCollection {
    self.mapController.view.hidden = traitCollection.verticalSizeClass != UIUserInterfaceSizeClassRegular;
}

- (void)vehicleMap:(OBAVehicleMapController *)vehicleMap didToggleSize:(BOOL)expanded {
    [self updateMapConstraints];
    [OBAAnimation performAnimations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)vehicleMap:(OBAVehicleMapController *)vehicleMap didSelectStop:(id<MKAnnotation>)annotation {
    if (![annotation isKindOfClass:OBATripStopTimeMapAnnotation.class]) {
        return;
    }

    OBATripStopTimeMapAnnotation *stopTimeAnnotation = (OBATripStopTimeMapAnnotation*)annotation;
    NSIndexPath *indexPath = [self indexPathForModel:stopTimeAnnotation.stopTime];

    if (indexPath) {
        [UIView animateWithDuration:[UIView inheritedAnimationDuration] animations:^{
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        } completion:^(BOOL finished) {
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }];
    }
}

#pragma mark - UI Layout

- (void)updateMapConstraints {
    CGFloat mapHeight = self.mapController.expanded ? kExpandedMapHeight : kCollapsedMapHeight;
    [self.mapController.view mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view);
        make.height.equalTo(@(mapHeight));
    }];
}

#pragma mark - Notifications

- (void)willEnterForeground:(NSNotification*)note {

    // First, reload the table so that times adjust properly.
    [self.tableView reloadData];

    // And then reload remote data.
    [self reloadData:nil];
}

#pragma mark - Timer/Refresh Control

- (void)reloadData:(id)sender {
    [self reloadDataAnimated:YES];
}

- (void)cancelTimer {
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

#pragma mark - Lazily Loaded Accessors

- (OBAArrivalDepartureOptionsSheet*)departureSheetHelper {
    if (!_departureSheetHelper) {
        _departureSheetHelper = [[OBAArrivalDepartureOptionsSheet alloc] initWithDelegate:self];
    }

    return _departureSheetHelper;
}

- (OBAModelDAO*)modelDAO {
    if (!_modelDAO) {
        _modelDAO = [OBAApplication sharedApplication].modelDao;
    }
    return _modelDAO;
}

- (PromisedModelService*)modelService {
    if (!_modelService) {
        _modelService = [OBAApplication sharedApplication].modelService;
    }
    return _modelService;
}

#pragma mark - Data Loading

- (void)reloadDataAnimated:(BOOL)animated {
    // If we're already loading data, then just bail.
    if (![self.reloadLock tryLock]) {
        return;
    }

    AnyPromise *arrivalDeparturePromise = [self promiseArrivalDeparture];
    AnyPromise *tripDetailsPromise = nil;

    if (arrivalDeparturePromise) {
        tripDetailsPromise = arrivalDeparturePromise.then(^(OBAArrivalAndDepartureV2 *arrivalAndDeparture) {
            self.arrivalAndDeparture = arrivalAndDeparture;
            self.departureView.departureRow = [self createDepartureRow:arrivalAndDeparture];
            self.mapController.arrivalAndDeparture = self.arrivalAndDeparture;
            self.mapController.routeType = self.arrivalAndDeparture.stop.firstAvailableRouteTypeForStop;
            [self updateTitleViewWithArrivalAndDeparture:self.arrivalAndDeparture];

            self.promiseWrapper = [self.modelService requestTripDetailsWithTripInstance:self.arrivalAndDeparture.tripInstance];
            return self.promiseWrapper.anyPromise;
        });
    }
    else {
        self.mapController.tripInstance = self.tripInstance;
        self.promiseWrapper = [self.modelService requestTripDetailsWithTripInstance:self.tripInstance];
        tripDetailsPromise = self.promiseWrapper.anyPromise;
    }

    tripDetailsPromise.then(^(NetworkResponse *response) {
        OBATripDetailsV2 *tripDetails = response.object;
        self.tripDetails = tripDetails;
        self.mapController.tripDetails = tripDetails;
        [self populateTableWithArrivalAndDeparture:self.arrivalAndDeparture tripDetails:self.tripDetails];
    }).catch(^(NSError *error) {
        [AlertPresenter showError:error presentingController:self];
    }).always(^{
        [self.reloadLock unlock];
    });
}

- (nullable AnyPromise*)promiseArrivalDeparture {
    if (self.convertible) {
        return [self.modelService requestArrivalAndDepartureWithConvertible:self.convertible];
    }
    else if (self.arrivalAndDeparture) {
        return [self.modelService requestArrivalAndDeparture:self.arrivalAndDeparture.instance];
    }
    else {
        return nil;
    }
}

- (OBADepartureRow*)createDepartureRow:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    OBAArrivalAndDepartureSectionBuilder *builder = [[OBAArrivalAndDepartureSectionBuilder alloc] initWithModelDAO:self.modelDAO];
    OBADepartureRow *row = [builder createDepartureRowForStop:arrivalAndDeparture];

    @weakify(row);
    [row setShowAlertController:^(UIView *presentingView) {
        @strongify(row);
        [self.departureSheetHelper showActionMenuForDepartureRow:row fromPresentingView:presentingView];
    }];

    return row;
}

- (void)populateTableWithArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture tripDetails:(OBATripDetailsV2*)tripDetails {
    NSMutableArray *sections = [[NSMutableArray alloc] init];
    NSUInteger currentStopIndex = [OBATripScheduleSectionBuilder indexOfStopID:arrivalAndDeparture.stopId inSchedule:tripDetails.schedule];

    // Service Alerts Section
    OBATableSection *serviceAlertsSection = [self createServiceAlertsSection:arrivalAndDeparture];
    if (serviceAlertsSection) {
        [sections addObject:serviceAlertsSection];
    }

    // Stops Section
    OBATableSection *stopsSection = [OBATripScheduleSectionBuilder buildStopsSection:tripDetails arrivalAndDeparture:arrivalAndDeparture currentStopIndex:currentStopIndex navigationController:self.navigationController];
    [sections addObject:stopsSection];

    // Actions Section
    [sections addObject:[self.class createActionsSection:arrivalAndDeparture navigationController:self.navigationController]];

    self.sections = sections;
    [self.tableView reloadData];

    // Scroll the user's current stop to the top of the list
    if (currentStopIndex != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:currentStopIndex inSection:0];

        // only scroll if the indexPath actually exists...
        // but that does raise the question of how we'd end
        // up in a situation where that was not the case.
        if (self.sections.count > indexPath.section && self.sections[indexPath.section].rows.count > indexPath.row) {
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
        else {
            DDLogError(@"%s: We really shouldn't end up here...", __PRETTY_FUNCTION__);
        }
    }
}

- (void)updateTitleViewWithArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    if (arrivalAndDeparture.tripStatus.vehicleId.length > 0) {
        self.titleLabels.topLabel.text = arrivalAndDeparture.tripStatus.vehicleId;
    }
    else {
        self.titleLabels.topLabel.text = @"";
    }

    NSMutableArray *bottomLabelParts = [NSMutableArray new];

    if (arrivalAndDeparture.tripStatus.lastUpdateTime != 0) {
        NSString *timeString = [OBADateHelpers formatShortTimeNoDate:arrivalAndDeparture.tripStatus.lastUpdateDate];
        [bottomLabelParts addObject:[NSString stringWithFormat:NSLocalizedString(@"arrival_departure_controller.last_report", @"Last report: <TIME>"), timeString]];
    }

    if (arrivalAndDeparture.tripStatus.scheduleDeviation != 0) {
        [bottomLabelParts addObject:arrivalAndDeparture.tripStatus.formattedScheduleDeviation];
    }

    self.titleLabels.bottomLabel.text = [bottomLabelParts componentsJoinedByString:@" • "];
}

#pragma mark - Context Menu Actions

- (void)toggleBookmarkActionForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)dep {
    if ([self.modelDAO bookmarkForArrivalAndDeparture:dep]) {
        [self.departureSheetHelper presentAlertToRemoveBookmarkForArrivalAndDeparture:dep];
    }
    else {
        OBABookmarkV2 *bookmark = [[OBABookmarkV2 alloc] initWithArrivalAndDeparture:dep region:self.modelDAO.currentRegion];
        OBAEditBookmarkViewController *bookmarkViewController = [[OBAEditBookmarkViewController alloc] initWithBookmark:bookmark modelDAO:self.modelDAO];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:bookmarkViewController];
        [self.navigationController presentViewController:nav animated:YES completion:nil];
    }
}

#pragma mark - Section/Row Construction

- (nullable OBATableSection*)createServiceAlertsSection:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    OBAServiceAlertsModel* serviceAlerts = [self.modelDAO getServiceAlertsModelForSituations:arrivalAndDeparture.situations];

    if (serviceAlerts.totalCount == 0) {
        return nil;
    }

    return [self createServiceAlertsSection:arrivalAndDeparture serviceAlerts:serviceAlerts];
}

+ (OBATableSection*)createActionsSection:(OBAArrivalAndDepartureV2*)arrivalAndDeparture navigationController:(UINavigationController*)navigationController {
    OBATableSection *actionsSection = [[OBATableSection alloc] init];

    [actionsSection addRowWithBlock:^OBABaseRow * {
        OBATimelineBarRow *tableRow = [[OBATimelineBarRow alloc] initWithTitle:NSLocalizedString(@"msg_minus_report_problem_this_trip", @"") action:^(OBABaseRow *row){
            OBAReportProblemWithTripViewController *vc = [[OBAReportProblemWithTripViewController alloc] initWithTripInstance:arrivalAndDeparture.tripInstance trip:arrivalAndDeparture.trip];
            vc.currentStopId = arrivalAndDeparture.stopId;
            [navigationController pushViewController:vc animated:YES];
        }];
        tableRow.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return tableRow;
    }];

    return actionsSection;
}

#pragma mark - Private UI Stuff

+ (UIView*)buildTableHeaderViewWrapperWithHeaderView:(OBAClassicDepartureView*)headerView {
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[headerView]];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.alignment = UIStackViewAlignmentFill;
    stackView.spacing = [OBATheme compactPadding];
    stackView.layoutMargins = [OBATheme compactEdgeInsets];
    stackView.layoutMarginsRelativeArrangement = YES;

    UIStackView *outerStack = [[UIStackView alloc] initWithArrangedSubviews:@[OBAUIBuilder.lineView, stackView, OBAUIBuilder.lineView]];
    outerStack.axis = UILayoutConstraintAxisVertical;
    outerStack.alignment = UIStackViewAlignmentFill;

    return outerStack;
}

@end
