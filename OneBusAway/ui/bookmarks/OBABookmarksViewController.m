//
//  OBABookmarksViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/9/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBABookmarksViewController.h"
#import "OBAStopViewController.h"
#import "OBAEditStopBookmarkViewController.h"
#import "OBABookmarkedRouteRow.h"
#import "OBAArrivalAndDepartureSectionBuilder.h"
#import "OBACollapsingHeaderView.h"
#import "OBABookmarkGroupsViewController.h"
#import "OBATableCell.h"

static NSTimeInterval const kRefreshTimerInterval = 30.0;
static NSUInteger const kMinutes = 30;

@interface OBABookmarksViewController ()
@property(nonatomic,strong) NSTimer *refreshBookmarksTimer;
@property(nonatomic,strong) NSMutableDictionary<OBABookmarkV2*,NSArray<OBAArrivalAndDepartureV2*>*> *bookmarksAndDepartures;
@end

@implementation OBABookmarksViewController

- (instancetype)init {
    self = [super init];

    if (self) {
        self.title = NSLocalizedString(@"Bookmarks", @"");
        self.tabBarItem.image = [UIImage imageNamed:@"Favorites"];
        self.tabBarItem.selectedImage = [UIImage imageNamed:@"Favorites_Selected"];
        self.emptyDataSetTitle = NSLocalizedString(@"No Bookmarks", @"");
        self.emptyDataSetDescription = NSLocalizedString(@"Tap 'Add to Bookmarks' from a stop to save a bookmark to this screen.", @"");
        _bookmarksAndDepartures = [[NSMutableDictionary alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [self cancelTimer];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.estimatedRowHeight = 80.f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;

    self.tableView.allowsSelectionDuringEditing = YES;

    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Groups", @"") style:UIBarButtonItemStylePlain target:self action:@selector(editGroups)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    OBALogFunction();

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];

    NSMutableString *title = [NSMutableString stringWithString:NSLocalizedString(@"Bookmarks", @"")];
    if (self.currentRegion) {
        [title appendFormat:@" - %@", self.currentRegion.regionName];
    }
    self.navigationItem.title = title;

    [self loadData];

    [self startTimer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];

    [self cancelTimer];
}

#pragma mark - OBANavigationTargetAware

- (OBANavigationTarget*)navigationTarget {
    return [OBANavigationTarget navigationTarget:OBANavigationTargetTypeBookmarks];
}

#pragma mark - Notifications

- (void)applicationDidEnterBackground:(NSNotification*)note {
    // Wipe out the 'scheduled arrival/departure' footer message when the
    // application is backgrounded to ensure that it doesn't hang out forever.
    self.tableFooterView = nil;
}

#pragma mark - Refresh Bookmarks

- (void)cancelTimer {
    [self.refreshBookmarksTimer invalidate];
    self.refreshBookmarksTimer = nil;
}

- (void)startTimer {
    @synchronized (self) {
        if (!self.refreshBookmarksTimer) {
            self.refreshBookmarksTimer = [NSTimer scheduledTimerWithTimeInterval:kRefreshTimerInterval target:self selector:@selector(refreshBookmarkDepartures:) userInfo:nil repeats:YES];
            [self refreshBookmarkDepartures:nil];
        }
    }
}

- (void)refreshBookmarkDepartures:(NSTimer*)timer {
    NSArray<OBABookmarkV2*> *allBookmarks = [self.modelDAO bookmarksMatchingPredicate:[NSPredicate predicateWithFormat:@"%K == %@", NSStringFromSelector(@selector(bookmarkVersion)), @(OBABookmarkVersion260)]];

    for (OBABookmarkV2 *bookmark in allBookmarks) {
        [self refreshDataForBookmark:bookmark];
    }
}

+ (NSArray<OBAUpcomingDeparture*>*)upcomingDeparturesFromArrivalsAndDepartures:(NSArray<OBAArrivalAndDepartureV2*>*)matchingDepartures {
    NSMutableArray *upcomingDepartures = [NSMutableArray array];
    for (OBAArrivalAndDepartureV2 *dep in matchingDepartures) {
        // only show departures.
        if (dep.arrivalDepartureState == OBAArrivalDepartureStateArriving) {
            continue;
        }
        [upcomingDepartures addObject:[[OBAUpcomingDeparture alloc] initWithDepartureDate:dep.bestDeparture departureStatus:dep.departureStatus]];
    }
    return [NSArray arrayWithArray:upcomingDepartures];
}

+ (BOOL)hasScheduledDepartures:(NSArray<OBAArrivalAndDepartureV2*>*)departures {
    for (OBAArrivalAndDepartureV2* dep in departures) {
        if (!dep.hasRealTimeData) {
            return YES;
        }
    }
    return NO;
}

- (void)refreshDataForBookmark:(OBABookmarkV2*)bookmark {
    OBABookmarkedRouteRow *row = [self rowForBookmarkVersion260:bookmark];

    [self.modelService requestStopForID:bookmark.stopId minutesBefore:0 minutesAfter:kMinutes].then(^(OBAArrivalsAndDeparturesForStopV2 *response) {
        NSArray<OBAArrivalAndDepartureV2*> *matchingDepartures = [bookmark matchingArrivalsAndDeparturesForStop:response];
        BOOL missingRealTimeData = [self.class hasScheduledDepartures:matchingDepartures];

        if (matchingDepartures.count > 0) {
            row.supplementaryMessage = nil;
        }
        else {
            row.supplementaryMessage = [NSString stringWithFormat:NSLocalizedString(@"%@: No departure scheduled for the next %@ minutes", @""), bookmark.routeShortName, @(kMinutes)];
        }

        // This will result in some 'false positive' instances where the
        // footer is displayed even when there is all real time data.
        // Hopefully that will be ok. Let's see though, eh?
        if (missingRealTimeData && !self.tableFooterView) {
            self.tableFooterView = [OBAUIBuilder footerViewWithText:[OBAStrings scheduledDepartureExplanation] maximumWidth:CGRectGetWidth(self.tableView.frame)];
        }

        row.upcomingDepartures = [self.class upcomingDeparturesFromArrivalsAndDepartures:matchingDepartures];
        [self.class updateBookmarkedRouteRow:row withArrivalAndDeparture:matchingDepartures.firstObject];
        self.bookmarksAndDepartures[bookmark] = matchingDepartures;
        row.state = OBABookmarkedRouteRowStateComplete;
    }).catch(^(NSError *error) {
        DDLogError(@"Failed to load departure for bookmark: %@", error);
        row.upcomingDepartures = nil;
        row.state = OBABookmarkedRouteRowStateError;
        row.supplementaryMessage = [error localizedDescription];
    }).always(^{
        NSIndexPath *indexPath = [self indexPathForModel:bookmark];

        if (indexPath.section >= self.sections.count) {
            return;
        }

        OBATableSection *section = self.sections[indexPath.section];

        if (indexPath.row >= section.rows.count) {
            return;
        }

        // There seems to be a circumstance when the app first
        // launches where this request is canceled almost as soon
        // as it starts. For reasons I cannot ascertain, PromiseKit
        // doesn't bother sending us the error, which means we end
        // up in the `finally` block instead of the error block.
        // So, on the occasions when this happens, simply retry the
        // download.
        if (row.state == OBABookmarkedRouteRowStateLoading) {
            [self refreshDataForBookmark:bookmark];
        }

        // if our expectation of what's in the table is in sync with reality,
        // then we will reload just the row at indexPath. Otherwise, we will
        // reload the entire table.
        if ([self replaceRowAtIndexPath:indexPath withRow:row]) {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }
        else {
            [self.tableView reloadData];
        }
    });
}

#pragma mark - Reachability

- (void)reachabilityChanged:(NSNotification*)note {
    // Automatically refresh whenever the connection goes from offline -> online
    if ([OBAApplication sharedApplication].isServerReachable) {
        [self startTimer];
    }
    else {
        [self cancelTimer];
    }
}

#pragma mark - Data Loading

- (void)loadData {
    [self loadDataWithTableReload:YES];
}

- (void)loadDataWithTableReload:(BOOL)tableReload {
    NSMutableArray *sections = [[NSMutableArray alloc] init];

    // If there are no bookmarks anywhere in the system, ungrouped or otherwise, then skip
    // over this code and instead show the empty table message.
    if (self.modelDAO.bookmarkGroups.count != 0 || self.modelDAO.ungroupedBookmarks.count != 0) {
        for (OBABookmarkGroup *group in [self.modelDAO.bookmarkGroups sortedArrayUsingSelector:@selector(compare:)]) {
            OBATableSection *section = [self tableSectionFromBookmarks:group.bookmarks group:group];
            [sections addObject:section];
        }

        OBATableSection *looseBookmarks = [self tableSectionFromBookmarks:self.modelDAO.ungroupedBookmarks group:nil];
        [sections addObject:looseBookmarks];
    }

    self.sections = sections;

    if (tableReload) {
        [self.tableView reloadData];
    }
}

#pragma mark - Actions

- (void)editGroups {
    OBABookmarkGroupsViewController *groups = [[OBABookmarkGroupsViewController alloc] init];
    groups.enableGroupEditing = YES;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:groups];
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - UITableView Editing

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // only rows that are backed by models can be edited.
    return !![self rowAtIndexPath:indexPath].model;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self deleteRowAtIndexPath:indexPath];
    }
}

