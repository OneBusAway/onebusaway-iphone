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

#import "OBASituationsViewController.h"

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
#import "UITableViewCell+oba_Additions.h"
#import "OBABookmarkGroup.h"
#import "OBAStopWebViewController.h"

#import "OBAAnalytics.h"
#import "OBAProblemReport.h"

static NSString *kOBANoStopInformationURL = @"http://stopinfo.pugetsound.onebusaway.org/testing";
static NSString *kOBAIncreaseContrastKey = @"OBAIncreaseContrastDefaultsKey";
static NSString *kOBAShowSurveyAlertKey = @"OBASurveyAlertDefaultsKey";
static NSString *kOBASurveyURL = @"http://tinyurl.com/stopinfo";

@interface OBAGenericStopViewController () <UIAlertViewDelegate>
@property (strong, readwrite) OBAApplicationDelegate *appDelegate;
@property (strong, readwrite) NSString *stopId;

@property (strong) id<OBAModelServiceRequest> request;
@property (strong) NSTimer *timer;

@property (strong) OBAArrivalsAndDeparturesForStopV2 *result;

@property(strong) OBAProgressIndicatorView * progressView;
@property(strong) OBAServiceAlertsModel * serviceAlerts;
@property (nonatomic, strong) UIButton *stopInfoButton;
@property (nonatomic, strong) UIButton *highContrastStopInfoButton;

@property (nonatomic, assign) BOOL showInHighContrast;
@property (nonatomic, assign) BOOL showSurveyAlert;

@property(nonatomic,strong) NSDictionary *problemReports;
@end

@interface OBAGenericStopViewController ()

// Override point for extension classes
- (void)customSetup;

- (void)clearPendingRequest;
- (void)didBeginRefresh;
- (void)didFinishRefresh;


- (NSUInteger)sectionIndexForSectionType:(OBAStopSectionType)section;

- (UITableViewCell *)tableView:(UITableView *)tableView serviceAlertCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell *)tableView:(UITableView *)tableView predictedArrivalCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)determineFilterTypeCellText:(UITableViewCell *)filterTypeCell filteringEnabled:(bool)filteringEnabled;
- (UITableViewCell *)tableView:(UITableView *)tableView filterCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell *)tableView:(UITableView *)tableView actionCellForRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)tableView:(UITableView *)tableView didSelectServiceAlertRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didSelectTripRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didSelectActionRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)reloadData;
@end


@implementation OBAGenericStopViewController

- (id)initWithApplicationDelegate:(OBAApplicationDelegate *)appDelegate {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        _appDelegate = appDelegate;

        _minutesBefore = 5;
        _minutesAfter = 35;

        _showTitle = YES;
        _showServiceAlerts = YES;
        _showActions = YES;

        _arrivalCellFactory = [[OBAArrivalEntryTableViewCellFactory alloc] initWithappDelegate:_appDelegate tableView:self.tableView];
        _arrivalCellFactory.showServiceAlerts = YES;

        _problemReports = @{};
        _serviceAlerts = [[OBAServiceAlertsModel alloc] init];

        _progressView = [[OBAProgressIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 160, 44)];
        [self.navigationItem setTitleView:_progressView];

        UIBarButtonItem *refreshItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(onRefreshButton:)];
        [self.navigationItem setRightBarButtonItem:refreshItem];
      
        _allArrivals = [[NSMutableArray alloc] init];
        _filteredArrivals = [[NSMutableArray alloc] init];
        _showFilteredArrivals = YES;

        self.navigationItem.title = NSLocalizedString(@"Stop", @"stop");
        self.tableView.backgroundColor = [UIColor whiteColor];

        [self customSetup];
    }

    return self;
}

- (id)initWithApplicationDelegate:(OBAApplicationDelegate *)appDelegate stopId:(NSString *)stopId {
    if (self = [self initWithApplicationDelegate:appDelegate]) {
        self.stopId = stopId;
    }

    return self;
}

