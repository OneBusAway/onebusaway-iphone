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

    XCTAssertEqualObjects(dep.bookmarkKey, @"ROUTE_HEADSIGN_SHORTROUTE");
}

@end
