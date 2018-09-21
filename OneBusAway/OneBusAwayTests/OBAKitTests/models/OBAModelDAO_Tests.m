//
//  OBAModelDAO_Tests.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 4/3/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <XCTest/XCTest.h>
@import OBAKit;
#import "OBATestHelpers.h"
#import "OBATestHarnessPersistenceLayer.h"

@interface OBAModelDAO_Tests : XCTestCase
@property(nonatomic,strong) OBATestHarnessPersistenceLayer *persistenceLayer;
@property(nonatomic,strong) OBAModelDAO *modelDAO;
@end

@implementation OBAModelDAO_Tests

- (void)setUp {
    [super setUp];

    self.persistenceLayer = [[OBATestHarnessPersistenceLayer alloc] init];
    self.modelDAO = [[OBAModelDAO alloc] initWithModelPersistenceLayer:self.persistenceLayer];
    self.modelDAO.currentRegion = [OBATestHelpers pugetSoundRegion];
}

#pragma mark - hideFutureLocationWarnings

- (void)testHideFutureLocationWarnings {
    XCTAssertFalse(self.persistenceLayer.hideFutureLocationWarnings);
    self.modelDAO.hideFutureLocationWarnings = YES;
    XCTAssertTrue(self.persistenceLayer.hideFutureLocationWarnings);
    XCTAssertTrue(self.modelDAO.hideFutureLocationWarnings);
}

#pragma mark - Bookmark Searching w/ Predicate

- (void)testANilPredicateReturnsEmptyArray {
    NSPredicate *blah = nil;
    NSArray *output = [self.modelDAO bookmarksMatchingPredicate:blah];
    XCTAssertEqualObjects([NSArray array], output);
}

- (void)testBasicPredicatesWork {
    OBABookmarkV2 *bookmark = [self generateBookmarkWithName:@"hello"];
    NSArray *bookmarkArray = @[bookmark];
    [self.modelDAO saveBookmark:bookmark];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", bookmark.name];

    NSArray *matches = [self.modelDAO bookmarksMatchingPredicate:predicate];

    XCTAssertEqualObjects(matches, bookmarkArray);
}

#pragma mark - Bookmarks

- (void)testTransientBookmarksDontTouchPersistenceLayer {
    [self generateBookmarkWithName:@"It's a stop!"];
    XCTAssertEqual(self.persistenceLayer.readBookmarks.count, 0);
}

- (void)testBookmarkForArrivalAndDepartureWithNilDoesntCrash {
    OBAArrivalAndDepartureV2 *nilStop = nil;
    XCTAssertNil([self.modelDAO bookmarkForArrivalAndDeparture:nilStop]);
}

- (void)testBookmarkForAAndD {
    OBAStopV2 *stop = [self.class generateStop];
    OBAArrivalAndDepartureV2 *arrivalAndDeparture = [self generateArrivalAndDepartureWithStop:stop];
    OBABookmarkV2 *bookmark = [[OBABookmarkV2 alloc] initWithArrivalAndDeparture:arrivalAndDeparture region:self.modelDAO.currentRegion];
    [self.modelDAO saveBookmark:bookmark];

    OBABookmarkV2 *match = [self.modelDAO bookmarkForArrivalAndDeparture:arrivalAndDeparture];
    XCTAssertEqualObjects(match, bookmark);
}

- (void)testBookmarkForAAndDInGroup {
    OBAStopV2 *stop = [self.class generateStop];
    OBAArrivalAndDepartureV2 *arrivalAndDeparture = [self generateArrivalAndDepartureWithStop:stop];
    OBABookmarkV2 *bookmark = [[OBABookmarkV2 alloc] initWithArrivalAndDeparture:arrivalAndDeparture region:self.modelDAO.currentRegion];
    OBABookmarkGroup *group = ({
        OBABookmarkGroup *g = [[OBABookmarkGroup alloc] initWithName:@"yay my group"];
        [g addBookmark:bookmark];
        g;
    });
    [self.modelDAO saveBookmarkGroup:group];

    OBABookmarkV2 *match = [self.modelDAO bookmarkForArrivalAndDeparture:arrivalAndDeparture];

    XCTAssertEqualObjects(match, bookmark);
}

- (void)testAllBookmarksAggregatesLooseAndGroupedBookmarks {
    OBABookmarkV2 *looseBookmark = [self generateBookmarkWithName:nil];
    OBABookmarkV2 *groupedBookmark = [self generateBookmarkWithName:nil];
    OBABookmarkGroup *group = [self groupWithBookmark:groupedBookmark];
    [self.modelDAO saveBookmark:looseBookmark];
    [self.modelDAO saveBookmarkGroup:group];

    NSSet *allBookmarks = [NSSet setWithArray:[self.modelDAO bookmarksForCurrentRegion]];
    NSSet *local = [NSSet setWithArray:@[looseBookmark,groupedBookmark]];

    XCTAssertEqualObjects(allBookmarks, local);
}

