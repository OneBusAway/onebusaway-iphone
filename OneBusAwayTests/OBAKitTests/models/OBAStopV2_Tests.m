//
//  OBAStopV2_Tests.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/25/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OBATestHelpers.h"

#import <OBAKit/OBAModelFactory.h>
#import <OBAKit/OBAReferencesV2.h>
#import <OBAKit/OBAStopV2.h>

/**
 TODO: WRITE TESTS
 */

@interface OBAStopV2_Tests : XCTestCase
@property(nonatomic,strong) OBAModelFactory *modelFactory;
@end

@implementation OBAStopV2_Tests

- (void)setUp {
    [super setUp];

    OBAReferencesV2 *references = [[OBAReferencesV2 alloc] init];
    self.modelFactory = [[OBAModelFactory alloc] initWithReferences:references];
}

#pragma mark - NSCoder

- (void)testDeserializingOldStops {
    // this plist was serialized with a pair of NSNumber objects representing the (lat, long),
    // as was the case in versions up to 2.5.2. 2.6.0 moved over to storing these as doubles.
    OBAStopV2 *stop = [OBATestHelpers unarchiveBundledTestFile:@"stop_with_obj_lat_long.plist"];
    XCTAssertEqual(47, stop.lat);
    XCTAssertEqual(-122, stop.lon);
}

- (void)testRoundtrippingEncodingSansLatLong {
    OBAStopV2 *stop = [self.class buildStop];
    OBAStopV2 *unarchived = [OBATestHelpers roundtripObjectThroughNSCoding:stop];

    XCTAssertEqualObjects(stop, unarchived);
    XCTAssertEqualObjects(stop.stopId, unarchived.stopId);
    XCTAssertEqual(stop.lat, stop.lat);
    XCTAssertEqual(stop.lon, stop.lon);
    XCTAssertEqualObjects(stop.name, unarchived.name);
    XCTAssertEqualObjects(stop.code, unarchived.code);
    XCTAssertEqualObjects(stop.direction, unarchived.direction);
    XCTAssertEqualObjects(stop.routeIds, unarchived.routeIds);
}

+ (OBAStopV2*)buildStop {
    OBAStopV2 *stop = [[OBAStopV2 alloc] init];
    stop.stopId = @"12345";
    stop.lat = 47;
    stop.lon = -122;
    stop.name = @"STOP";
    stop.code = @"CODE";
    stop.direction = @"E";
    stop.routeIds = @[@"1", @"2"];

    return stop;
}
@end