#pragma mark - Table Row Actions (context menu thingy)

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {

    OBABaseRow *tableRow = [self rowAtIndexPath:indexPath];

    if (!tableRow.model) {
        // rows not backed by models don't get actions.
        return nil;
    }

    NSMutableArray<UITableViewRowAction *> *actions = [NSMutableArray array];

    UITableViewRowAction *delete = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:NSLocalizedString(@"Delete", @"Title of delete bookmark row action.") handler:^(UITableViewRowAction *action, NSIndexPath *rowIndexPath) {
        [self deleteRowAtIndexPath:rowIndexPath];
    }];
    [actions addObject:delete];

    if (tableRow.editAction) {
        UITableViewRowAction *edit = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:NSLocalizedString(@"Edit", @"Title of edit bookmark/group row action.") handler:^(UITableViewRowAction *action, NSIndexPath *rowIndexPath) {
            tableRow.editAction();
        }];
        [actions addObject:edit];
    }
    return actions;
}

#pragma mark - Moving Table Cells

- (BOOL)tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Only rows backed by a model can be moved.
    return !![self rowAtIndexPath:indexPath].model;
}

- (void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    OBABaseRow *tableRow = [self rowAtIndexPath:sourceIndexPath];
    OBATableSection *sourceSection = self.sections[sourceIndexPath.section];
    OBATableSection *destinationSection = self.sections[destinationIndexPath.section];
    OBABookmarkV2 *bookmark = tableRow.model;

    OBAGuard(bookmark) else {
        return;
    }

    OBABookmarkGroup *destinationGroup = self.sections[destinationIndexPath.section].model;

    [tableView beginUpdates];

    [self.modelDAO moveBookmark:bookmark toIndex:destinationIndexPath.row inGroup:destinationGroup];

    NSMutableArray *sourceRows = [NSMutableArray arrayWithArray:sourceSection.rows];
    [sourceRows removeObjectAtIndex:sourceIndexPath.row];
    sourceSection.rows = [NSArray arrayWithArray:sourceRows];

    NSMutableArray *destinationRows = [NSMutableArray arrayWithArray:destinationSection.rows];
    [destinationRows insertObject:tableRow atIndex:destinationIndexPath.row];
    destinationSection.rows = [NSArray arrayWithArray:destinationRows];

    [tableView endUpdates];
}

