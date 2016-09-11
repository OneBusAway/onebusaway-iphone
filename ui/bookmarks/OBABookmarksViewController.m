//
//  OBABookmarksViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/9/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBABookmarksViewController.h"
#import "OBAApplication.h"
#import "OBABookmarkGroup.h"
#import "OBAStopViewController.h"
#import "OBAEditStopBookmarkViewController.h"
#import <OBAKit/OBAModelDAO.h>
#import <OBAKit/OBAArrivalAndDepartureV2.h>
#import "OBABookmarkedRouteRow.h"
#import "OBAArrivalAndDepartureSectionBuilder.h"
#import "OBAClassicDepartureRow.h"
#import "OBACollapsingHeaderView.h"
#import "OBABookmarkGroupsViewController.h"
#import "OBATableCell.h"

static NSTimeInterval const kRefreshTimerInterval = 30.0;
static NSUInteger const kMinutes = 30;

@interface OBABookmarksViewController ()
@property(nonatomic,strong) NSTimer *refreshBookmarksTimer;
@property(nonatomic,strong) NSMutableDictionary<OBABookmarkV2*,OBAArrivalAndDepartureV2*> *bookmarksAndDepartures;
@end

@implementation OBABookmarksViewController

- (instancetype)init {
    self = [super init];

    if (self) {
        self.title = NSLocalizedString(@"Bookmarks", @"");
        self.tabBarItem.title = NSLocalizedString(@"Bookmarks", @"Bookmarks tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"Bookmarks"];
        self.emptyDataSetTitle = NSLocalizedString(@"No Bookmarks", @"");
        self.emptyDataSetDescription = NSLocalizedString(@"Tap 'Add to Bookmarks' from a stop to save a bookmark to this screen.", @"");
        _bookmarksAndDepartures = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    [self cancelTimer];
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

- (void)refreshDataForBookmark:(OBABookmarkV2*)bookmark {
    OBABookmarkedRouteRow *row = [self rowForBookmarkVersion260:bookmark];

    [self.modelService requestStopForID:bookmark.stopId minutesBefore:0 minutesAfter:kMinutes].then(^(OBAArrivalsAndDeparturesForStopV2 *response) {
        NSArray<OBAArrivalAndDepartureV2*> *matchingDepartures = [bookmark matchingArrivalsAndDeparturesForStop:response];
        OBAArrivalAndDepartureV2 *departure = matchingDepartures.firstObject;

        if (departure) {
            self.bookmarksAndDepartures[bookmark] = departure;
            row.supplementaryMessage = nil;
        }
        else {
            row.supplementaryMessage = [NSString stringWithFormat:NSLocalizedString(@"%@: No departure scheduled for the next %@ minutes", @""), bookmark.routeShortName, @(kMinutes)];
        }

        row.nextDeparture = departure;
        row.state = OBABookmarkedRouteRowStateComplete;
    }).catch(^(NSError *error) {
        NSLog(@"Failed to load departure for bookmark: %@", error);
        row.nextDeparture = nil;
        row.state = OBABookmarkedRouteRowStateError;
        row.supplementaryMessage = [error localizedDescription];
    }).finally(^{
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

#pragma mark -  OBANavigationTargetAware

- (OBANavigationTarget *)navigationTarget {
    return [OBANavigationTarget target:OBANavigationTargetTypeBookmarks];
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
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:[self.sections indexOfObject:section]];
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
        NSLog(@"Corrupted bookmark: %@", bookmark);
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
    OBABookmarkedRouteRow *row = [[OBABookmarkedRouteRow alloc] initWithAction:^(OBABaseRow *baseRow){
        OBAStopViewController *controller = [[OBAStopViewController alloc] initWithStopID:bookmark.stopId];
        [self.navigationController pushViewController:controller animated:YES];
    }];
    row.bookmark = bookmark;
    row.nextDeparture = self.bookmarksAndDepartures[bookmark];

    [self performCommonBookmarkRowConfiguration:row forBookmark:bookmark];

    return row;
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
