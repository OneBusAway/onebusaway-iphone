//
//  OBAArrivalAndDepartureV2_Tests.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/25/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OBATestHelpers.h"

#import <OBAKit/OBAModelFactory.h>
#import <OBAKit/OBAReferencesV2.h>
#import <OBAKit/OBAArrivalAndDepartureV2.h>

/**
 TODO: WRITE TESTS
 */

@interface OBAArrivalAndDepartureV2_Tests : XCTestCase
@property(nonatomic,strong) OBAModelFactory *modelFactory;
@end

@implementation OBAArrivalAndDepartureV2_Tests

- (void)setUp {
    [super setUp];

    OBAReferencesV2 *references = [[OBAReferencesV2 alloc] init];
    self.modelFactory = [[OBAModelFactory alloc] initWithReferences:references];
}

- (void)testBookmarkKey {
    OBAArrivalAndDepartureV2 *dep = [[OBAArrivalAndDepartureV2 alloc] init];
    dep.routeId = @"ROUTE";
    dep.tripHeadsign = @"HEADSIGN";
    dep.routeShortName = @"SHORTROUTE";

    XCTAssertEqualObjects(dep.bookmarkKey, @"SHORTROUTE_headsign_ROUTE");
}

- (void)testNilHeadsign {
    OBAArrivalAndDepartureV2 *dep = [[OBAArrivalAndDepartureV2 alloc] init];
    dep.tripHeadsign = nil;

    XCTAssertNil(dep.tripHeadsign);
}

- (void)testMixedCaseHeadsign {
    OBAArrivalAndDepartureV2 *dep = [[OBAArrivalAndDepartureV2 alloc] init];
    dep.tripHeadsign = @"Downtown Seattle - 15TH";

    XCTAssertEqualObjects(@"Downtown Seattle - 15TH", dep.tripHeadsign);
}

@end