#pragma mark - Accessors

- (OBARegionV2*)currentRegion {
    return [OBAApplication sharedApplication].modelDao.currentRegion;
}

- (OBAModelDAO*)modelDAO {
    if (!_modelDAO) {
        _modelDAO = [OBAApplication sharedApplication].modelDao;
    }
    return _modelDAO;
}

- (OBAModelService*)modelService {
    if (!_modelService) {
        _modelService = [OBAApplication sharedApplication].modelService;
    }
    return _modelService;
}

#pragma mark - Private

/*
 TODO: aggressively refactor me! This code is really ugly, and can definitely stand to be improved.
 */
- (OBATableSection*)tableSectionFromBookmarks:(NSArray<OBABookmarkV2*>*)bookmarks group:(nullable OBABookmarkGroup*)group {
    NSArray<OBABaseRow*>* rows = @[];

    NSString *groupName = group ? group.name : NSLocalizedString(@"Bookmarks", @"");
    BOOL groupOpen = group ? group.open : self.modelDAO.ungroupedBookmarksOpen;

    if (groupOpen) {
        rows = [self tableRowsFromBookmarks:bookmarks];
    }

    OBATableSection *section = [[OBATableSection alloc] initWithTitle:groupName rows:rows];
    section.model = group;
    OBACollapsingHeaderView *header = [[OBACollapsingHeaderView alloc] initWithFrame:CGRectMake(0, 0, 100, 35)];
    header.isOpen = groupOpen;
    header.title = groupName;
    [header setTapped:^(BOOL open) {
        if (group) {
            group.open = open;
            [self.modelDAO persistGroups];
        }
        else {
            self.modelDAO.ungroupedBookmarksOpen = open;
        }
        section.rows = open ? [self tableRowsFromBookmarks:bookmarks] : @[];

        if (!section) {
            [self.tableView reloadData];
            return;
        }

        NSUInteger index = [self.sections indexOfObject:section];
        if (index == NSNotFound) {
            [self.tableView reloadData];
            return;
        }

        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
    }];
    section.headerView = header;

    return section;
}