- (void)dealloc {
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

        self.tableHeaderView.backgroundColor = OBAGREENBACKGROUND;
        [self.tableHeaderView addSubview:self.stopName];

        OBARegionV2 *region = _appDelegate.modelDao.region;

        if (![region.stopInfoUrl isEqual:[NSNull null]]) {
            self.showInHighContrast = [[NSUserDefaults standardUserDefaults] boolForKey:kOBAIncreaseContrastKey];

            if (self.showInHighContrast) {
                [OBAAnalytics reportEventWithCategory:@"accessibility" action:@"increase_contrast" label:[NSString stringWithFormat:@"Loaded view: %@ with Increased Contrast", [self class]] value:nil];
                self.mapView.hidden = YES;
                self.tableHeaderView.backgroundColor = OBAGREEN;
            }
            else {
                self.mapView.hidden = NO;
                self.tableHeaderView.backgroundColor = [UIColor clearColor];
            }

            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshContrast) name:OBAIncreaseContrastToggledNotification object:nil];

            CGFloat infoButtonOriginX = CGRectGetWidth(self.view.bounds) - 25.f - 10.f;
            
            self.highContrastStopInfoButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [self.highContrastStopInfoButton
             setBackgroundImage:[UIImage imageNamed:@"InfoButton.png"]
                       forState:UIControlStateNormal];
            [self.highContrastStopInfoButton setFrame:CGRectMake(infoButtonOriginX, 53, 25, 25)];
            [self.highContrastStopInfoButton
             addTarget:self
                          action:@selector(openURLS)
                forControlEvents:UIControlEventTouchUpInside];
            self.highContrastStopInfoButton.tintColor = [UIColor whiteColor];
            self.highContrastStopInfoButton.accessibilityLabel = NSLocalizedString(@"About this stop, button.", @"");
            self.highContrastStopInfoButton.accessibilityHint = NSLocalizedString(@"Double tap for stop landmark information.", @"");
            self.highContrastStopInfoButton.hidden = YES;
            [self.tableHeaderView addSubview:self.highContrastStopInfoButton];

            self.stopInfoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];

            [self.stopInfoButton setFrame:CGRectMake(infoButtonOriginX, 53, 25, 25)];
            [self.stopInfoButton
             addTarget:self
                          action:@selector(openURLS)
                forControlEvents:UIControlEventTouchUpInside];
            self.stopInfoButton.tintColor = [UIColor whiteColor];
            self.stopInfoButton.accessibilityLabel = NSLocalizedString(@"About this stop, button.", @"");
            self.stopInfoButton.accessibilityHint = NSLocalizedString(@"Double tap for stop landmark information.", @"");
            self.stopInfoButton.hidden = YES;
            [self.tableHeaderView addSubview:self.stopInfoButton];
        }

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

- (void)refreshContrast {
    self.showInHighContrast = [[NSUserDefaults standardUserDefaults] boolForKey:kOBAIncreaseContrastKey];

    if (self.showInHighContrast) {
        self.highContrastStopInfoButton.hidden = self.stopInfoButton.hidden;
        self.stopInfoButton.hidden = YES;
        self.mapView.hidden = YES;
        self.tableHeaderView.backgroundColor = OBAGREEN;
    }
    else {
        self.stopInfoButton.hidden = self.highContrastStopInfoButton.hidden;
        self.highContrastStopInfoButton.hidden = YES;
        self.mapView.hidden = NO;
        self.tableHeaderView.backgroundColor = [UIColor clearColor];
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

        [OBAAnalytics reportEventWithCategory:@"ui_action" action:@"button_press" label:[NSString stringWithFormat:@"Loaded StopInfo from %@", region.regionName] value:nil];

        OBAStopWebViewController *webViewController = [[OBAStopWebViewController alloc] initWithURL:[NSURL URLWithString:url]];
        [self.navigationController pushViewController:webViewController animated:YES];
        
        // Show popup for research survey. Should only be implemented
        // when a survey is currently being conducted.
        self.showSurveyAlert = [[NSUserDefaults standardUserDefaults] boolForKey:kOBAShowSurveyAlertKey];
        if (self.showSurveyAlert) {
            [self showSurveyPopup];
        }
        
        // Show popup for research survey. Should only be implemented
        // when a survey is currently being conducted.
        self.showSurveyAlert = [[NSUserDefaults standardUserDefaults] boolForKey:kOBAShowSurveyAlertKey];
        if (self.showSurveyAlert) {
            [self showSurveyPopup];
        }
        
    }

    if (UIAccessibilityIsVoiceOverRunning()) {
        [OBAAnalytics reportEventWithCategory:@"accessibility" action:@"voiceover_on" label:@"Loaded StopInfo with VoiceOver" value:nil];
    }
}

