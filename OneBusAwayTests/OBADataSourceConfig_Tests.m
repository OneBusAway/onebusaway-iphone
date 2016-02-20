//
//  OBADataSourceConfig_Tests.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/16/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OBADataSourceConfig.h"

@interface OBADataSourceConfig_Tests : XCTestCase

@end

@implementation OBADataSourceConfig_Tests

- (void)testExample {
    NSURL *URL = [NSURL URLWithString:@"http://api.pugetsound.onebusaway.org"];
    OBADataSourceConfig *config = [[OBADataSourceConfig alloc] initWithURL:URL args:nil];
    NSURL *fooURL = [config constructURL:@"/foo.json" withArgs:nil];

    XCTAssertEqualObjects([NSURL URLWithString:@"http://api.pugetsound.onebusaway.org/foo.json"], fooURL);
}

- (void)testDefaultParameters {
    OBADataSourceConfig *googleMapsDataSourceConfig = [[OBADataSourceConfig alloc] initWithURL:[NSURL URLWithString:@"https://maps.googleapis.com"] args:@{@"sensor": @"true"}];

    NSURL *testURL = [googleMapsDataSourceConfig constructURL:@"/something-goes-here.json" withArgs:@{@"hello": @"world", @"foo": @"bar"}];

    BOOL nonDeterminismSucks = ([testURL.absoluteString isEqual:@"https://maps.googleapis.com/something-goes-here.json?sensor=true&foo=bar&hello=world"] ||
                                [testURL.absoluteString isEqual:@"https://maps.googleapis.com/something-goes-here.json?sensor=true&hello=world&foo=bar"]);

    XCTAssert(nonDeterminismSucks);
}

@end
