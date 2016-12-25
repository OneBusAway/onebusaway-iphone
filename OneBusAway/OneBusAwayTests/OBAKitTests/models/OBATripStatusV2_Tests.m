//
//  OBATripStatusV2_Tests.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/25/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OBATestHelpers.h"

#import <OBAKit/OBAModelFactory.h>
#import <OBAKit/OBAReferencesV2.h>
#import <OBAKit/OBATripStatusV2.h>

/**
 TODO: WRITE TESTS
 */

@interface OBATripStatusV2_Tests : XCTestCase
@property(nonatomic,strong) OBAModelFactory *modelFactory;
@end

@implementation OBATripStatusV2_Tests

- (void)setUp {
    [super setUp];

    OBAReferencesV2 *references = [[OBAReferencesV2 alloc] init];
    self.modelFactory = [[OBAModelFactory alloc] initWithReferences:references];
}

#pragma mark - Orientation

- (void)testEast {
    OBATripStatusV2 *status = [[OBATripStatusV2 alloc] init];
    status.orientation = 0.f;
    XCTAssertEqualWithAccuracy(status.orientationInRadians, 0, 0.0001);
}

- (void)testNE {
    OBATripStatusV2 *status = [[OBATripStatusV2 alloc] init];
    status.orientation = 45.f;
    XCTAssertEqualWithAccuracy(status.orientationInRadians, M_PI / 4.f, 0.0001);
}

- (void)testNorth {
    OBATripStatusV2 *status = [[OBATripStatusV2 alloc] init];
    status.orientation = 90.f;
    XCTAssertEqualWithAccuracy(status.orientationInRadians, M_PI_2, 0.0001);
}

- (void)testNW {
    OBATripStatusV2 *status = [[OBATripStatusV2 alloc] init];
    status.orientation = 135.f;
    XCTAssertEqualWithAccuracy(status.orientationInRadians, 0.75f * M_PI, 0.0001);
}

- (void)testWest {
    OBATripStatusV2 *status = [[OBATripStatusV2 alloc] init];
    status.orientation = 180.f;
    XCTAssertEqualWithAccuracy(status.orientationInRadians, M_PI, 0.0001);
}

- (void)testSW {
    OBATripStatusV2 *status = [[OBATripStatusV2 alloc] init];
    status.orientation = 225.f;
    XCTAssertEqualWithAccuracy(status.orientationInRadians, 1.25f * M_PI, 0.0001);
}

- (void)testSouth {
    OBATripStatusV2 *status = [[OBATripStatusV2 alloc] init];
    status.orientation = 270.f;
    XCTAssertEqualWithAccuracy(status.orientationInRadians, 3.f * M_PI_2, 0.0001);
}

- (void)testSE {
    OBATripStatusV2 *status = [[OBATripStatusV2 alloc] init];
    status.orientation = 315.f;
    XCTAssertEqualWithAccuracy(status.orientationInRadians, (7.f / 4.f) * M_PI, 0.0001);
}

@end