// This method should be used only when there is a survey being conducted.
- (void)showSurveyPopup {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0.0")){
        UIAlertController *surveyAlert = [UIAlertController alertControllerWithTitle:@"Help us improve OneBusAway!"
                                                                       message:@"Tell us why you might contribute information about bus stops, and you could win a $50 gift card!"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Take survey"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       //Open survey in external browser
                                                       [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kOBASurveyURL]];
                                                       [[NSUserDefaults standardUserDefaults] setBool:NO
                                                                                               forKey:kOBAShowSurveyAlertKey];
                                                       [[NSUserDefaults standardUserDefaults] synchronize];
                                                       [surveyAlert dismissViewControllerAnimated:YES
                                                                                       completion:nil];
                                                       
                                                       [OBAAnalytics reportEventWithCategory:@"ui_action"
                                                                                      action:@"button_press"
                                                                                       label:@"Loaded UW StopInfo survey"
                                                                                       value:nil];
                                                   }];
        
        UIAlertAction *notNow = [UIAlertAction actionWithTitle:@"Not right now"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                           [surveyAlert dismissViewControllerAnimated:YES
                                                                                           completion:nil];
                                                       }];
        
        UIAlertAction *neverShow = [UIAlertAction actionWithTitle:@"Don't show this again"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                           [[NSUserDefaults standardUserDefaults] setBool:NO
                                                                                                   forKey:kOBAShowSurveyAlertKey];
                                                           [[NSUserDefaults standardUserDefaults] synchronize];
                                                           [surveyAlert dismissViewControllerAnimated:YES
                                                                                           completion:nil];
                                                           [OBAAnalytics reportEventWithCategory:@"ui_action"
                                                                                          action:@"button_press"
                                                                                           label:@"Never show survey alert"
                                                                                           value:nil];
                                                       }];
        
        
        
        [surveyAlert addAction:ok];
        [surveyAlert addAction:notNow];
        [surveyAlert addAction:neverShow];
        
        [self presentViewController:surveyAlert animated:YES completion:nil];
    }
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

- (OBAStopSectionType)sectionTypeForSection:(NSUInteger)section {
    if (_result.stop) {
        int offset = 0;

        if (_showServiceAlerts && _serviceAlerts.unreadCount > 0) {
            if (section == offset) return OBAStopSectionTypeServiceAlerts;

            offset++;
        }

        if (section == offset) {
            return OBAStopSectionTypeArrivals;
        }

        offset++;

        if ([_filteredArrivals count] != [_allArrivals count]) {
            if (section == offset) return OBAStopSectionTypeFilter;

            offset++;
        }

        if (_showActions) {
            if (section == offset) return OBAStopSectionTypeActions;

            offset++;
        }
    }

    return OBAStopSectionTypeNone;
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget *)navigationTarget {
    NSDictionary *params = @{ @"stopId": _stopId };

    return [OBANavigationTarget target:OBANavigationTargetTypeStop parameters:params];
}

- (void)setNavigationTarget:(OBANavigationTarget *)navigationTarget {
    self.stopId = [navigationTarget parameterForKey:@"stopId"];
    [self refresh];
}

#pragma mark UIViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];

    self.navigationItem.title = @"Stop";

    [self refresh];

    [OBAAnalytics reportScreenView:[NSString stringWithFormat:@"View: %@", [self class]]];

    if (UIAccessibilityIsVoiceOverRunning()) {
        [OBAAnalytics reportEventWithCategory:@"accessibility" action:@"voiceover_on" label:[NSString stringWithFormat:@"Loaded view: %@ using VoiceOver", [self class]] value:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self clearPendingRequest];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)willEnterForeground {
    // will repaint the UITableView to update new time offsets and such when returning from the background.
    // this makes it so old data, represented with current times, from before the task switch will display
    // briefly before we fetch new data.
    [self reloadData];
}

#pragma mark MapView

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[OBAStopV2 class]]) {
        OBAStopV2 *stop = (OBAStopV2 *)annotation;
        static NSString *viewId = @"StopView";

        MKAnnotationView *view = [mapView dequeueReusableAnnotationViewWithIdentifier:viewId];

        if (!view) {
            view = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:viewId];
        }

        view.canShowCallout = NO;

        OBAStopIconFactory *stopIconFactory = self.appDelegate.stopIconFactory;
        view.image = [stopIconFactory getIconForStop:stop];
        return view;
    }

    return nil;
}

