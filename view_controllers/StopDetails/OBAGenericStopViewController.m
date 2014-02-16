/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific languOBAStopSectionTypeage governing permissions and
 * limitations under the License.
 */

#import "OBAGenericStopViewController.h"
#import "OBALogger.h"

#import "OBAArrivalEntryTableViewCell.h"

#import "OBAProgressIndicatorView.h"

#import "OBAPresentation.h"

#import "OBAStopPreferences.h"
#import "OBAEditStopBookmarkViewController.h"
#import "OBAEditStopPreferencesViewController.h"
#import "OBAArrivalAndDepartureViewController.h"
#import "OBATripDetailsViewController.h"
#import "OBAReportProblemViewController.h"
#import "OBAStopIconFactory.h"
#import "OBARegionV2.h"

#import "OBASearchController.h"
#import "OBASphericalGeometryLibrary.h"
#import "MKMapView+oba_Additions.h"
#import "UITableViewController+oba_Additions.h"
#import "OBABookmarkGroup.h"
#import "OBAStopWebViewController.h"

static const double kNearbyStopRadius = 200;
static NSString *kOBANoStopInformationURL = @"http://stopinfo.pugetsound.onebusaway.org/testing";
static NSString *kOBADidShowStopInfoHintDefaultsKey = @"OBADidShowStopInfoHintDefaultsKey";

@interface OBAGenericStopViewController ()
@property(strong,readwrite) OBAApplicationDelegate * _appDelegate;
@property(strong,readwrite) NSString * stopId;

@property(strong) id<OBAModelServiceRequest> request;
@property(strong) NSTimer *timer;

@property(strong) OBAArrivalsAndDeparturesForStopV2 * result;

@property(strong) OBAProgressIndicatorView * progressView;
@property(strong) OBAServiceAlertsModel * serviceAlerts;
@property (nonatomic, strong) EMHint *hint;
@end

@interface OBAGenericStopViewController ()

// Override point for extension classes
- (void)customSetup;

- (void)clearPendingRequest;
- (void)didBeginRefresh;
- (void)didFinishRefresh;


- (NSUInteger) sectionIndexForSectionType:(OBAStopSectionType)section;

- (UITableViewCell*) tableView:(UITableView*)tableView serviceAlertCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell*) tableView:(UITableView*)tableView predictedArrivalCellForRowAtIndexPath:(NSIndexPath*)indexPath;
- (void)determineFilterTypeCellText:(UITableViewCell*)filterTypeCell filteringEnabled:(bool)filteringEnabled;
- (UITableViewCell*) tableView:(UITableView*)tableView filterCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell*) tableView:(UITableView*)tableView actionCellForRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)tableView:(UITableView *)tableView didSelectServiceAlertRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didSelectTripRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didSelectActionRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)reloadData;
@end


@implementation OBAGenericStopViewController

- (id) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate {

    if (self = [super initWithStyle:UITableViewStylePlain]) {

        _appDelegate = appDelegate;
        
        _minutesBefore = 5;
        _minutesAfter = 35;
        
        _showTitle = YES;
        _showServiceAlerts = YES;
        _showActions = YES;
        
        _arrivalCellFactory = [[OBAArrivalEntryTableViewCellFactory alloc] initWithappDelegate:_appDelegate tableView:self.tableView];
        _arrivalCellFactory.showServiceAlerts = YES;

        _serviceAlerts = [[OBAServiceAlertsModel alloc] init];

        _progressView = [[OBAProgressIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 160, 44)];
        [self.navigationItem setTitleView:_progressView];
        
        UIBarButtonItem * refreshItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(onRefreshButton:)];
        [self.navigationItem setRightBarButtonItem:refreshItem];
        
        _allArrivals = [[NSMutableArray alloc] init];
        _filteredArrivals = [[NSMutableArray alloc] init];
        _showFilteredArrivals = YES;

        self.navigationItem.title = NSLocalizedString(@"Stop",@"stop");
        self.tableView.backgroundColor = [UIColor whiteColor];
        
        [self customSetup];
    }
    return self;
}

