//
//  OBARegionalAlert_Tests.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/16/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

@import XCTest;
@import Mantle;
#import "OBATestHelpers.h"
#import <OBAKit/OBARegionalAlert.h>

@interface OBARegionalAlert_Tests : XCTestCase

@end

@implementation OBARegionalAlert_Tests

- (void)setUp {
    [super setUp];

    [OBATestHelpers configureDefaultTimeZone];
}

- (void)testUpdatedTestDeserialization {
    id json = [OBATestHelpers jsonObjectFromFile:@"alert_feed_items.json"];

    NSError *error = nil;
    NSArray *models = [MTLJSONAdapter modelsOfClass:OBARegionalAlert.class fromJSONArray:json error:&error];

    XCTAssertNil(error);
    XCTAssertEqual(models.count, 20);

    OBARegionalAlert *alert = models[0];

    XCTAssertEqualObjects(alert.title, @"Link light rail - Elevator outage - Northbound Platform at Mt Baker Station ");
    XCTAssertNotNil(alert.publishedAt);
}

@end