#pragma mark - UITableViewDelegate and UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    OBAStopV2 *stop = _result.stop;

    if (stop) {
        int count = 2;

        if ([_filteredArrivals count] != [_allArrivals count]) count++;

        if (_showServiceAlerts && _serviceAlerts.unreadCount > 0) count++;

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
            NSInteger arrivalsViewSection = [self sectionIndexForSectionType:OBAStopSectionTypeArrivals];

            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            [self determineFilterTypeCellText:cell filteringEnabled:_showFilteredArrivals];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

            if ([_filteredArrivals count] == 0) {
                // We're showing a "no arrivals in the next 30 minutes" message, so our insertion/deletion math below would be wrong.
                // Instead, just refresh the section with a fade.
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:arrivalsViewSection] withRowAnimation:UITableViewRowAnimationFade];
            }
            else if ([_allArrivals count] != [_filteredArrivals count]) {
                // Display a nice animation of the cells when changing our filter settings
                NSMutableArray *modificationArray = [NSMutableArray array];

                for (NSInteger i = 0; i < self.allArrivals.count; i++) {
                    OBAArrivalAndDepartureV2 *pa = self.allArrivals[i];

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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([self sectionTypeForSection:section] == OBAStopSectionTypeActions) {
        return 30;
    }

    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];

    view.backgroundColor = OBAGREENBACKGROUND;
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self sectionTypeForSection:indexPath.section] == OBAStopSectionTypeArrivals) {
        return 50;
    }

    return 44;
}

- (void)customSetup {
}

- (void)refresh {
    [_progressView setMessage:NSLocalizedString(@"Updating...", @"refresh") inProgress:YES progress:0];
    [self didBeginRefresh];

    [self clearPendingRequest];
    @weakify(self);
    _request = [_appDelegate.modelService requestStopWithArrivalsAndDeparturesForId:_stopId withMinutesBefore:_minutesBefore withMinutesAfter:_minutesAfter
                                                                    completionBlock:^(id responseData, NSUInteger responseCode, NSError *error) {
        @strongify(self);
        if (error) {
            OBALogWarningWithError(error, @"Error... yay!");
            [self.progressView setMessage:NSLocalizedString(@"Error connecting", @"requestDidFail") inProgress:NO progress:0];
        }
        else if (responseCode >= 300) {
            NSString *message = (404 == responseCode ? NSLocalizedString(@"Stop not found", @"code == 404") : NSLocalizedString(@"Unknown error", @"code # 404"));
            [self.progressView setMessage:message inProgress:NO progress:0];
        }
        else if (responseData) {
            NSString *message = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Updated", @"message"), [OBACommon getTimeAsString]];
            [self.progressView setMessage:message inProgress:NO progress:0];
            self.result = responseData;

            // Note the event
            [[NSNotificationCenter defaultCenter] postNotificationName:OBAViewedArrivalsAndDeparturesForStopNotification object:self.result.stop];
            
            [self reloadData];
        }

        [self didFinishRefresh];
    } progressBlock:^(CGFloat progress) {
        [self.progressView setInProgress:YES progress:progress];
    }];
    _timer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(refresh) userInfo:nil repeats:YES];
}

- (void)clearPendingRequest {
    [_timer invalidate];
    _timer = nil;

    [_request cancel];
    _request = nil;
}

- (void)didBeginRefresh {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    NSArray *arrivals = _showFilteredArrivals ? _filteredArrivals : _allArrivals;
    UITableViewCell *cell;

    if (arrivals.count == 0) {
        cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    }
    else {
        cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:arrivals.count inSection:0]];
    }

    cell.userInteractionEnabled = NO;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textColor = [UIColor lightGrayColor];
}

- (void)didFinishRefresh {
    self.navigationItem.rightBarButtonItem.enabled = YES;
    NSArray *arrivals = _showFilteredArrivals ? _filteredArrivals : _allArrivals;
    UITableViewCell *cell;

    if (arrivals.count == 0) {
        cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    }
    else {
        cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:arrivals.count inSection:0]];
    }

    cell.userInteractionEnabled = YES;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.textLabel.textColor = [UIColor blackColor];
}