#pragma mark - Test -bookmarkAtIndex:inGroup:

- (void)testBookmarkAtIndexInGroupReturnsNilForOutOfBoundIndexes {
    NSUInteger outOfBounds = self.modelDAO.ungroupedBookmarks.count + 1;
    XCTAssertNil([self.modelDAO bookmarkAtIndex:outOfBounds inGroup:nil]);
}

#pragma mark - Create New Bookmark

- (void)testAddNewLooseBookmark {
    OBABookmarkV2 *looseBookmark = [self generateBookmarkWithName:nil];
    [self.modelDAO saveBookmark:looseBookmark];
    XCTAssertEqual(self.modelDAO.ungroupedBookmarks.count, 1);
    XCTAssertEqualObjects(self.persistenceLayer.readBookmarks, @[looseBookmark]);
}

- (void)testAddNewGroupedBookmark {
    OBABookmarkV2 *groupedBookmark = [self generateBookmarkWithName:nil];
    OBABookmarkGroup *group = [self groupWithBookmark:groupedBookmark];
    [self.modelDAO saveBookmarkGroup:group];

    // 2 = this one + today bookmark group.
    XCTAssertEqual(self.persistenceLayer.readBookmarkGroups.count, 2);
}

#pragma mark - Save Existing Bookmark

- (void)testSaveExistingBookmarkWhenItDoesntYetExist {
    OBABookmarkV2 *bookmark = [self generateBookmarkWithName:nil];
    XCTAssertEqual(self.modelDAO.ungroupedBookmarks.count,0);
    [self.modelDAO saveBookmark:bookmark];
    XCTAssertEqual(self.persistenceLayer.readBookmarks.count, 1);
}

- (void)testSaveExistingBookmarkWhenItBelongsToAGroup {
    OBABookmarkV2 *bookmark = [self generateBookmarkWithName:nil];
    OBABookmarkGroup *group = [self groupWithBookmark:bookmark];
    [self.modelDAO saveBookmarkGroup:group];
    XCTAssertEqual(self.modelDAO.ungroupedBookmarks.count,0);
    XCTAssertEqual(self.persistenceLayer.readBookmarks.count, 0);
    XCTAssertEqual(self.modelDAO.bookmarkGroups.count, 2);
    XCTAssertEqual(self.persistenceLayer.readBookmarkGroups.count, 2);
    XCTAssertEqual([self.persistenceLayer.readBookmarkGroups[1] bookmarks].count, 1);
    bookmark.name = @"I AM NOW CHANGED";
    [self.modelDAO saveBookmark:bookmark];
    XCTAssertEqual(self.persistenceLayer.readBookmarks.count, 0);
    XCTAssertEqualObjects([[[self.persistenceLayer.readBookmarkGroups[1] bookmarks] firstObject] name], bookmark.name);
}

- (void)testSavingLoosePreexistingBookmark {
    NSString *bookmarkName = @"NEW TITLE - LOREM IPSUM DOLOR SIT AMET";
    OBABookmarkV2 *bookmark = [self generateBookmarkWithName:nil];
    [self.modelDAO saveBookmark:bookmark];
    bookmark.name = bookmarkName;
    [self.modelDAO saveBookmark:bookmark];
    XCTAssertEqualObjects([self.persistenceLayer.readBookmarks.firstObject name], bookmarkName);
}

#pragma mark - Move Bookmark

- (void)testMoveBookmarkFromPositionZeroToOneInLoose {
    OBABookmarkV2 *pos0 = [self generateBookmarkWithName:@"Pos 0"];
    OBABookmarkV2 *pos1 = [self generateBookmarkWithName:@"Pos 1"];

    [self.modelDAO saveBookmark:pos0];
    [self.modelDAO saveBookmark:pos1];

    XCTAssertEqualObjects(self.modelDAO.ungroupedBookmarks[0], pos0);
    XCTAssertEqualObjects(self.persistenceLayer.readBookmarks[0], pos0);

    [self.modelDAO moveBookmark:0 to:1];
    XCTAssertEqualObjects(self.modelDAO.ungroupedBookmarks[1], pos0);
    XCTAssertEqualObjects(self.persistenceLayer.readBookmarks[1], pos0);
}

