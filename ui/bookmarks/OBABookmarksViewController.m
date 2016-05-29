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

@implementation OBABookmarksViewController

- (instancetype)init {
    self = [super init];

    if (self) {
        self.tabBarItem.title = NSLocalizedString(@"Bookmarks", @"Bookmarks tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"Bookmarks"];
        self.emptyDataSetTitle = NSLocalizedString(@"No Bookmarks", @"");
        self.emptyDataSetDescription = NSLocalizedString(@"Tap 'Add to Bookmarks' from a stop to save a bookmark to this screen.", @"");
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.estimatedRowHeight = 80.f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;

    self.tableView.allowsSelectionDuringEditing = YES;
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSString *title = nil;
    if (self.currentRegion) {
        title = [NSString stringWithFormat:NSLocalizedString(@"Bookmarks - %@", @""), self.currentRegion.regionName];
    }
    else {
        title = NSLocalizedString(@"Bookmarks", @"");
    }
    self.navigationItem.title = title;

    [self loadData];
}

#pragma mark -  OBANavigationTargetAware

- (OBANavigationTarget *)navigationTarget {
    return [OBANavigationTarget target:OBANavigationTargetTypeBookmarks];
}

#pragma mark - Data Loading

- (void)loadData {
    OBAModelDAO *modelDAO = [OBAApplication sharedApplication].modelDao;

    NSMutableArray *sections = [[NSMutableArray alloc] init];

    for (OBABookmarkGroup *group in modelDAO.bookmarkGroups) {
        NSArray *rows = [self tableRowsFromBookmarks:group.bookmarks];
        OBATableSection *section = [[OBATableSection alloc] initWithTitle:group.name rows:rows];
        [sections addObject:section];
    }

    OBATableSection *looseBookmarks = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"Bookmarks", @"") rows:[self tableRowsFromBookmarks:modelDAO.ungroupedBookmarks]];
    if (looseBookmarks.rows.count > 0) {
        [sections addObject:looseBookmarks];
    }

    self.sections = sections;
    [self.tableView reloadData];
}

#pragma mark - Editing

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];

    UIBarButtonItem *rightBarItem = nil;

    if (editing) {
        rightBarItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add Group", @"") style:UIBarButtonItemStylePlain target:self action:@selector(addBookmarkGroup)];
    }

    self.navigationItem.rightBarButtonItem = rightBarItem;
}

#pragma mark - Actions

- (void)addBookmarkGroup {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Add Bookmark Group", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"Name of Group", @"");
    }];

    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Save", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        OBABookmarkGroup *group = [[OBABookmarkGroup alloc] initWithName:alertController.textFields[0].text];
        [self.modelDAO saveBookmarkGroup:group];
        [self loadData];
    }]];

    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UITableView

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self deleteRowAtIndexPath:indexPath tableView:tableView];
    }
}

- (void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    OBABookmarkGroup *sourceGroup = sourceIndexPath.section == self.modelDAO.bookmarkGroups.count ? nil : self.modelDAO.bookmarkGroups[sourceIndexPath.section];
    OBABookmarkGroup *destinationGroup = destinationIndexPath.section == self.modelDAO.bookmarkGroups.count ? nil : self.modelDAO.bookmarkGroups[destinationIndexPath.section];

    OBABookmarkV2 *bookmark = [self.modelDAO bookmarkAtIndex:sourceIndexPath.row inGroup:sourceGroup];

    if (bookmark) {
        [self.modelDAO moveBookmark:bookmark toIndex:destinationIndexPath.row inGroup:destinationGroup];
    }
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:NSLocalizedString(@"Delete", @"Title of delete bookmark row action.") handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        [self deleteRowAtIndexPath:indexPath tableView:tableView];
    }];

    return @[action];
}

#pragma mark - Table Row Deletion

- (void)deleteRowAtIndexPath:(NSIndexPath*)indexPath tableView:(UITableView*)tableView {
    OBATableSection *tableSection = self.sections[indexPath.section];
    OBATableRow *tableRow = tableSection.rows[indexPath.row];

    NSMutableArray *rows = [NSMutableArray arrayWithArray:tableSection.rows];
    [rows removeObjectAtIndex:indexPath.row];
    tableSection.rows = rows;

    if (tableRow.deleteModel) {
        tableRow.deleteModel();
    }

    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Accessors

- (OBARegionV2*)currentRegion {
    return [OBAApplication sharedApplication].modelDao.region;
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

- (NSArray<OBATableRow*>*)tableRowsFromBookmarks:(NSArray<OBABookmarkV2*>*)bookmarks {
    NSMutableArray *rows = [NSMutableArray array];

    for (OBABookmarkV2 *bm in bookmarks) {

        if (bm.stopId.length == 0) {
            // bookmark was somehow corrupted. Skip it and continue on.
            NSLog(@"Corrupted bookmark: %@", bm);
            continue;
        }

        if (bm.regionIdentifier != NSNotFound && bm.regionIdentifier != [self currentRegion].identifier) {
            // We are special-casing bookmarks that don't have a region set on them, as there's no way to know
            // for sure which region they belong to. However, if this bookmark has a valid regionIdentifier and
            // the current region's identifier doesn't match the bookmark, then this bookmark belongs to a
            // different region. Skip it.
            continue;
        }

        OBABaseRow *row = [self tableRowForBookmark:bm];

        [rows addObject:row];
    }

    return rows;
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

- (OBABaseRow*)rowForBookmarkVersion260:(OBABookmarkV2*)bookmark {
    OBABookmarkedRouteRow *row = [[OBABookmarkedRouteRow alloc] initWithAction:^{
        OBAStopViewController *controller = [[OBAStopViewController alloc] initWithStopID:bookmark.stopId];
        [self.navigationController pushViewController:controller animated:YES];
    }];
    row.bookmark = bookmark;

    [self.modelService requestStopForID:bookmark.stopId minutesBefore:0 minutesAfter:35].then(^(OBAArrivalsAndDeparturesForStopV2 *response) {
        NSArray<OBAArrivalAndDepartureV2*> *matchingDepartures = [bookmark matchingArrivalsAndDeparturesForStop:response];
        ((OBABookmarkedRouteRow*)row).nextDeparture = matchingDepartures.firstObject;
        NSIndexPath *indexPath = [self indexPathForRow:row];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }).catch(^(NSError *error) {
        NSLog(@"Failed to load departure for bookmark: %@", error);
    });

    [self performCommonBookmarkRowConfiguration:row forBookmark:bookmark];

    return row;
}

- (void)performCommonBookmarkRowConfiguration:(OBABaseRow*)row forBookmark:(OBABookmarkV2*)bookmark {
    row.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    [row setEditAction:^{
        OBAEditStopBookmarkViewController *editor = [[OBAEditStopBookmarkViewController alloc] initWithBookmark:bookmark];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:editor];
        [self presentViewController:nav animated:YES completion:nil];
    }];

    [row setDeleteModel:^{
        [[OBAApplication sharedApplication].modelDao removeBookmark:bookmark];
    }];
}

@end