- (id) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate stopId:(NSString*)stopId {
    if (self = [self initWithApplicationDelegate:appDelegate]) {
        self.stopId = stopId;
    }
    return self;
}

- (void) dealloc {
    [self clearPendingRequest];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.showTitle) {
        UINib *xibFile = [UINib nibWithNibName:@"OBAGenericStopViewController" bundle:nil];
        [xibFile instantiateWithOwner:self options:nil];
        self.tableView.tableHeaderView = self.tableHeaderView;
        self.mapView.accessibilityElementsHidden = YES;

        self.stopRoutes = [[OBAShadowLabel alloc] initWithFrame:CGRectMake(0, 77, 320, 18) rate:60 andFadeLength:10];
        self.stopRoutes.marqueeType = MLContinuous;
        self.stopRoutes.backgroundColor = [UIColor clearColor];
        self.stopRoutes.textColor = [UIColor whiteColor];
        self.stopRoutes.font = [UIFont boldSystemFontOfSize:14];
        self.stopRoutes.continuousMarqueeExtraBuffer = 80;
        self.stopRoutes.tapToScroll = YES;
        self.stopRoutes.animationDelay = 0;
        self.stopRoutes.animationCurve = UIViewAnimationOptionCurveLinear;
        [self.tableHeaderView addSubview:self.stopRoutes];

        self.stopNumber = [[OBAShadowLabel alloc] initWithFrame:CGRectMake(10, 40, 320, 15)];
        self.stopNumber.backgroundColor = [UIColor clearColor];
        self.stopNumber.textColor = [UIColor whiteColor];
        self.stopNumber.font = [UIFont systemFontOfSize:13];
        [self.tableHeaderView addSubview:self.stopNumber];
        
        self.stopName = [[OBAShadowLabel alloc] initWithFrame:CGRectMake(0, 53, 275, 27) rate:60 andFadeLength:10];
        self.stopName.marqueeType = MLContinuous;
        self.stopName.backgroundColor = [UIColor clearColor];
        self.stopName.textColor = [UIColor whiteColor];
        self.stopName.font = [UIFont boldSystemFontOfSize:19];
        self.stopName.continuousMarqueeExtraBuffer = 80;
        self.stopName.tapToScroll = YES;
        self.stopName.animationDelay = 0;
        self.stopName.animationCurve = UIViewAnimationOptionCurveLinear;
        [self.view addSubview:self.stopName];

        OBARegionV2 *region = _appDelegate.modelDao.region;
        if (![region.stopInfoUrl isEqual:[NSNull null]]) {
            self.stopInfoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
            [self.stopInfoButton setFrame:CGRectMake(285, 53, 25, 25)];
            [self.stopInfoButton addTarget:self
                               action:@selector(openURLS)
                     forControlEvents:UIControlEventTouchUpInside];
            self.stopInfoButton.tintColor = [UIColor whiteColor];
            self.stopInfoButton.accessibilityLabel = NSLocalizedString(@"About this stop, button.", @"");
            self.stopInfoButton.accessibilityHint = NSLocalizedString(@"Double tap for stop landmark information.", @"");
            self.stopInfoButton.hidden = YES;
            [self.tableHeaderView addSubview:self.stopInfoButton];
        }
        
        self.tableHeaderView.backgroundColor = OBAGREENBACKGROUND;
        [self.tableHeaderView addSubview:self.stopName];
        
        UIView *legalView = nil;
        
        for (UIView *subview in self.mapView.subviews) {
            if ([subview isKindOfClass:[UILabel class]]) {
                legalView = subview;
                break;
            }
        }
        legalView.frame = CGRectMake(290, 4, legalView.frame.size.width, legalView.frame.size.height);
        
        [self hideEmptySeparators];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([self shouldShowHint]) {
        [self showHint];
    }
}

