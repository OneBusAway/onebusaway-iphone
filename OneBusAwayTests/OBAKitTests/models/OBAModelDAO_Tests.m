//
//  OBAModelDAO_Tests.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 4/3/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OBAModelDAO.h"
#import "OBATestHelpers.h"
#import "OBATestHarnessPersistenceLayer.h"
#import "OBABookmarkGroup.h"
#import "OBABookmarkV2.h"

@interface OBAModelDAO_Tests : XCTestCase
@property(nonatomic,strong) OBATestHarnessPersistenceLayer *persistenceLayer;
@property(nonatomic,strong) OBAModelDAO *modelDAO;
@end

@implementation OBAModelDAO_Tests

- (void)setUp {
    [super setUp];

    self.persistenceLayer = [[OBATestHarnessPersistenceLayer alloc] init];
    self.modelDAO = [[OBAModelDAO alloc] initWithModelPersistenceLayer:self.persistenceLayer];
    self.modelDAO.region = [OBATestHelpers pugetSoundRegion];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - hideFutureLocationWarnings

- (void)testHideFutureLocationWarnings {
    XCTAssertFalse(self.persistenceLayer.hideFutureLocationWarnings);
    self.modelDAO.hideFutureLocationWarnings = YES;
    XCTAssertTrue(self.persistenceLayer.hideFutureLocationWarnings);
    XCTAssertTrue(self.modelDAO.hideFutureLocationWarnings);
}

#pragma mark - Bookmarks

- (void)testTransientBookmarksDontTouchPersistenceLayer {
    OBAStopV2 *stop = [[OBAStopV2 alloc] init];
    stop.stopId = @"1234567890";
    OBABookmarkV2 *bookmark = [[OBABookmarkV2 alloc] initWithStop:stop region:self.modelDAO.region];
    XCTAssertEqual(self.persistenceLayer.readBookmarks.count, 0);

    XCTAssertEqualObjects(bookmark.stop, stop);
}

- (void)testBookmarkForStopIDWithNilDoesntCrash {
    OBAStopV2 *nilStop = nil;
    XCTAssertNil([self.modelDAO bookmarkForStop:nilStop]);
}

- (void)testBookmarkForStop {
    OBAStopV2 *stop = [self.class generateStop];
    OBABookmarkV2 *bookmark = [[OBABookmarkV2 alloc] initWithStop:stop region:self.modelDAO.region];
    [self.modelDAO saveBookmark:bookmark];

    XCTAssertEqualObjects([self.modelDAO bookmarkForStop:stop], bookmark);
}

- (void)testBookmarkForStopInGroup {
    OBAStopV2 *stop = [self.class generateStop];
    OBABookmarkV2 *bookmark = [self generateBookmarkWithStop:stop];
    OBABookmarkGroup *group = ({
        OBABookmarkGroup *g = [[OBABookmarkGroup alloc] initWithName:@"yay my group"];
        [g.bookmarks addObject:bookmark];
        g;
    });
    [self.modelDAO saveBookmarkGroup:group];

    XCTAssertEqualObjects([self.modelDAO bookmarkForStop:stop], bookmark);
}

- (void)testAllBookmarksAggregatesLooseAndGroupedBookmarks {
    OBABookmarkV2 *looseBookmark = [self generateBookmark];
    OBABookmarkV2 *groupedBookmark = [self generateBookmark];
    OBABookmarkGroup *group = [self groupWithBookmark:groupedBookmark];
    [self.modelDAO saveBookmark:looseBookmark];
    [self.modelDAO saveBookmarkGroup:group];

    NSSet *allBookmarks = [NSSet setWithArray:[self.modelDAO bookmarksForCurrentRegion]];
    NSSet *local = [NSSet setWithArray:@[looseBookmark,groupedBookmark]];

    XCTAssertEqualObjects(allBookmarks, local);
}

#pragma mark - Create New Bookmark

- (void)testAddNewLooseBookmark {
    OBABookmarkV2 *looseBookmark = [self generateBookmark];
    [self.modelDAO saveBookmark:looseBookmark];
    XCTAssertEqual(self.modelDAO.bookmarks.count, 1);
    XCTAssertEqualObjects(self.persistenceLayer.readBookmarks, @[looseBookmark]);
}

- (void)testAddNewGroupedBookmark {
    OBABookmarkV2 *groupedBookmark = [self generateBookmark];
    OBABookmarkGroup *group = [self groupWithBookmark:groupedBookmark];
    [self.modelDAO saveBookmarkGroup:group];

    XCTAssertEqual(self.persistenceLayer.readBookmarkGroups.count, 1);
}

#pragma mark - Save Existing Bookmark

- (void)testSaveExistingBookmarkWhenItDoesntYetExist {
    OBABookmarkV2 *bookmark = [self generateBookmark];
    XCTAssertEqual(self.modelDAO.bookmarks.count,0);
    [self.modelDAO saveBookmark:bookmark];
    XCTAssertEqual(self.persistenceLayer.readBookmarks.count, 1);
}

- (void)testSaveExistingBookmarkWhenItBelongsToAGroup {
    OBABookmarkV2 *bookmark = [self generateBookmark];
    OBABookmarkGroup *group = [self groupWithBookmark:bookmark];
    [self.modelDAO saveBookmarkGroup:group];
    XCTAssertEqual(self.modelDAO.bookmarks.count,0);
    XCTAssertEqual(self.persistenceLayer.readBookmarks.count, 0);
    XCTAssertEqual(self.modelDAO.bookmarkGroups.count, 1);
    XCTAssertEqual(self.persistenceLayer.readBookmarkGroups.count, 1);
    XCTAssertEqual([self.persistenceLayer.readBookmarkGroups.firstObject bookmarks].count, 1);
    bookmark.name = @"I AM NOW CHANGED";
    [self.modelDAO saveBookmark:bookmark];
    XCTAssertEqual(self.persistenceLayer.readBookmarks.count, 0);
    XCTAssertEqualObjects([[[self.persistenceLayer.readBookmarkGroups.firstObject bookmarks] firstObject] name], bookmark.name);
}

- (void)testSavingLoosePreexistingBookmark {
    NSString *bookmarkName = @"NEW TITLE - LOREM IPSUM DOLOR SIT AMET";
    OBABookmarkV2 *bookmark = [self generateBookmark];
    [self.modelDAO saveBookmark:bookmark];
    bookmark.name = bookmarkName;
    [self.modelDAO saveBookmark:bookmark];
    XCTAssertEqualObjects([self.persistenceLayer.readBookmarks.firstObject name], bookmarkName);
}

#pragma mark - Move Bookmark

- (void)testMoveBookmarkFromPositionZeroToOneInLoose {
    OBABookmarkV2 *pos0 = [self generateBookmark];
    pos0.name = @"Pos 0";

    OBABookmarkV2 *pos1 = [self generateBookmark];
    pos1.name = @"Pos 1";

    [self.modelDAO saveBookmark:pos0];
    [self.modelDAO saveBookmark:pos1];

    XCTAssertEqualObjects(self.modelDAO.bookmarks[0], pos0);
    XCTAssertEqualObjects(self.persistenceLayer.readBookmarks[0], pos0);

    [self.modelDAO moveBookmark:0 to:1];
    XCTAssertEqualObjects(self.modelDAO.bookmarks[1], pos0);
    XCTAssertEqualObjects(self.persistenceLayer.readBookmarks[1], pos0);
}

- (void)testMoveBookmarkFromZeroToOneInGroup {
    OBABookmarkV2 *pos0 = [self generateBookmark];
    pos0.name = @"Pos 0";

    OBABookmarkV2 *pos1 = [self generateBookmark];
    pos1.name = @"Pos 1";

    OBABookmarkGroup *group = [self groupWithBookmarks:@[pos0, pos1]];
    [self.modelDAO saveBookmarkGroup:group];
    [self.modelDAO moveBookmark:0 to:1 inGroup:group];
    XCTAssertEqualObjects(group.bookmarks[1], pos0);
    XCTAssertEqualObjects([[self.persistenceLayer.readBookmarkGroups[0] bookmarks] objectAtIndex:1], pos0);
}

- (void)testMoveBookmarkAcrossGroups {
    OBABookmarkV2 *pos00 = [self generateBookmark];
    pos00.name = @"Pos 0_0";

    OBABookmarkV2 *pos01 = [self generateBookmark];
    pos01.name = @"Pos 0_1";

    OBABookmarkGroup *initialGroup = [self groupWithBookmarks:@[pos00, pos01]];
    [self.modelDAO saveBookmarkGroup:initialGroup];

    OBABookmarkV2 *pos10 = [self generateBookmark];
    pos10.name = @"Pos 1_0";
    OBABookmarkGroup *secondGroup = [self groupWithBookmarks:@[pos10]];
    [self.modelDAO saveBookmarkGroup:secondGroup];

    [self.modelDAO moveBookmark:pos00 toGroup:secondGroup];

    // First group only contains the second bookmark
    XCTAssertEqual(initialGroup.bookmarks.count, 1);
    XCTAssertEqualObjects(initialGroup.bookmarks.firstObject, pos01);

    // Second group now contains two bookmarks:
    XCTAssertEqual(secondGroup.bookmarks.count, 2);
    XCTAssertEqualObjects(secondGroup.bookmarks[1], pos00);
    XCTAssertEqualObjects([self.persistenceLayer.readBookmarkGroups[1] bookmarks][1], pos00);
}

- (void)testMovingLooseBookmarkFromZeroToZero {
    OBABookmarkV2 *pos0 = [self generateBookmark];
    pos0.name = @"Pos 0";

    OBABookmarkV2 *pos1 = [self generateBookmark];
    pos1.name = @"Pos 1";

    [self.modelDAO saveBookmark:pos0];
    [self.modelDAO saveBookmark:pos1];

    [self.modelDAO moveBookmark:0 to:0];

    NSArray *bookmarks = @[pos0, pos1];

    XCTAssertEqualObjects(self.modelDAO.bookmarks, bookmarks);
}

- (void)testMovingGroupedBookmarkFromZeroToZero {
    OBABookmarkV2 *pos00 = [self generateBookmark];
    pos00.name = @"Pos 0_0";

    OBABookmarkV2 *pos01 = [self generateBookmark];
    pos01.name = @"Pos 0_1";

    OBABookmarkGroup *initialGroup = [self groupWithBookmarks:@[pos00, pos01]];
    [self.modelDAO saveBookmarkGroup:initialGroup];

    [self.modelDAO moveBookmark:0 to:0 inGroup:initialGroup];
    NSArray *bookmarks = @[pos00, pos01];
    XCTAssertEqualObjects(initialGroup.bookmarks, bookmarks);
}

- (void)testMoveBookmarkFromZeroToInvalidIndex {
    OBABookmarkV2 *pos0 = [self generateBookmark];
    pos0.name = @"Pos 0";

    OBABookmarkV2 *pos1 = [self generateBookmark];
    pos1.name = @"Pos 1";

    [self.modelDAO saveBookmark:pos0];
    [self.modelDAO saveBookmark:pos1];

    [self.modelDAO moveBookmark:0 to:27];

    NSArray *bookmarks = @[pos1, pos0];

    XCTAssertEqualObjects(self.modelDAO.bookmarks, bookmarks);
}

- (void)testMoveBookmarkFromInvalidIndexToValidIndex {
    //
}

- (void)testMoveBookmarkFromInvalidIndexToInvalidIndex {
    //
}

#pragma mark - Deleting Bookmarks

- (void)testRemovingOneOfManyLooseBookmarks {
    //
}

- (void)testRemovingTheLastLooseBookmark {
    //
}

- (void)testRemovingOneOfManyGroupedBookmarks {
    //
}

- (void)testRemovingTheLastGroupedBookmark {
    //
}

#pragma mark - Region

- (void)testSettingAlreadySetRegion {
    OBARegionV2 *region = self.modelDAO.region;
    self.modelDAO.region = region;
    XCTAssertEqualObjects(self.modelDAO.region, region);
}

- (void)testDefaultValueForAutomaticallySetRegion {
    XCTAssertTrue([self.persistenceLayer readSetRegionAutomatically]);
    XCTAssertTrue(self.modelDAO.readSetRegionAutomatically);
}

- (void)testSettingAutomaticallySetRegion {
    [self.modelDAO writeSetRegionAutomatically:NO];
    XCTAssertFalse(self.modelDAO.readSetRegionAutomatically);
    XCTAssertFalse(self.persistenceLayer.readSetRegionAutomatically);
}

- (void)testNullRegionReturnsEmptyArray {
    self.modelDAO.region = nil;
    XCTAssertEqualObjects(self.modelDAO.bookmarksForCurrentRegion, @[]);
}

#pragma mark - Location

- (void)testMostRecentLocation {
    CLLocation *location = [[CLLocation alloc] initWithLatitude:47.623971 longitude:-122.3132352];
    self.modelDAO.mostRecentLocation = location;
    XCTAssertEqualObjects(self.modelDAO.mostRecentLocation, location);
    XCTAssertEqualObjects(self.persistenceLayer.readMostRecentLocation, location);
}

#pragma mark - Helpers

- (OBABookmarkGroup*)groupWithBookmark:(OBABookmarkV2*)bookmark {
    return [self groupWithBookmarks:@[bookmark]];
}

- (OBABookmarkGroup*)groupWithBookmarks:(NSArray<OBABookmarkV2*>*)bookmarks {
    OBABookmarkGroup *g = [[OBABookmarkGroup alloc] initWithName:@"Bookmark Group"];
    [g.bookmarks addObjectsFromArray:bookmarks];

    for (OBABookmarkV2 *bookmark in bookmarks) {
        bookmark.group = g;
    }

    return g;
}

- (OBABookmarkV2*)generateBookmark {
    return [self generateBookmarkWithStop:nil];
}

- (OBABookmarkV2*)generateBookmarkWithStop:(OBAStopV2*)stop {
    return [[OBABookmarkV2 alloc] initWithStop:(stop ?: [self.class generateStop]) region:self.modelDAO.region];
}

+ (OBAStopV2*)generateStop {
    OBAStopV2 *stop = [[OBAStopV2 alloc] init];
    stop.stopId = [[NSUUID UUID] UUIDString];
    stop.name = stop.stopId;
    return stop;
}

@end
