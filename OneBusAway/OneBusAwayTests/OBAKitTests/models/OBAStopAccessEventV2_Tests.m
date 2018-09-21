//
//  OBAStopAccessEventV2_Tests.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/25/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OBATestHelpers.h"

#import <OBAKit/OBAModelFactory.h>
#import <OBAKit/OBAReferencesV2.h>
#import <OBAKit/OBAStopAccessEventV2.h>

@interface OBAStopAccessEventV2_Tests : XCTestCase
@property(nonatomic,strong) OBAModelFactory *modelFactory;
@end

@implementation OBAStopAccessEventV2_Tests

- (void)setUp {
    [super setUp];

    OBAReferencesV2 *references = [[OBAReferencesV2 alloc] init];
    self.modelFactory = [[OBAModelFactory alloc] initWithReferences:references];
}

- (void)testVerifyLoadingOldObjectFromCoding {
    OBAStopAccessEventV2 *archivedObject = [OBATestHelpers unarchiveBundledTestFile:@"RecentStopWithStopIDs.plist"];
    XCTAssertEqualObjects(archivedObject.title, @"I am a title");
    XCTAssertEqualObjects(archivedObject.subtitle, @"I am a subtitle");
    XCTAssertEqualObjects(archivedObject.stopID, @"12345");
}

- (void)testVerifyRoundtrippingOldObjectFromCoding {
    OBAStopAccessEventV2 *archivedObject = [OBATestHelpers unarchiveBundledTestFile:@"RecentStopWithStopIDs.plist"];
    OBAStopAccessEventV2 *archivedObject2 = [OBATestHelpers roundtripObjectThroughNSCoding:archivedObject];

    XCTAssertEqualObjects(archivedObject2.title, @"I am a title");
    XCTAssertEqualObjects(archivedObject2.subtitle, @"I am a subtitle");
    XCTAssertEqualObjects(archivedObject2.stopID, @"12345");
}

- (void)testVerifyLoadingNewObjectFromCoding {
    OBAStopAccessEventV2 *archivedObject = [OBATestHelpers unarchiveBundledTestFile:@"RecentStopWithStopID.plist"];

    XCTAssertEqualObjects(archivedObject.title, @"I am a title");
    XCTAssertEqualObjects(archivedObject.subtitle, @"I am a subtitle");
    XCTAssertEqualObjects(archivedObject.stopID, @"98765");
}

- (void)testRecentStopWithoutLocation {
    OBAStopAccessEventV2 *event = [[OBAStopAccessEventV2 alloc] init];
    XCTAssertFalse(event.hasLocation);
}

- (void)testLocationCoding {
    OBAStopAccessEventV2 *event = [[OBAStopAccessEventV2 alloc] init];
    event.title = @"a title";
    event.subtitle = @"a subtitle";
    event.stopID = @"12345";
    event.coordinate = CLLocationCoordinate2DMake(47.6235294, -122.3126582);

    XCTAssertTrue(event.hasLocation);

    OBAStopAccessEventV2 *round2 = [OBATestHelpers roundtripObjectThroughNSCoding:event];

    XCTAssertEqualObjects(round2.title, @"a title");
    XCTAssertEqualObjects(round2.subtitle, @"a subtitle");
    XCTAssertEqualObjects(round2.stopID, @"12345");
    XCTAssertEqual(round2.coordinate.latitude, 47.6235294);
    XCTAssertEqual(round2.coordinate.longitude, -122.3126582);

    XCTAssertEqualObjects(event, round2);
}

@end