- (void)testMoveBookmarkFromZeroToOneInGroup {
    OBABookmarkV2 *pos0 = [self generateBookmarkWithName:@"Pos 0"];
    OBABookmarkV2 *pos1 = [self generateBookmarkWithName:@"Pos 1"];

    OBABookmarkGroup *group = [self groupWithBookmarks:@[pos0, pos1]];
    group.UUID = @"group1";
    [self.modelDAO saveBookmarkGroup:group];
    [self.modelDAO moveBookmark:0 to:1 inGroup:group];
    XCTAssertEqualObjects(group.bookmarks[1], pos0);

    OBABookmarkGroup *reloadedGroup = self.persistenceLayer.readBookmarkGroups[1];
    XCTAssertEqualObjects(reloadedGroup.UUID, @"group1"); // make sure we're looking at the right object.
    XCTAssertEqual(reloadedGroup.bookmarks.count, 2);
    XCTAssertEqualObjects(reloadedGroup.bookmarks[1], pos0);
}

- (void)testMoveBookmarkAcrossGroups {
    OBABookmarkV2 *pos00 = [self generateBookmarkWithName:@"Pos 0_0"];
    OBABookmarkV2 *pos01 = [self generateBookmarkWithName:@"Pos 0_1"];

    OBABookmarkGroup *initialGroup = [self groupWithBookmarks:@[pos00, pos01]];
    initialGroup.sortOrder = 0;

    [self.modelDAO saveBookmarkGroup:initialGroup];

    OBABookmarkV2 *pos10 = [self generateBookmarkWithName:@"Pos 1_0"];
    OBABookmarkGroup *secondGroup = [self groupWithBookmarks:@[pos10]];
    secondGroup.sortOrder = 1;
    secondGroup.UUID = @"secondgroup";
    [self.modelDAO saveBookmarkGroup:secondGroup];

    [self.modelDAO moveBookmark:pos00 toGroup:secondGroup];

    // First group only contains the second bookmark
    XCTAssertEqual(initialGroup.bookmarks.count, 1);
    XCTAssertEqualObjects(initialGroup.bookmarks.firstObject, pos01);

    // Second group now contains two bookmarks:
    NSUInteger idx = [self.persistenceLayer.readBookmarkGroups indexOfObjectPassingTest:^BOOL(OBABookmarkGroup *obj, NSUInteger i, BOOL *stop) {
        return [obj.UUID isEqual:@"secondgroup"];
    }];
    OBABookmarkGroup *reloadedGroup = self.persistenceLayer.readBookmarkGroups[idx];
    XCTAssertEqual(reloadedGroup.bookmarks.count, 2);
    XCTAssertEqualObjects(reloadedGroup.bookmarks[1], pos00);
    XCTAssertEqualObjects([reloadedGroup bookmarks][1], pos00);
}

- (void)testMovingLooseBookmarkFromZeroToZero {
    OBABookmarkV2 *pos0 = [self generateBookmarkWithName:@"Pos 0"];
    OBABookmarkV2 *pos1 = [self generateBookmarkWithName:@"Pos 1"];

    [self.modelDAO saveBookmark:pos0];
    [self.modelDAO saveBookmark:pos1];

    [self.modelDAO moveBookmark:0 to:0];

    NSArray *bookmarks = @[pos0, pos1];

    XCTAssertEqualObjects(self.modelDAO.ungroupedBookmarks, bookmarks);
}

- (void)testMovingGroupedBookmarkFromZeroToZero {
    OBABookmarkV2 *pos00 = [self generateBookmarkWithName:@"Pos 0_0"];
    OBABookmarkV2 *pos01 = [self generateBookmarkWithName:@"Pos 0_1"];

    OBABookmarkGroup *initialGroup = [self groupWithBookmarks:@[pos00, pos01]];
    [self.modelDAO saveBookmarkGroup:initialGroup];

    [self.modelDAO moveBookmark:0 to:0 inGroup:initialGroup];
    NSArray *bookmarks = @[pos00, pos01];
    XCTAssertEqualObjects(initialGroup.bookmarks, bookmarks);
}

- (void)testMoveBookmarkFromZeroToInvalidIndex {
    OBABookmarkV2 *pos0 = [self generateBookmarkWithName:@"Pos 0"];
    OBABookmarkV2 *pos1 = [self generateBookmarkWithName:@"Pos 1"];

    [self.modelDAO saveBookmark:pos0];
    [self.modelDAO saveBookmark:pos1];

    [self.modelDAO moveBookmark:0 to:27];

    NSArray *bookmarks = @[pos1, pos0];

    XCTAssertEqualObjects(self.modelDAO.ungroupedBookmarks, bookmarks);
}

- (void)testMoveBookmarkFromInvalidIndexToValidIndex {
    OBABookmarkV2 *pos0 = [self generateBookmarkWithName:@"Pos 0"];
    OBABookmarkV2 *pos1 = [self generateBookmarkWithName:@"Pos 1"];

    [self.modelDAO saveBookmark:pos0];
    [self.modelDAO saveBookmark:pos1];

    [self.modelDAO moveBookmark:37 to:0];

    NSArray *bookmarks = @[pos0, pos1];

    XCTAssertEqualObjects(self.modelDAO.ungroupedBookmarks, bookmarks);
}