- (NSUInteger)sectionIndexForSectionType:(OBAStopSectionType)section {
    OBAStopV2 *stop = _result.stop;

    if (stop) {
        int offset = 0;

        if (_showServiceAlerts && _serviceAlerts.unreadCount > 0) {
            if (section == OBAStopSectionTypeServiceAlerts) return offset;

            offset++;
        }

        if (section == OBAStopSectionTypeArrivals) return offset;

        offset++;

        if ([_filteredArrivals count] != [_allArrivals count]) {
            if (section == OBAStopSectionTypeFilter) return offset;

            offset++;
        }

        if (_showActions) {
            if (section == OBAStopSectionTypeActions) return offset;

            offset++;
        }
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView serviceAlertCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [UITableViewCell tableViewCellForUnreadServiceAlerts:_serviceAlerts tableView:tableView];
}

- (NSArray*)arrivals {
    return (_showFilteredArrivals ? _filteredArrivals : _allArrivals);
}

- (UITableViewCell *)tableView:(UITableView *)tableView predictedArrivalCellForRowAtIndexPath:(NSIndexPath *)indexPath {

    NSArray *arrivals = [self arrivals];

    if ((arrivals.count == 0 && indexPath.row == 1) || (arrivals.count == indexPath.row && arrivals.count > 0)) {
        UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];
        cell.textLabel.text = NSLocalizedString(@"Load more arrivals", @"load more arrivals");
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.font = [UIFont systemFontOfSize:18];
        cell.accessoryType = UITableViewCellAccessoryNone;
        return cell;
    }
    else if (arrivals.count == 0) {
        UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];
        cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"No arrivals in the next %i minutes", @"[arrivals count] == 0"), self.minutesAfter];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.font = [UIFont systemFontOfSize:18];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        return cell;
    }
    else {
      
        //this adds a swipe gesture on the table cell to report that bus is full
      
        OBAArrivalAndDepartureV2 *pa = arrivals[indexPath.row];
        OBAArrivalEntryTableViewCell *cell = [_arrivalCellFactory createCellForArrivalAndDeparture:pa];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        // iOS 7 separator
        if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
            cell.separatorInset = UIEdgeInsetsZero;
        }

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 44)];
        label.text = NSLocalizedString(@"The Bus is Full!", @"");
        label.textColor = [UIColor whiteColor];

        UIColor *redColor = [UIColor colorWithRed:232.0 / 255.0 green:61.0 / 255.0 blue:14.0 / 255.0 alpha:1.0];

        @weakify(self);
        [cell setSwipeGestureWithView:label color:redColor mode:MCSwipeTableViewCellModeExit state:MCSwipeTableViewCellState3 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
            @strongify(self);

            NSString *alertMessage = [NSString stringWithFormat:NSLocalizedString(@"Help other riders and transit operators in %@ know when buses are full.",@""), self.appDelegate.modelDao.region.regionName];

            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Report that this bus is full", @"")
                                                                message:alertMessage
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel button label")
                                                      otherButtonTitles:NSLocalizedString(@"Report", @""), nil];

            alertView.tag = indexPath.row; // awful hack, but sufficient for our purposes for now. :P

            alertView.delegate = self;
            [alertView show];
        }];

        NSArray *problemReportsForTrip = self.problemReports[pa.tripId];

        if (problemReportsForTrip.count > 0) {
            OBAProblemReport *firstProblemReport = problemReportsForTrip[0];
            cell.problemReportType = firstProblemReport.problemReportType;
            cell.numberOfReports = problemReportsForTrip.count;
        }
        else {
            cell.problemReportType = OBAProblemReportTypeNone;
        }
        return cell;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

    if (buttonIndex != alertView.cancelButtonIndex) {

        NSArray *arrivals = [self arrivals];

        if (alertView.tag >= arrivals.count) {
            return;
        }

        OBAArrivalAndDepartureV2 *pa = self.arrivals[alertView.tag];
        OBAProblemReport *problemReport = [OBAProblemReport object];
        problemReport.tripID = pa.tripId;
        problemReport.problemReportType = OBAProblemReportTypeFullBus;

        if (pa.stop) {
            CLLocation *location = [[CLLocation alloc] initWithLatitude:pa.stop.lat longitude:pa.stop.lon];
            problemReport.location = [PFGeoPoint geoPointWithLocation:location];
        }

        @weakify(self);
        [problemReport saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            @strongify(self);

            if (succeeded) {
                [self createAlertViewForReportSubmissionNotification];
                [self reloadData];
            }
        }];
    }
    

    [self.tableView reloadData];
}