- (NSArray*)tableRowsFromBookmarks:(NSArray<OBABookmarkV2*>*)bookmarks {
    NSMutableArray *rows = [NSMutableArray new];

    for (OBABookmarkV2 *bm in bookmarks) {
        if (![self.class isValidBookmark:bm forRegion:[self currentRegion]]) {
            continue;
        }

        OBABaseRow *row = [self tableRowForBookmark:bm];

        [rows addObject:row];
    }

    return rows;
}

+ (BOOL)isValidBookmark:(OBABookmarkV2*)bookmark forRegion:(OBARegionV2*)region {
    if (bookmark.stopId.length == 0) {
        // bookmark was somehow corrupted. Skip it and continue on.
        DDLogError(@"Corrupted bookmark: %@", bookmark);
        return NO;
    }

    if (bookmark.regionIdentifier != NSNotFound && bookmark.regionIdentifier != region.identifier) {
        // We are special-casing bookmarks that don't have a region set on them, as there's no way to know
        // for sure which region they belong to. However, if this bookmark has a valid regionIdentifier and
        // the current region's identifier doesn't match the bookmark, then this bookmark belongs to a
        // different region. Skip it.
        return NO;
    }

    return YES;
}

#pragma mark - Row Builders

/**
 This is the entry point to all of the row builders.
 */
- (OBABaseRow*)tableRowForBookmark:(OBABookmarkV2*)bookmark {
    if (bookmark.bookmarkVersion > OBABookmarkVersion252) {
        return [self rowForBookmarkVersion260:bookmark];
    }
    else {
        return [self rowForBookmarkVersion252:bookmark];
    }
}

- (OBABaseRow*)rowForBookmarkVersion252:(OBABookmarkV2*)bm {
    OBATableRow *row = [[OBATableRow alloc] initWithTitle:bm.name action:^{
        OBAStopViewController *controller = [[OBAStopViewController alloc] initWithStopID:bm.stopId];
        [self.navigationController pushViewController:controller animated:YES];
    }];

    [self performCommonBookmarkRowConfiguration:row forBookmark:bm];

    return row;
}

- (OBABookmarkedRouteRow *)rowForBookmarkVersion260:(OBABookmarkV2*)bookmark {
    OBABookmarkedRouteRow *row = [[OBABookmarkedRouteRow alloc] initWithAction:^(OBABaseRow *baseRow) {
        OBAStopViewController *controller = [[OBAStopViewController alloc] initWithStopID:bookmark.stopId];
        [self.navigationController pushViewController:controller animated:YES];
    }];

    row.bookmark = bookmark;
    [self performCommonBookmarkRowConfiguration:row forBookmark:bookmark];

    // We only have this object available once the associated network request completes.
    OBAArrivalAndDepartureV2 *arrivalAndDeparture = self.bookmarksAndDepartures[bookmark].firstObject;
    [self.class updateBookmarkedRouteRow:row withArrivalAndDeparture:arrivalAndDeparture];

    row.upcomingDepartures = [self.class upcomingDeparturesFromArrivalsAndDepartures:self.bookmarksAndDepartures[bookmark]];

    return row;
}

+ (void)updateBookmarkedRouteRow:(OBABookmarkedRouteRow*)row withArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    if (!arrivalAndDeparture) {
        return;
    }
    row.routeName = arrivalAndDeparture.bestAvailableName;
    row.destination = arrivalAndDeparture.tripHeadsign;
    row.statusText = arrivalAndDeparture.statusText;
}

- (void)performCommonBookmarkRowConfiguration:(OBABaseRow*)row forBookmark:(OBABookmarkV2*)bookmark {
    row.model = bookmark;
    row.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    [row setEditAction:^{
        OBAEditStopBookmarkViewController *editor = [[OBAEditStopBookmarkViewController alloc] initWithBookmark:bookmark];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:editor];
        [self presentViewController:nav animated:YES completion:nil];
    }];

    [row setDeleteModel:^(OBABaseRow *deleteRow){
        [self.modelDAO removeBookmark:deleteRow.model];
    }];
}

@end