- (void)testMoveBookmarkFromInvalidIndexToInvalidIndex {
    OBABookmarkV2 *pos0 = [self generateBookmarkWithName:@"Pos 0"];
    OBABookmarkV2 *pos1 = [self generateBookmarkWithName:@"Pos 1"];

    [self.modelDAO saveBookmark:pos0];
    [self.modelDAO saveBookmark:pos1];

    [self.modelDAO moveBookmark:37 to:40];

    NSArray *bookmarks = @[pos0, pos1];

    XCTAssertEqualObjects(self.modelDAO.ungroupedBookmarks, bookmarks);
}

- (void)testMoveBookmarkFromInvalidIndexToValidIndexInGroup {
    OBABookmarkV2 *pos0 = [self generateBookmarkWithName:@"Pos 0"];
    OBABookmarkV2 *pos1 = [self generateBookmarkWithName:@"Pos 1"];

    NSArray *bookmarks = @[pos0, pos1];

    OBABookmarkGroup *group = [self groupWithBookmarks:bookmarks];
    [self.modelDAO saveBookmarkGroup:group];

    [self.modelDAO moveBookmark:37 to:0 inGroup:group];

    XCTAssertEqualObjects(group.bookmarks, bookmarks);
}

- (void)testMoveBookmarkFromInvalidIndexToInvalidIndexInGroup {
    OBABookmarkV2 *pos0 = [self generateBookmarkWithName:@"Pos 0"];
    OBABookmarkV2 *pos1 = [self generateBookmarkWithName:@"Pos 1"];

    NSArray *bookmarks = @[pos0, pos1];

    OBABookmarkGroup *group = [self groupWithBookmarks:bookmarks];
    [self.modelDAO saveBookmarkGroup:group];

    [self.modelDAO moveBookmark:37 to:12 inGroup:group];

    XCTAssertEqualObjects(group.bookmarks, bookmarks);
}

- (void)testMovingBookmarkToGroupItsAlreadyInIsANoOp {
    OBABookmarkV2 *bookmark = [self generateBookmarkWithName:@"Hello World"];
    OBABookmarkGroup *group = [self groupWithBookmark:bookmark];
    [self.modelDAO saveBookmarkGroup:group];

    [self.modelDAO moveBookmark:bookmark toGroup:group];

    XCTAssertEqual(1, group.bookmarks.count);
}

#pragma mark - Groups

- (void)testNilGroupsObjectDoesntCrashApp {
    id shouldntBeNilButHereWeAreAnyway = nil;

    OBATestHarnessPersistenceLayer *persistenceLayer = [[OBATestHarnessPersistenceLayer alloc] init];
    [persistenceLayer writeBookmarkGroups:shouldntBeNilButHereWeAreAnyway];
    OBAModelDAO *modelDAO = [[OBAModelDAO alloc] initWithModelPersistenceLayer:persistenceLayer];
    XCTAssertEqual(modelDAO.bookmarkGroups.count, 1);
}

- (void)testGarbageGroupsObjectDoesntCrashApp {
    id shouldntBeNilButHereWeAreAnyway = [NSNull null];

    OBATestHarnessPersistenceLayer *persistenceLayer = [[OBATestHarnessPersistenceLayer alloc] init];
    [persistenceLayer writeBookmarkGroups:shouldntBeNilButHereWeAreAnyway];
    OBAModelDAO *modelDAO = [[OBAModelDAO alloc] initWithModelPersistenceLayer:persistenceLayer];
    XCTAssertEqual(modelDAO.bookmarkGroups.count, 1);
}

#pragma mark - Reordering Bookmark Groups

- (void)testTodayGroupIsFirstByDefault {
    OBABookmarkGroup *group = [self generateBookmarkGroupNamed:@"Zeroth" bookmarkCount:1];
    [self.modelDAO saveBookmarkGroup:group];

    XCTAssertEqual(group.bookmarkGroupType, OBABookmarkGroupTypeRegular);
    XCTAssertTrue(self.modelDAO.bookmarkGroups.firstObject.bookmarkGroupType == OBABookmarkGroupTypeTodayWidget);
}

- (void)testBookmarkGroupsAreAppendedToEndAtSave {
    OBABookmarkGroup *group0 = [self generateBookmarkGroupNamed:@"Zeroth" bookmarkCount:1];
    [self.modelDAO saveBookmarkGroup:group0];

    OBABookmarkGroup *group1 = [self generateBookmarkGroupNamed:@"First" bookmarkCount:1];
    [self.modelDAO saveBookmarkGroup:group1];

    XCTAssertEqual(group0.sortOrder, 1);
    XCTAssertEqual(group1.sortOrder, 2);
}