-(void)createAlertViewForReportSubmissionNotification {
    NSString *alertMessage = NSLocalizedString(@"Thanks for submitting your report", @"");

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"+10 points", @"")
                                                        message:alertMessage
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"Cancel button label")
                                              otherButtonTitles:nil, nil];
    [alertView show];
}

-(void)createAlertViewForReportSubmissionMilestoneNotification {
    NSString *alertMessage = NSLocalizedString(@"Thanks for submitting your report", @"");
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"+10 points", @"")
                                                        message:alertMessage
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"Cancel button label")
                                              otherButtonTitles:nil, nil];
    [alertView show];
}

- (void)determineFilterTypeCellText:(UITableViewCell *)filterTypeCell filteringEnabled:(bool)filteringEnabled {
    if (filteringEnabled) filterTypeCell.textLabel.text = NSLocalizedString(@"Show all arrivals", @"filteringEnabled");
    else filterTypeCell.textLabel.text = NSLocalizedString(@"Show filtered arrivals", @"!filteringEnabled");
}

- (UITableViewCell *)tableView:(UITableView *)tableView filterCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];

    [self determineFilterTypeCellText:cell filteringEnabled:_showFilteredArrivals];

    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.font = [UIFont systemFontOfSize:18];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.accessoryType = UITableViewCellAccessoryNone;

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView actionCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];

    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.font = [UIFont systemFontOfSize:18];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = nil;

    switch (indexPath.row) {
        case 0: {
            if ([self existingBookmark]) {
                cell.textLabel.text = NSLocalizedString(@"Edit Bookmark", @"case 0 edit");
            }
            else {
                cell.textLabel.text = NSLocalizedString(@"Add to Bookmarks", @"case 0");
            }

            break;
        }

        case 1: {
            cell.textLabel.text = NSLocalizedString(@"Report a Problem", @"self.navigationItem.title");
            break;
        }

        case 2: {
            cell.textLabel.text = NSLocalizedString(@"About This Stop", @"case 2");
            break;
        }

        case 3: {
            if (_serviceAlerts.totalCount == 0) {
                cell.textLabel.text = @"Service Alerts";
            }
            else {
                cell.textLabel.text = [NSString stringWithFormat:@"Service Alerts: %lu total", (unsigned long)_serviceAlerts.totalCount];
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
            cell.textLabel.text = NSLocalizedString(@"Filter & Sort Routes", @"case 1");
            break;
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectServiceAlertRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *situations = _result.situations;

    [OBASituationsViewController showSituations:situations withappDelegate:_appDelegate navigationController:self.navigationController args:nil];
}

- (void)tableView:(UITableView *)tableView didSelectTripRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *arrivals = _showFilteredArrivals ? _filteredArrivals : _allArrivals;

    if ((arrivals.count == 0 && indexPath.row == 1) || (arrivals.count == indexPath.row && arrivals.count > 0)) {
        [OBAAnalytics reportEventWithCategory:@"ui_action" action:@"button_press" label:@"Clicked load more arrivals button" value:nil];

        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        self.minutesAfter += 30;
        [self refresh];
    }
   else if (0 <= indexPath.row && indexPath.row < arrivals.count) {
        OBAArrivalAndDepartureV2 *arrivalAndDeparture = arrivals[indexPath.row];
        OBAArrivalAndDepartureViewController *vc = [[OBAArrivalAndDepartureViewController alloc] initWithApplicationDelegate:_appDelegate arrivalAndDeparture:arrivalAndDeparture];
        [self.navigationController pushViewController:vc animated:YES];
  

    }

}

- (void)tableView:(UITableView *)tableView didSelectActionRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0: {
            OBAEditStopBookmarkViewController *vc = nil;
            OBABookmarkV2 *bookmark = [self existingBookmark];

            if (!bookmark) {
                bookmark = [_appDelegate.modelDao createTransientBookmark:_result.stop];

                vc = [[OBAEditStopBookmarkViewController alloc] initWithApplicationDelegate:_appDelegate bookmark:bookmark editType:OBABookmarkEditNew];
            }
            else {
                vc = [[OBAEditStopBookmarkViewController alloc] initWithApplicationDelegate:_appDelegate bookmark:bookmark editType:OBABookmarkEditExisting];
            }

            [self.navigationController pushViewController:vc animated:YES];

            break;
        }

        case 1: {
            OBAReportProblemViewController *vc = [[OBAReportProblemViewController alloc] initWithApplicationDelegate:_appDelegate stop:_result.stop];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }

        case 2: {
            [self openURLS];
            break;
        }

        case 3: {
            NSArray *situations = _result.situations;
            [OBASituationsViewController showSituations:situations withappDelegate:_appDelegate navigationController:self.navigationController args:nil];
            break;
        }

        case 4: {
            OBAEditStopPreferencesViewController *vc = [[OBAEditStopPreferencesViewController alloc] initWithApplicationDelegate:_appDelegate stop:_result.stop];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
    }
}