- (void)openURLS {
    
    OBARegionV2 *region = _appDelegate.modelDao.region;
    
    if (region) {
        
        NSString *url;
        OBAStopV2 *stop = _result.stop;
        NSString *stopFinderBaseUrl = region.stopInfoUrl;
        
        NSString *hiddenPreferenceUserId = @"OBAApplicationUserId";
        NSString *userID = [[NSUserDefaults standardUserDefaults] stringForKey:hiddenPreferenceUserId];
        
        if (![region.stopInfoUrl isEqual:[NSNull null]]) {
            url = [NSString stringWithFormat:@"%@/busstops/%@", stopFinderBaseUrl, stop.stopId];
            if (userID.length > 0) {
                url = [NSString stringWithFormat:@"%@?userid=%@", url, userID];
                if (stop.direction.length > 0) {
                    url = [NSString stringWithFormat:@"%@&direction=%@", url, stop.direction];
                }
            }
            else if (stop.direction.length > 0) {
                url = [NSString stringWithFormat:@"%@?direction=%@", url, stop.direction];
            }
        }
        else {
            url = kOBANoStopInformationURL;
        }
        [TestFlight passCheckpoint:[NSString stringWithFormat:@"Loaded StopInfo from %@", region.regionName]];
        
        
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0.0")) {
            OBAStopWebViewController *webViewController = [[OBAStopWebViewController alloc] initWithURL:[NSURL URLWithString:url]];
            [self.navigationController pushViewController:webViewController animated:YES];
        } else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString: url]];
        }
    }
    [[GAI sharedInstance].defaultTracker
             send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"
                                                          action:@"button_press"
                                                           label:[NSString stringWithFormat:@"Loaded StopInfo from %@", region.regionName]
                                                           value:nil] build]];
}

- (void)viewDidUnload {
    self.tableHeaderView = nil;
    self.tableView.tableHeaderView = nil;
    [self setStopRoutes:nil];
    [super viewDidUnload];
}

- (OBABookmarkV2*)existingBookmark {
    OBAStopV2 *stop = _result.stop;
    for (OBABookmarkV2 *bm in [_appDelegate.modelDao bookmarks]) {
        if ([bm.stopIds containsObject:stop.stopId]) {
            return bm;
        }
    }
    for (OBABookmarkGroup *group in [_appDelegate.modelDao bookmarkGroups]) {
        for (OBABookmarkV2 *bm in group.bookmarks) {
            if ([bm.stopIds containsObject:stop.stopId]) {
                return bm;
            }
        }
    }
    return nil;
}

- (OBAStopSectionType) sectionTypeForSection:(NSUInteger)section {

    if (_result.stop) {
        
        int offset = 0;
                
        if( _showServiceAlerts && _serviceAlerts.unreadCount > 0) {

            if( section == offset )
                return OBAStopSectionTypeServiceAlerts;
            offset++;
        }
        
        if( section == offset ) {
            return OBAStopSectionTypeArrivals;
        }
        offset++;
        
        if( [_filteredArrivals count] != [_allArrivals count] ) {
            if( section == offset )
                return OBAStopSectionTypeFilter;
            offset++;
        }
        
        if( _showActions ) {
            if( section == offset)
                return OBAStopSectionTypeActions;
            offset++;
        }
    }
    
    return OBAStopSectionTypeNone;
}

#pragma mark Stop Info Hint

- (NSArray *)hintStateRectsToHint:(id)hintState {
    return @[ [NSValue valueWithCGRect:CGRectMake(297, 129, 30, 30)] ];
}

- (UIView *)hintStateViewForDialog:(id)hintState {
    NSString *message = NSLocalizedString(@"Tap here to learn and share useful information about this stop", @"EMHint label");
    NSString *accessMessage = NSLocalizedString(@"Access information about bus stops through the stop info button found after the name of the stop. Double tap to dismiss this message.", @"EMHint accessibility label");
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    CGSize sz = [message sizeWithFont:label.font constrainedToSize:CGSizeMake(250, 1000)];
    
    CGRect frame = CGRectMake(floorf(150 - sz.width/2),
                              floorf(250 - sz.height/2),
                              floorf(sz.width + 5),
                              floorf(sz.height + 10));
    label.frame = frame;
    label.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin
                                | UIViewAutoresizingFlexibleRightMargin
                                | UIViewAutoresizingFlexibleLeftMargin
                                | UIViewAutoresizingFlexibleBottomMargin);
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.numberOfLines = 0;
    label.lineBreakMode = UILineBreakModeWordWrap;
    label.text = message;
    label.accessibilityLabel = accessMessage;
    
    return label;
}