- (void)testMovingBookmarkGroupToItsCurrentIndex {
    OBABookmarkGroup *group0 = [self generateBookmarkGroupNamed:@"Zeroth" bookmarkCount:1];
    [self.modelDAO saveBookmarkGroup:group0];

    OBABookmarkGroup *group1 = [self generateBookmarkGroupNamed:@"First" bookmarkCount:1];
    [self.modelDAO saveBookmarkGroup:group1];

    [self.modelDAO moveBookmarkGroup:group0 toIndex:0];

    XCTAssertEqual(group0.sortOrder, 0);
    XCTAssertEqual(group1.sortOrder, 2);
}

- (void)testMovingBookmarkGroupToExistingPosition {
    OBABookmarkGroup *group0 = [self generateBookmarkGroupNamed:@"Zeroth" bookmarkCount:1];
    [self.modelDAO saveBookmarkGroup:group0];

    OBABookmarkGroup *group1 = [self generateBookmarkGroupNamed:@"First" bookmarkCount:1];
    [self.modelDAO saveBookmarkGroup:group1];

    [self.modelDAO moveBookmarkGroup:group1 toIndex:0];

    XCTAssertEqual(group0.sortOrder, 2);
    XCTAssertEqual(group1.sortOrder, 0);
}

- (void)testMovingBookmarkGroupToBadIndex {
    OBABookmarkGroup *group0 = [self generateBookmarkGroupNamed:@"Zeroth" bookmarkCount:1];
    [self.modelDAO saveBookmarkGroup:group0];

    OBABookmarkGroup *group1 = [self generateBookmarkGroupNamed:@"First" bookmarkCount:1];
    [self.modelDAO saveBookmarkGroup:group1];

    [self.modelDAO moveBookmarkGroup:group0 toIndex:999];

    XCTAssertEqual(group0.sortOrder, 2);
    XCTAssertEqual(group1.sortOrder, 1);
}

#pragma mark - Deleting Bookmarks

- (void)testRemovingOneOfManyLooseBookmarks {
    OBABookmarkV2 *pos0 = [self generateBookmarkWithName:@"Pos 0"];
    OBABookmarkV2 *pos1 = [self generateBookmarkWithName:@"Pos 1"];
    OBABookmarkV2 *pos2 = [self generateBookmarkWithName:@"Pos 2"];

    [self.modelDAO saveBookmark:pos0];
    [self.modelDAO saveBookmark:pos1];
    [self.modelDAO saveBookmark:pos2];

    [self.modelDAO removeBookmark:pos1];

    XCTAssertEqual(self.persistenceLayer.readBookmarks.count, 2);
    XCTAssertEqualObjects(self.persistenceLayer.readBookmarks[0], pos0);
    XCTAssertEqualObjects(self.persistenceLayer.readBookmarks[1], pos2);
}

- (void)testRemovingTheLastLooseBookmark {
    OBABookmarkV2 *pos0 = [self generateBookmarkWithName:@"Pos 0"];
    OBABookmarkV2 *pos1 = [self generateBookmarkWithName:@"Pos 1"];
    OBABookmarkV2 *pos2 = [self generateBookmarkWithName:@"Pos 2"];

    [self.modelDAO saveBookmark:pos0];
    [self.modelDAO saveBookmark:pos1];
    [self.modelDAO saveBookmark:pos2];

    [self.modelDAO removeBookmark:pos2];

    XCTAssertEqual(self.persistenceLayer.readBookmarks.count, 2);
    XCTAssertEqualObjects(self.persistenceLayer.readBookmarks[0], pos0);
    XCTAssertEqualObjects(self.persistenceLayer.readBookmarks[1], pos1);
}

- (void)testRemovingOneOfManyGroupedBookmarks {
    OBABookmarkV2 *pos0 = [self generateBookmarkWithName:@"Pos 0"];
    OBABookmarkV2 *pos1 = [self generateBookmarkWithName:@"Pos 1"];
    OBABookmarkV2 *pos2 = [self generateBookmarkWithName:@"Pos 2"];
    OBABookmarkGroup *group = [self groupWithBookmarks:@[pos0, pos1, pos2]];

    [self.modelDAO saveBookmarkGroup:group];
    [self.modelDAO removeBookmark:pos1];

    XCTAssertEqual(self.persistenceLayer.readBookmarks.count, 0);
    XCTAssertEqual(group.bookmarks.count, 2);
    XCTAssertEqualObjects(group.bookmarks[0], pos0);
    XCTAssertEqualObjects(group.bookmarks[1], pos2);
}

