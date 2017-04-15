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

- (void)testDeserialization {
    NSString *sample = @"{\"id\":1330,\"alert_feed_id\":2,\"title\":\"Sounder Everett-Seattle - Delay - Train #1702 (4:33 pm Seattle departure) is delayed approximately 10 minutes\",\"url\":\"http://m.soundtransit.org/node/15271\",\"summary\":\"North Line Train #1702 (4:33 pm Seattle departure) is delayed approximately 10 minutes en route to Everett due to BNSF freight interference.\",\"published_at\":\"2017-03-16T23:49:00.000Z\",\"external_id\":\"15271\",\"created_at\":\"2017-03-16T23:52:25.947Z\",\"updated_at\":\"2017-03-16T23:52:25.947Z\"}";
    NSDictionary *dict = [OBATestHelpers jsonObjectFromString:sample];
    NSError *error = nil;
    OBARegionalAlert *alert = [MTLJSONAdapter modelOfClass:OBARegionalAlert.class fromJSONDictionary:dict error:&error];

    XCTAssertNil(error);

    XCTAssertEqual(alert.identifier, 1330);
    XCTAssertEqualObjects(alert.title, @"Sounder Everett-Seattle - Delay - Train #1702 (4:33 pm Seattle departure) is delayed approximately 10 minutes");
    XCTAssertEqualObjects(alert.summary, @"North Line Train #1702 (4:33 pm Seattle departure) is delayed approximately 10 minutes en route to Everett due to BNSF freight interference.");
    XCTAssertEqualObjects(alert.URL, [NSURL URLWithString:@"http://m.soundtransit.org/node/15271"]);
    XCTAssertEqual(alert.alertFeedID, 2);
    XCTAssertEqualObjects(alert.summary, @"North Line Train #1702 (4:33 pm Seattle departure) is delayed approximately 10 minutes en route to Everett due to BNSF freight interference.");
    XCTAssertEqualObjects(alert.publishedAt, [NSDate dateWithTimeIntervalSince1970:(1489708140+25200)]);
    XCTAssertEqualObjects(alert.externalID, @"15271");
}

@end