- (BOOL)shouldShowHint {
    BOOL didShowHintAlready = [[NSUserDefaults standardUserDefaults] boolForKey:kOBADidShowStopInfoHintDefaultsKey];
    OBARegionV2 *region = _appDelegate.modelDao.region;
    BOOL validStopInfoRegion = ![region.stopInfoUrl isEqual:[NSNull null]];
    return (!didShowHintAlready && validStopInfoRegion);
}

- (void)showHint {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kOBADidShowStopInfoHintDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.hint = [[EMHint alloc] init];
    self.hint.hintDelegate = self;
    [self.hint presentModalMessage:@"Tap here to view and submit more information about this stop with the new Stop Info service" where:self.view.superview];
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget*) navigationTarget {
    NSDictionary * params = @{@"stopId": _stopId};
    return [OBANavigationTarget target:OBANavigationTargetTypeStop parameters:params];
}


- (void) setNavigationTarget:(OBANavigationTarget*)navigationTarget {
    self.stopId = [navigationTarget parameterForKey:@"stopId"];
    [self refresh];
}

#pragma mark UIViewController

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    self.navigationItem.title = @"Stop";
    
    [self refresh];

    [TestFlight passCheckpoint:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName
                                       value:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker
     send:[[GAIDictionaryBuilder createAppView] build]];
    if (UIAccessibilityIsVoiceOverRunning()){
        [TestFlight passCheckpoint:[NSString stringWithFormat:@"Loaded view: %@ using VoiceOver", [self class]]];
        [[GAI sharedInstance].defaultTracker
            send:[[GAIDictionaryBuilder createEventWithCategory:@"accessibility"
                                                         action:@"voiceover_on"
                                                          label:@"VoiceOver Running"
                                                          value:nil] build]];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
 
    [self clearPendingRequest];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)willEnterForeground {
    // will repaint the UITableView to update new time offsets and such when returning from the background.
    // this makes it so old data, represented with current times, from before the task switch will display
    // briefly before we fetch new data.
    [self reloadData];
}

#pragma mark OBAModelServiceDelegate

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {
    NSString * message = [NSString stringWithFormat:@"%@: %@",NSLocalizedString(@"Updated",@"message"), [OBACommon getTimeAsString]];
    [_progressView setMessage:message inProgress:NO progress:0];
    [self didFinishRefresh];
    self.result = obj;
    
    // Note the event
    [[NSNotificationCenter defaultCenter] postNotificationName:OBAViewedArrivalsAndDeparturesForStopNotification object:self.result.stop];

    [self reloadData];
}

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withCode:(NSInteger)code context:(id)context {
    NSString *message = (404 == code ? NSLocalizedString(@"Stop not found",@"code == 404") : NSLocalizedString(@"Unknown error",@"code # 404"));
    [self.progressView setMessage:message inProgress:NO progress:0];
    [self didFinishRefresh];
}

- (void)requestDidFail:(id<OBAModelServiceRequest>)request withError:(NSError *)error context:(id)context {
    OBALogWarningWithError(error, @"Error... yay!");
    [_progressView setMessage:NSLocalizedString(@"Error connecting",@"requestDidFail") inProgress:NO progress:0];
    [self didFinishRefresh];
}

- (void)request:(id<OBAModelServiceRequest>)request withProgress:(float)progress context:(id)context {
    [_progressView setInProgress:YES progress:progress];
}

#pragma mark MapView

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    if ([annotation isKindOfClass:[OBAStopV2 class]]) {
        
        OBAStopV2 *stop = (OBAStopV2*)annotation;
        static NSString *viewId = @"StopView";
        
        MKAnnotationView * view = [mapView dequeueReusableAnnotationViewWithIdentifier:viewId];
        if (!view) {
            view = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:viewId];
        }
        view.canShowCallout = NO;
        
        OBAStopIconFactory * stopIconFactory = self.appDelegate.stopIconFactory;
        view.image = [stopIconFactory getIconForStop:stop];
        return view;
    }
    return nil;
}

