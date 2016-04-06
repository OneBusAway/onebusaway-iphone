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

// It doesn't touch the persistence layer
- (void)testCreateTransientBookmark {
    OBAStopV2 *stop = [[OBAStopV2 alloc] init];
    stop.stopId = @"1234567890";
    OBABookmarkV2 *bookmark = [self.modelDAO createTransientBookmark:stop];
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
    [self.modelDAO addNewBookmark:bookmark];

    XCTAssertEqualObjects([self.modelDAO bookmarkForStop:stop], bookmark);
}

- (void)testBookmarkForStopInGroup {
    OBAStopV2 *stop = [self.class generateStop];
    OBABookmarkV2 *bookmark = [self generateBookmark];
    OBABookmarkGroup *group = ({
        OBABookmarkGroup *g = [[OBABookmarkGroup alloc] initWithName:@"yay my group"];
        [g.bookmarks addObject:bookmark];
        g;
    });
    [self.modelDAO addOrSaveBookmarkGroup:group];

    XCTAssertEqualObjects([self.modelDAO bookmarkForStop:stop], bookmark);
}

- (OBABookmarkV2*)generateBookmark {
    OBAStopV2 *stop = [self.class generateStop];
    return [[OBABookmarkV2 alloc] initWithStop:stop region:self.modelDAO.region];
}


+ (OBAStopV2*)generateStop {
    OBAStopV2 *stop = [[OBAStopV2 alloc] init];
    stop.stopId = @"12345";
    return stop;
}

@end