- (void)testRemovingTheLastGroupedBookmark {
    OBABookmarkV2 *pos0 = [self generateBookmarkWithName:@"Pos 0"];
    OBABookmarkV2 *pos1 = [self generateBookmarkWithName:@"Pos 1"];
    OBABookmarkV2 *pos2 = [self generateBookmarkWithName:@"Pos 2"];
    OBABookmarkGroup *group = [self groupWithBookmarks:@[pos0, pos1, pos2]];

    [self.modelDAO saveBookmarkGroup:group];
    [self.modelDAO removeBookmark:pos2];

    XCTAssertEqual(self.persistenceLayer.readBookmarks.count, 0);
    XCTAssertEqual(group.bookmarks.count, 2);
    XCTAssertEqualObjects(group.bookmarks[0], pos0);
    XCTAssertEqualObjects(group.bookmarks[1], pos1);
}

- (void)testRemoveNilBookmarkGroup {
    OBABookmarkGroup *group = [self generateBookmarkGroupNamed:@"Group Name" bookmarkCount:1];
    [self.modelDAO saveBookmarkGroup:group];

    OBABookmarkGroup *nilGroup = nil;
    [self.modelDAO removeBookmarkGroup:nilGroup];

    XCTAssertEqualObjects(self.modelDAO.bookmarkGroups[1], group);
}

- (void)testRemoveNonexistentBookmarkGroup {
    OBABookmarkGroup *group = [self generateBookmarkGroupNamed:@"Group 1" bookmarkCount:1];
    [self.modelDAO saveBookmarkGroup:group];

    OBABookmarkGroup *group2 = [self generateBookmarkGroupNamed:@"Group 2" bookmarkCount:1];
    [self.modelDAO saveBookmarkGroup:group2];

    XCTAssertEqual(self.modelDAO.bookmarkGroups.count, (NSInteger)3);

    [self.modelDAO removeBookmarkGroup:group2];
    [self.modelDAO removeBookmarkGroup:group2];

    XCTAssertEqual(self.modelDAO.bookmarkGroups.count, (NSInteger)2);
    XCTAssertEqualObjects(self.modelDAO.bookmarkGroups[1], group);
}

- (void)testRemoveBookmarkGroup {
    OBABookmarkGroup *group = [self generateBookmarkGroupNamed:@"Group 1" bookmarkCount:1];
    [self.modelDAO saveBookmarkGroup:group];

    XCTAssertEqual(self.modelDAO.ungroupedBookmarks.count, (NSInteger)0);
    XCTAssertEqual(self.modelDAO.bookmarkGroups.count, (NSInteger)2);

    [self.modelDAO removeBookmarkGroup:group];

    XCTAssertEqual(self.modelDAO.ungroupedBookmarks.count, (NSInteger)1);
    XCTAssertEqual(self.modelDAO.bookmarkGroups.count, (NSInteger)1);
}

- (void)testRemovingLastBookmarkRemovesGroup {
    OBABookmarkGroup *group = [self generateBookmarkGroupNamed:@"Testing testRemovingLastBookmarkRemovesGroup" bookmarkCount:1];
    [self.modelDAO saveBookmarkGroup:group];

    XCTAssertEqualObjects(self.modelDAO.bookmarkGroups[1], group);

    [self.modelDAO removeBookmark:group.bookmarks.firstObject];

    XCTAssertEqualObjects(self.modelDAO.bookmarkGroups, [NSArray arrayWithObject:self.modelDAO.todayBookmarkGroup]);
}

- (void)testMovingBookmarkOutOfGroup {
    OBABookmarkGroup *group = [self generateBookmarkGroupNamed:@"Testing testMovingBookmarkOutOfGroup" bookmarkCount:1];
    [self.modelDAO saveBookmarkGroup:group];

    OBABookmarkV2 *bookmark = group.bookmarks.firstObject;

    [self.modelDAO moveBookmark:bookmark toGroup:nil];

    XCTAssertEqual(self.modelDAO.ungroupedBookmarks.count, (NSUInteger)1);
    XCTAssertEqualObjects(self.modelDAO.ungroupedBookmarks.firstObject, bookmark);
}

- (void)testMovingUngroupedBookmarkToGroup {
    OBABookmarkGroup *group = [self generateBookmarkGroupNamed:@"Testing testMovingUngroupedBookmarkToGroup" bookmarkCount:0];
    [self.modelDAO saveBookmarkGroup:group];

    OBABookmarkV2 *bookmark = [self generateBookmarkWithName:@"Hello bookmark"];
    [self.modelDAO saveBookmark:bookmark];

    [self.modelDAO moveBookmark:bookmark toGroup:group];

    XCTAssertEqual(self.modelDAO.ungroupedBookmarks.count, (NSUInteger)0);
    XCTAssertEqualObjects(group.bookmarks, [NSArray arrayWithObject:bookmark]);
}

