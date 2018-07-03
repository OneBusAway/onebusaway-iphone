//
//  OBADataSourceConfig_Tests.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 9/21/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <XCTest/XCTest.h>
@import OBAKit;

@interface OBADataSourceConfig_Tests : XCTestCase

@end

@implementation OBADataSourceConfig_Tests

- (void)testSimpleAPIConstruction {
    NSURL *URL = [NSURL URLWithString:@"http://api.pugetsound.onebusaway.org"];
    OBADataSourceConfig *config = [[OBADataSourceConfig alloc] initWithBaseURL:URL userID:nil checkStatusCodeInBody:NO];
    NSURL *fooURL = [config constructURL:@"/foo.json" withArgs:nil];

    XCTAssertEqualObjects([NSURL URLWithString:@"http://api.pugetsound.onebusaway.org/foo.json?"], fooURL);
}

- (void)testTampaConstruction {
    OBADataSourceConfig *tampa = [self buildTampaConfig];

    NSString *apiPath = @"/api/where/stops-for-location.json";
    NSDictionary *apiArgs = @{
        @"lat": @(28.05869999999996),
        @"latSpan": @(0.005754244055234281),
        @"lon": @(-82.41389999999997),
        @"lonSpan": @(0.004585944745571169)
    };

    NSURLComponents *constructedComponents = [NSURLComponents componentsWithURL:[tampa constructURL:apiPath withArgs:apiArgs] resolvingAgainstBaseURL:NO];
    NSArray<NSURLQueryItem*>* constructedQueryItems = constructedComponents.queryItems;
    constructedComponents.queryItems = nil;
    NSURL *constructedURL = constructedComponents.URL;

    NSURL *goodURL = [NSURL URLWithString:@"http://api.tampa.onebusaway.org/api/api/where/stops-for-location.json"];

    NSArray *goodQueryItems = @[
                                [NSURLQueryItem queryItemWithName:@"key" value:@"org.onebusaway.iphone"],
                                [NSURLQueryItem queryItemWithName:@"app_uid" value:@"8F97F623-B527-4E99-9268-42AC6F27DCA5"],
                                [NSURLQueryItem queryItemWithName:@"app_ver" value:@"20160920.00"],
                                [NSURLQueryItem queryItemWithName:@"version" value:@"2"],
                                [NSURLQueryItem queryItemWithName:@"lat" value:@"28.05869999999996"],
                                [NSURLQueryItem queryItemWithName:@"lon" value:@"-82.41389999999997"],
                                [NSURLQueryItem queryItemWithName:@"lonSpan" value:@"0.004585944745571169"],
                                [NSURLQueryItem queryItemWithName:@"latSpan" value:@"0.005754244055234281"]
                                ];

    XCTAssertEqualObjects(constructedURL, goodURL);
    XCTAssertEqualObjects([NSSet setWithArray:constructedQueryItems], [NSSet setWithArray:goodQueryItems]);
}

#pragma mark - Helpers

- (OBADataSourceConfig*)buildTampaConfig {
    return [[OBADataSourceConfig alloc] initWithURL:[NSURL URLWithString:@"http://api.tampa.onebusaway.org/api/"]
                                               args:@{
                                                      @"app_uid": @"8F97F623-B527-4E99-9268-42AC6F27DCA5",
                                                      @"app_ver": @"20160920.00",
                                                      @"key": @"org.onebusaway.iphone",
                                                      @"version": @2
                                                      }];
}

@end