#pragma mark - UITableViewDelegate and UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    OBAStopV2 * stop = _result.stop;
    
    if( stop ) {
        int count = 2;
        if( [_filteredArrivals count] != [_allArrivals count] )
            count++;
        if( _showServiceAlerts && _serviceAlerts.unreadCount > 0 )
            count++;
        return count;
    }
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    switch ([self sectionTypeForSection:section]) {
        case OBAStopSectionTypeServiceAlerts: {
            return 1;
        }
        case OBAStopSectionTypeArrivals: {
            NSInteger arrivalRows = self.showFilteredArrivals ? self.filteredArrivals.count : self.allArrivals.count;
            if (arrivalRows > 0) {
                return arrivalRows + 1;
            }
            else {
                // for a 'no arrivals in the next 35 minutes' message
                // for 'load next arrivals' message
                return 2;
            }
        }
        case OBAStopSectionTypeFilter: {
            return 1;
        }
        case OBAStopSectionTypeActions: {
            return 5;
        }
        default: {
            return 0;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    switch ([self sectionTypeForSection:indexPath.section]) {
        case OBAStopSectionTypeServiceAlerts: {
            return [self tableView:tableView serviceAlertCellForRowAtIndexPath:indexPath];
        }
        case OBAStopSectionTypeArrivals: {
            return [self tableView:tableView predictedArrivalCellForRowAtIndexPath:indexPath];
        }
        case OBAStopSectionTypeFilter: {
            return [self tableView:tableView filterCellForRowAtIndexPath:indexPath];
        }
        case OBAStopSectionTypeActions: {
            return [self tableView:tableView actionCellForRowAtIndexPath:indexPath];
        }
        default: {
            return [UITableViewCell getOrCreateCellForTableView:tableView];
        }
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OBAStopSectionType sectionType = [self sectionTypeForSection:indexPath.section];
    
    switch (sectionType) {
            
        case OBAStopSectionTypeServiceAlerts:
            [self tableView:tableView didSelectServiceAlertRowAtIndexPath:indexPath];
            break;
            
        case OBAStopSectionTypeArrivals:
            [self tableView:tableView didSelectTripRowAtIndexPath:indexPath];
            break;
            
        case OBAStopSectionTypeFilter: {
            _showFilteredArrivals = !_showFilteredArrivals;
            
            // update arrivals section
            int arrivalsViewSection = [self sectionIndexForSectionType:OBAStopSectionTypeArrivals];

            UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
            [self determineFilterTypeCellText:cell filteringEnabled:_showFilteredArrivals];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            
            if ([_filteredArrivals count] == 0)
            {
                // We're showing a "no arrivals in the next 30 minutes" message, so our insertion/deletion math below would be wrong.
                // Instead, just refresh the section with a fade.
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:arrivalsViewSection] withRowAnimation:UITableViewRowAnimationFade];
            }
            else if ([_allArrivals count] != [_filteredArrivals count])
            {
                // Display a nice animation of the cells when changing our filter settings
                NSMutableArray *modificationArray = [NSMutableArray array];
                
                for (NSInteger i = 0; i < self.allArrivals.count; i++) {
                    OBAArrivalAndDepartureV2 * pa = self.allArrivals[i];
                    if (![_filteredArrivals containsObject:pa]) {
                        [modificationArray addObject:[NSIndexPath indexPathForRow:i inSection:arrivalsViewSection]];
                    }
                }

                if (self.showFilteredArrivals) {
                    [self.tableView deleteRowsAtIndexPaths:modificationArray withRowAnimation:UITableViewRowAnimationFade];
                }
                else {
                    [self.tableView insertRowsAtIndexPaths:modificationArray withRowAnimation:UITableViewRowAnimationFade];
                }
            }
            
            break;
        }
        
        case OBAStopSectionTypeActions:
            [self tableView:tableView didSelectActionRowAtIndexPath:indexPath];
            break;

        default:
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([self sectionTypeForSection:section] == OBAStopSectionTypeActions) {
        return 30;
    }
    return 0;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
    view.backgroundColor = OBAGREENBACKGROUND;
    return view;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self sectionTypeForSection:indexPath.section] == OBAStopSectionTypeArrivals) {
        return 50;
    }
    return 44;
}