- (void)testMovingBookmarkFromGroupToGroup {
    OBABookmarkGroup *fromGroup = [self generateBookmarkGroupNamed:@"from group" bookmarkCount:3];
    [self.modelDAO saveBookmarkGroup:fromGroup];

    OBABookmarkGroup *toGroup = [self generateBookmarkGroupNamed:@"to group" bookmarkCount:3];
    [self.modelDAO saveBookmarkGroup:toGroup];

    OBABookmarkV2 *bookmark = fromGroup.bookmarks[0];

    [self.modelDAO moveBookmark:bookmark toIndex:1 inGroup:toGroup];

    XCTAssertEqual(2, fromGroup.bookmarks.count);
    XCTAssertEqual(4, toGroup.bookmarks.count);
    XCTAssertEqualObjects(bookmark, toGroup.bookmarks[1]);
}

- (void)testMovingUngroupedBookmarkToNewUngroupedIndex {
    OBABookmarkV2 *top = [self generateBookmarkWithName:@"Top"];
    OBABookmarkV2 *bottom = [self generateBookmarkWithName:@"Bottom"];
    [self.modelDAO saveBookmark:top];
    [self.modelDAO saveBookmark:bottom];

    NSArray *expectedInitialOrder = @[top,bottom];

    XCTAssertEqualObjects(expectedInitialOrder, self.modelDAO.ungroupedBookmarks);

    [self.modelDAO moveBookmark:top toIndex:1 inGroup:nil];

    NSArray *expectedFinalOrder = @[bottom,top];
    XCTAssertEqual(expectedInitialOrder.count, self.modelDAO.ungroupedBookmarks.count);
    XCTAssertEqualObjects(expectedFinalOrder, self.modelDAO.ungroupedBookmarks);
}

#pragma mark - Region

- (void)testSettingAlreadySetRegion {
    OBARegionV2 *region = self.modelDAO.currentRegion;
    self.modelDAO.currentRegion = region;
    XCTAssertEqualObjects(self.modelDAO.currentRegion, region);
}

- (void)testDefaultValueForAutomaticallySetRegion {
    XCTAssertTrue([self.persistenceLayer readSetRegionAutomatically]);
    XCTAssertTrue(self.modelDAO.automaticallySelectRegion);
}

- (void)testSettingAutomaticallySetRegion {
    self.modelDAO.automaticallySelectRegion = NO;
    XCTAssertFalse(self.modelDAO.automaticallySelectRegion);
    XCTAssertFalse(self.persistenceLayer.readSetRegionAutomatically);
}

- (void)testNullRegionReturnsEmptyArray {
    self.modelDAO.currentRegion = nil;
    XCTAssertEqualObjects(self.modelDAO.bookmarksForCurrentRegion, @[]);
}

#pragma mark - Most Recent Stops

- (void)testViewingStopAffectsMostRecentStops {
    OBAStopV2 *stop = [self.class generateStop];
    [self.modelDAO viewedArrivalsAndDeparturesForStop:stop];

    XCTAssertEqual(1, self.modelDAO.mostRecentStops.count);

}

- (void)testClearingMostRecentStops {
    OBAStopV2 *stop = [self.class generateStop];
    [self.modelDAO viewedArrivalsAndDeparturesForStop:stop];
    [self.modelDAO clearMostRecentStops];

    XCTAssertEqual(0, self.modelDAO.mostRecentStops.count);
}

