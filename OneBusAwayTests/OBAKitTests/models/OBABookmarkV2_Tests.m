//
//  OBABookmarkV2_Tests.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/9/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OBATestHelpers.h"
#import <OBAKit/OBABookmarkV2.h>

@interface OBABookmarkV2_Tests : XCTestCase

@end

@implementation OBABookmarkV2_Tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testMigratingBookmarkWithStopIDsArray {
    OBABookmarkV2 *bookmark = [OBATestHelpers unarchiveBundledTestFile:@"bookmark_with_stopids_array.plist"];
    XCTAssertEqualObjects(bookmark.name, @"Test Bookmark");
    XCTAssertNil(bookmark.group);
    XCTAssertEqualObjects(bookmark.stopId, @"1_12345");
    XCTAssertEqual(bookmark.regionIdentifier, 1337);
}

- (void)testMigratingBookmarkWithoutRegionIdentifier {
    OBABookmarkV2 *bm = [OBATestHelpers unarchiveBundledTestFile:@"bookmark_without_region_identifier.plist"];

    XCTAssertEqualObjects(bm.name, @"Test Bookmark");
    XCTAssertEqualObjects(bm.stopId, @"1_12345");
    XCTAssertEqual(bm.regionIdentifier, NSNotFound);
}

- (void)testBookmarkWithRegionIdentifier {
    OBABookmarkV2 *bm = [OBATestHelpers unarchiveBundledTestFile:@"bookmark_with_region_identifier.plist"];
    XCTAssertEqualObjects(bm.name, @"Happy, up to date bookmark.");
    XCTAssertEqualObjects(bm.stopId, @"1_123456");
    XCTAssertEqual(bm.regionIdentifier, 1);
}

@end