- (void) customSetup {
    
}

- (void) refresh {
    [_progressView setMessage:NSLocalizedString(@"Updating...",@"refresh") inProgress:YES progress:0];
    [self didBeginRefresh];
    
    [self clearPendingRequest];
    _request = [_appDelegate.modelService requestStopWithArrivalsAndDeparturesForId:_stopId withMinutesBefore:_minutesBefore withMinutesAfter:_minutesAfter withDelegate:self withContext:nil];
    _timer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(refresh) userInfo:nil repeats:YES];
}
     
- (void) clearPendingRequest {
    
    [_timer invalidate];
    _timer = nil;
    
    [_request cancel];
    _request = nil;
}

- (void) didBeginRefresh {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    NSArray * arrivals = _showFilteredArrivals ? _filteredArrivals : _allArrivals;
    UITableViewCell *cell;
    if (arrivals.count == 0) {
        cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    } else {
        cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:arrivals.count inSection:0]];
    }
    cell.userInteractionEnabled = NO;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textColor = [UIColor lightGrayColor];
}

- (void) didFinishRefresh {
    self.navigationItem.rightBarButtonItem.enabled = YES;
    NSArray * arrivals = _showFilteredArrivals ? _filteredArrivals : _allArrivals;
    UITableViewCell *cell;
    if (arrivals.count == 0) {
        cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    } else {
        cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:arrivals.count inSection:0]];
    }
    cell.userInteractionEnabled = YES;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.textLabel.textColor = [UIColor blackColor];
}

- (NSUInteger) sectionIndexForSectionType:(OBAStopSectionType)section {

    OBAStopV2 * stop = _result.stop;
    
    if( stop ) {
        
        int offset = 0;
                
        if( _showServiceAlerts && _serviceAlerts.unreadCount > 0) {
            if( section == OBAStopSectionTypeServiceAlerts )
                return offset;
            offset++;
        }
        
        if( section == OBAStopSectionTypeArrivals )
            return offset;
        offset++;
        
        if( [_filteredArrivals count] != [_allArrivals count] ) {
            if( section == OBAStopSectionTypeFilter )
                return offset;
            offset++;
        }
        
        if( _showActions ) {
            if( section == OBAStopSectionTypeActions)
                return offset;
            offset++;
        }
    }
    
    return 0;
    
}

- (UITableViewCell*) tableView:(UITableView*)tableView serviceAlertCellForRowAtIndexPath:(NSIndexPath *)indexPath {    
    return [OBAPresentation tableViewCellForUnreadServiceAlerts:_serviceAlerts tableView:tableView];
}

- (UITableViewCell*)tableView:(UITableView*)tableView predictedArrivalCellForRowAtIndexPath:(NSIndexPath*)indexPath {
    NSArray * arrivals = _showFilteredArrivals ? _filteredArrivals : _allArrivals;

    if ((arrivals.count == 0 && indexPath.row == 1) || (arrivals.count == indexPath.row && arrivals.count > 0)) {
        UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
        cell.textLabel.text = NSLocalizedString(@"Load more arrivals",@"load more arrivals");
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.textLabel.font = [UIFont systemFontOfSize:18];
        cell.accessoryType = UITableViewCellAccessoryNone;
        return cell;
    } else if(arrivals.count == 0 ) {
        UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
        cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"No arrivals in the next %i minutes",@"[arrivals count] == 0"), self.minutesAfter];
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.textLabel.font = [UIFont systemFontOfSize:18];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        return cell;
    } else {

        OBAArrivalAndDepartureV2 * pa = arrivals[indexPath.row];
        OBAArrivalEntryTableViewCell * cell = [_arrivalCellFactory createCellForArrivalAndDeparture:pa];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
       
        return cell;
    }
}