- (void)testClearingMostRecentStopsTriggersNotification {
    OBAStopV2 *stop = [self.class generateStop];
    [self.modelDAO viewedArrivalsAndDeparturesForStop:stop];

    [self expectationForNotification:OBAMostRecentStopsChangedNotification object:nil handler:nil];

    [self.modelDAO clearMostRecentStops];

    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testRecentStopsNearCoordinate_invalidCoordinate {
    CLLocationCoordinate2D invalid = kCLLocationCoordinate2DInvalid;
    NSArray *output = [self.modelDAO recentStopsNearCoordinate:invalid];

    XCTAssertTrue(output.count == 0);
}

- (void)testRecentStopsNearCoordinate_validCoordinate {
    CLLocationCoordinate2D coordSpaceNeedle = CLLocationCoordinate2DMake(47.6205063, -122.3492774);

    OBAStopV2 *stopSLU = [self.class generateStopWithLatitude:47.6208745 longitude:-122.3387323];
    stopSLU.name = @"SLU";
    [self.modelDAO viewedArrivalsAndDeparturesForStop:stopSLU];
    XCTAssertEqual(self.modelDAO.mostRecentStops.count, 1);

    OBAStopV2 *stopAurora = [self.class generateStopWithLatitude:47.6210315 longitude:-122.3440149];
    stopAurora.name = @"Aurora";
    [self.modelDAO viewedArrivalsAndDeparturesForStop:stopAurora];
    XCTAssertEqual(self.modelDAO.mostRecentStops.count, 2);

    OBAStopV2 *stopSaint = [self.class generateStopWithLatitude:47.6177114 longitude:-122.3272776];
    [self.modelDAO viewedArrivalsAndDeparturesForStop:stopSaint];
    XCTAssertEqual(self.modelDAO.mostRecentStops.count, 3);

    NSArray<OBAStopAccessEventV2*> *sortedRecents = [self.modelDAO recentStopsNearCoordinate:coordSpaceNeedle];
    XCTAssertEqual(sortedRecents.count, 2);
    XCTAssertEqualObjects(sortedRecents[0].stopID, stopAurora.stopId);
    XCTAssertEqualObjects(sortedRecents[1].stopID, stopSLU.stopId);
}

#pragma mark - Location

- (void)testMostRecentLocation {
    CLLocation *location = [[CLLocation alloc] initWithLatitude:47.623971 longitude:-122.3132352];
    self.modelDAO.mostRecentLocation = location;
    XCTAssertEqual(self.modelDAO.mostRecentLocation.coordinate.latitude, location.coordinate.latitude);
    XCTAssertEqual(self.modelDAO.mostRecentLocation.coordinate.longitude, location.coordinate.longitude);
    XCTAssertEqual(self.persistenceLayer.readMostRecentLocation.coordinate.latitude, location.coordinate.latitude);
    XCTAssertEqual(self.persistenceLayer.readMostRecentLocation.coordinate.longitude, location.coordinate.longitude);
}

#pragma mark - Helpers

- (OBABookmarkGroup*)generateBookmarkGroupNamed:(NSString*)name bookmarkCount:(NSUInteger)count {
    OBABookmarkGroup *group = [[OBABookmarkGroup alloc] initWithName:name];

    for (int i=0; i<count;i++) {
        OBABookmarkV2 *bm = [self generateBookmarkWithName:[NSString stringWithFormat:@"Pos %d", i]];
        bm.group = group;
        [group addBookmark:bm];
    }
    return group;
}

- (OBABookmarkGroup*)groupWithBookmark:(OBABookmarkV2*)bookmark {
    return [self groupWithBookmarks:@[bookmark]];
}

- (OBABookmarkGroup*)groupWithBookmarks:(NSArray<OBABookmarkV2*>*)bookmarks {
    OBABookmarkGroup *g = [[OBABookmarkGroup alloc] initWithName:@"Bookmark Group"];
    for (OBABookmarkV2 *bm in bookmarks) {
        [g addBookmark:bm];
    }

    for (OBABookmarkV2 *bookmark in bookmarks) {
        bookmark.group = g;
    }

    return g;
}

- (OBABookmarkV2*)generateBookmarkWithName:(NSString*)name {
    return [self generateBookmarkWithStop:nil name:name];
}

- (OBABookmarkV2*)generateBookmarkWithStop:(OBAStopV2*)stop name:(nullable NSString*)name {
    OBAArrivalAndDepartureV2 *arrivalAndDeparture = [self generateArrivalAndDepartureWithStop:stop];
    OBABookmarkV2 *bookmark = [[OBABookmarkV2 alloc] initWithArrivalAndDeparture:arrivalAndDeparture region:self.modelDAO.currentRegion];
    bookmark.name = name;
    return bookmark;
}

+ (OBAStopV2*)generateStop {
    OBAStopV2 *stop = [[OBAStopV2 alloc] init];
    stop.stopId = [[NSUUID UUID] UUIDString];
    stop.name = stop.stopId;
    return stop;
}

+ (OBAStopV2*)generateStopWithLatitude:(double)lat longitude:(double)lon {
    OBAStopV2 *stop = [self generateStop];
    stop.lat = lat;
    stop.lon = lon;

    return stop;
}

- (OBAArrivalAndDepartureV2*)generateArrivalAndDepartureWithStop:(OBAStopV2*)stop {
    OBAArrivalAndDepartureV2 *arrivalAndDeparture = [[OBAArrivalAndDepartureV2 alloc] init];
    [arrivalAndDeparture.references addStop:stop ?: [self.class generateStop]];
    arrivalAndDeparture.stopId = stop.stopId;
    arrivalAndDeparture.routeId = [NSUUID UUID].UUIDString;
    arrivalAndDeparture.tripHeadsign = [NSUUID UUID].UUIDString;

    return arrivalAndDeparture;
}

@end