- (IBAction)onRefreshButton:(id)sender {
    [self refresh];
}

NSComparisonResult predictedArrivalSortByDepartureTime(id pa1, id pa2, void *context) {
    return ((OBAArrivalAndDepartureV2 *)pa1).bestDepartureTime - ((OBAArrivalAndDepartureV2 *)pa2).bestDepartureTime;
}

NSComparisonResult predictedArrivalSortByRoute(id o1, id o2, void *context) {
    OBAArrivalAndDepartureV2 *pa1 = o1;
    OBAArrivalAndDepartureV2 *pa2 = o2;

    OBARouteV2 *r1 = pa1.route;
    OBARouteV2 *r2 = pa2.route;
    NSComparisonResult r = [r1 compareUsingName:r2];

    if (r == 0) r = predictedArrivalSortByDepartureTime(pa1, pa2, context);

    return r;
}

- (void)configureHeaderMapViewForStop:(OBAStopV2*)stop
{
    if (stop) {
        [self.mapView oba_setCenterCoordinate:CLLocationCoordinate2DMake(stop.lat, stop.lon) zoomLevel:15 animated:NO];
        self.stopName.text = stop.name;

        if (stop.direction) {
            self.stopNumber.text = [NSString stringWithFormat:@"%@ #%@ - %@ %@", NSLocalizedString(@"Stop", @"text"), stop.code, stop.direction, NSLocalizedString(@"bound", @"text")];
        }
        else {
            self.stopNumber.text = [NSString stringWithFormat:@"%@ #%@", NSLocalizedString(@"Stop", @"text"), stop.code];
        }

        if (stop.routeNamesAsString) self.stopRoutes.text = [stop routeNamesAsString];

        [_mapView addAnnotation:stop];

        if (self.showInHighContrast) {
            self.highContrastStopInfoButton.hidden = NO;
        }
        else {
            self.stopInfoButton.hidden = NO;
        }
    }
}

- (void)reloadData {
    OBAModelDAO *modelDao = _appDelegate.modelDao;

    OBAStopV2 *stop = _result.stop;

    NSArray *predictedArrivals = _result.arrivalsAndDepartures;

    [_allArrivals removeAllObjects];
    [_filteredArrivals removeAllObjects];

    [self configureHeaderMapViewForStop:stop];

    if (stop && predictedArrivals) {
        OBAStopPreferencesV2 *prefs = [modelDao stopPreferencesForStopWithId:stop.stopId];

        for (OBAArrivalAndDepartureV2 *pa in predictedArrivals) {
            [_allArrivals addObject:pa];

            if ([prefs isRouteIdEnabled:pa.routeId]) [_filteredArrivals addObject:pa];
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

    NSArray *allTripIDs = [self.allArrivals valueForKey:@"tripId"];

    if (allTripIDs.count > 0) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"tripID in %@", allTripIDs];
        PFQuery *query = [PFQuery queryWithClassName:NSStringFromClass(OBAProblemReport.class) predicate:predicate];

        @weakify(self);
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            @strongify(self);

            if (objects.count) {
                NSMutableDictionary *reports = [[NSMutableDictionary alloc] init];

                for (OBAProblemReport* report in objects) {

                    NSArray *reportsForTrip = reports[report.tripID];

                    if (!reportsForTrip) {
                        reportsForTrip = @[report];
                    }
                    else {
                        reportsForTrip = [reportsForTrip arrayByAddingObject:report];
                    }

                    reports[report.tripID] = reportsForTrip;
                }

                self.problemReports = [NSDictionary dictionaryWithDictionary:reports];
            }
            else {
                self.problemReports = @{};
            }

            if (error) {
                NSLog(@"Error trying to retrieve problem reports!");
            }
            
            [self.tableView reloadData];
        }];
    }

    _serviceAlerts = [modelDao getServiceAlertsModelForSituations:_result.situations];

    [self.tableView reloadData];
}

@end