- (void)determineFilterTypeCellText:(UITableViewCell*)filterTypeCell filteringEnabled:(bool)filteringEnabled {
    if( filteringEnabled )
        filterTypeCell.textLabel.text = NSLocalizedString(@"Show all arrivals",@"filteringEnabled");
    else
        filterTypeCell.textLabel.text = NSLocalizedString(@"Show filtered arrivals",@"!filteringEnabled");    
}

- (UITableViewCell*) tableView:(UITableView*)tableView filterCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    
    [self determineFilterTypeCellText:cell filteringEnabled:_showFilteredArrivals];
    
    cell.textLabel.textAlignment = UITextAlignmentCenter;
    cell.textLabel.font = [UIFont systemFontOfSize:18];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

- (UITableViewCell*) tableView:(UITableView*)tableView actionCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];

    cell.textLabel.textAlignment = UITextAlignmentLeft;
    cell.textLabel.font = [UIFont systemFontOfSize:18];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = nil;
    
    switch(indexPath.row) {
        case 0: {
            if ([self existingBookmark]) {
                cell.textLabel.text = NSLocalizedString(@"Edit Bookmark",@"case 0 edit");
            } else {
                cell.textLabel.text = NSLocalizedString(@"Add to Bookmarks",@"case 0");
            }
            break;
        }
        case 1: {
            cell.textLabel.text = NSLocalizedString(@"Report a Problem",@"self.navigationItem.title");
            break;
        }
        case 2: {
            cell.textLabel.text = NSLocalizedString(@"About This Stop",@"case 2");
            break;
        }
        case 3: {
            if (_serviceAlerts.totalCount == 0) {
                cell.textLabel.text = @"Service Alerts";
            }
            else {
                cell.textLabel.text = [NSString stringWithFormat:@"Service Alerts: %d total", _serviceAlerts.totalCount];
            }

            if (_serviceAlerts.totalCount == 0) {
                cell.imageView.image = nil;
            }
            else if (_serviceAlerts.unreadCount > 0) {
                NSString *imageName = [_serviceAlerts.unreadMaxSeverity isEqual:@"noImpact"] ? @"Alert-Info" : @"Alert";
                cell.imageView.image = [UIImage imageNamed:imageName];
            }
            else {
                NSString *imageName = [_serviceAlerts.maxSeverity isEqual:@"noImpact"] ? @"Alert-Info-Grayscale" : @"AlertGrayscale";
                cell.imageView.image = [UIImage imageNamed:imageName];
            }
            
            return cell;
            break;
        }
        case 4: {
            cell.textLabel.text = NSLocalizedString(@"Filter & Sort Routes",@"case 1");
            break;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectServiceAlertRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray * situations = _result.situations;
    [OBAPresentation showSituations:situations withappDelegate:_appDelegate navigationController:self.navigationController args:nil];
}

- (void)tableView:(UITableView *)tableView didSelectTripRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray * arrivals = _showFilteredArrivals ? _filteredArrivals : _allArrivals;
    if ((arrivals.count == 0 && indexPath.row == 1) || (arrivals.count == indexPath.row && arrivals.count > 0)) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        self.minutesAfter += 30;
        [self refresh];
    } else if ( 0 <= indexPath.row && indexPath.row < arrivals.count ) {
        OBAArrivalAndDepartureV2 * arrivalAndDeparture = arrivals[indexPath.row];
        OBAArrivalAndDepartureViewController * vc = [[OBAArrivalAndDepartureViewController alloc] initWithApplicationDelegate:_appDelegate arrivalAndDeparture:arrivalAndDeparture];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView didSelectActionRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.row) {
        case 0: {
            OBAEditStopBookmarkViewController * vc = nil;
            OBABookmarkV2 * bookmark = [self existingBookmark];
            if (!bookmark) {
                bookmark = [_appDelegate.modelDao createTransientBookmark:_result.stop];
                
                vc = [[OBAEditStopBookmarkViewController alloc] initWithApplicationDelegate:_appDelegate bookmark:bookmark editType:OBABookmarkEditNew];
            } else {
                vc = [[OBAEditStopBookmarkViewController alloc] initWithApplicationDelegate:_appDelegate bookmark:bookmark editType:OBABookmarkEditExisting];
            }
            [self.navigationController pushViewController:vc animated:YES];
            
            break;
        }
        case 1: {
            OBAReportProblemViewController * vc = [[OBAReportProblemViewController alloc] initWithApplicationDelegate:_appDelegate stop:_result.stop];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case 2: {
            [self openURLS];
            break;
        }
        case 3: {
            NSArray * situations = _result.situations;
            [OBAPresentation showSituations:situations withappDelegate:_appDelegate navigationController:self.navigationController args:nil];
            break;
        }

        case 4: {
            OBAEditStopPreferencesViewController * vc = [[OBAEditStopPreferencesViewController alloc] initWithApplicationDelegate:_appDelegate stop:_result.stop];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
    }
    
}

- (IBAction)onRefreshButton:(id)sender {
    [self refresh];
}

NSComparisonResult predictedArrivalSortByDepartureTime(id pa1, id pa2, void * context) {
    return ((OBAArrivalAndDepartureV2*)pa1).bestDepartureTime - ((OBAArrivalAndDepartureV2*)pa2).bestDepartureTime;
}

NSComparisonResult predictedArrivalSortByRoute(id o1, id o2, void * context) {
    OBAArrivalAndDepartureV2* pa1 = o1;
    OBAArrivalAndDepartureV2* pa2 = o2;
    
    OBARouteV2 * r1 = pa1.route;
    OBARouteV2 * r2 = pa2.route;
    NSComparisonResult r = [r1 compareUsingName:r2];
    
    if( r == 0)
        r = predictedArrivalSortByDepartureTime(pa1,pa2,context);
    
    return r;
}

- (void) reloadData {
        
    OBAModelDAO * modelDao = _appDelegate.modelDao;
    
    OBAStopV2 * stop = _result.stop;
    
    NSArray * predictedArrivals = _result.arrivalsAndDepartures;
    
    [_allArrivals removeAllObjects];
    [_filteredArrivals removeAllObjects];
    
    if (stop) {
        [self.mapView oba_setCenterCoordinate:CLLocationCoordinate2DMake(stop.lat, stop.lon) zoomLevel:15 animated:NO];
        self.stopName.text = stop.name;
        if (stop.direction) {
            self.stopNumber.text = [NSString stringWithFormat:@"%@ #%@ - %@ %@",NSLocalizedString(@"Stop",@"text"),stop.code,stop.direction,NSLocalizedString(@"bound",@"text")];
        }
        else {
            self.stopNumber.text = [NSString stringWithFormat:@"%@ #%@",NSLocalizedString(@"Stop",@"text"),stop.code];
   
        }

        
        if (stop.routeNamesAsString) 
            self.stopRoutes.text = [stop routeNamesAsString];
        
        [_mapView addAnnotation:stop];

        self.stopInfoButton.hidden = NO;
    }
    
    if (stop && predictedArrivals) {
        
        OBAStopPreferencesV2 * prefs = [modelDao stopPreferencesForStopWithId:stop.stopId];
        
        for( OBAArrivalAndDepartureV2 * pa in predictedArrivals) {
            [_allArrivals addObject:pa];
            if( [prefs isRouteIdEnabled:pa.routeId] )
                [_filteredArrivals addObject:pa];
        }
        
        switch (prefs.sortTripsByType) {
            case OBASortTripsByDepartureTimeV2:
                [_allArrivals sortUsingFunction:predictedArrivalSortByDepartureTime context:nil];
                [_filteredArrivals sortUsingFunction:predictedArrivalSortByDepartureTime context:nil];
                break;
            case OBASortTripsByRouteNameV2:
                [_allArrivals sortUsingFunction:predictedArrivalSortByRoute context:nil];
                [_filteredArrivals sortUsingFunction:predictedArrivalSortByRoute context:nil];
                break;
        }
    }
    
    _serviceAlerts = [modelDao getServiceAlertsModelForSituations:_result.situations];
    
    [self.tableView reloadData];
}

@end


