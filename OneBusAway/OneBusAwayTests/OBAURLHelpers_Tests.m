//
//  OBAURLHelpers_Tests.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/22/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OBAKit/OBAURLHelpers.h>

@interface OBAURLHelpers_Tests : XCTestCase

@end

@implementation OBAURLHelpers_Tests

+ (NSURL*)yorkResultURL {
    return [NSURL URLWithString:@"http://oba.yrt.ca/api/where/current-time.json?key=org.onebusaway.iphone"];
}

+ (NSURL*)tampaResultURL {
    return [NSURL URLWithString:@"http://api.tampa.onebusaway.org/api/where/current-time.json?key=org.onebusaway.iphone"];
}

+ (NSURL*)pugetSoundResultURL {
    return [NSURL URLWithString:@"http://api.pugetsound.onebusaway.org/api/where/current-time.json?key=org.onebusaway.iphone"];
}

+ (NSURL*)httpsPugetSoundResultURL {
    return [NSURL URLWithString:@"https://api.pugetsound.onebusaway.org/api/where/current-time.json?key=org.onebusaway.iphone"];
}

+ (NSURL*)busTimeResultURL {
    return [NSURL URLWithString:@"http://bustime.mta.info/api/where/current-time.json?key=org.onebusaway.iphone"];
}

+ (NSURL*)IPAndPortResultURL {
    return [NSURL URLWithString:@"http://194.89.230.196:8080/api/where/current-time.json?key=org.onebusaway.iphone"];
}

+ (NSURL*)portAndPathResultURL {
    return [NSURL URLWithString:@"http://oba.rvtd.org:8080/onebusaway-api-webapp/api/where/current-time.json?key=org.onebusaway.iphone"];
}

#pragma mark - URL Normalization

static NSString * const kOBACurrentTimeURLPath = @"/where/current-time.json";

- (void)testBaseURLNormalization1 {
    NSString *baseURLString = @"app.staging.obahart.org/api";
    NSURL *resultURL = [NSURL URLWithString:@"http://app.staging.obahart.org/api"];
    XCTAssertEqualObjects([OBAURLHelpers normalizeURLPath:@"/" relativeToBaseURL:baseURLString parameters:nil], resultURL);
}

- (void)testBaseURLNormalization2 {
    NSString *baseURLString = @"http://app.staging.obahart.org/api";
    NSURL *resultURL = [NSURL URLWithString:@"http://app.staging.obahart.org/api"];
    XCTAssertEqualObjects([OBAURLHelpers normalizeURLPath:@"/" relativeToBaseURL:baseURLString parameters:nil], resultURL);
}

- (void)testBaseURLNormalization3 {
    NSString *baseURLString = @"http://app.staging.obahart.org/api";
    NSURL *resultURL = [NSURL URLWithString:@"http://app.staging.obahart.org/api"];
    XCTAssertEqualObjects([OBAURLHelpers normalizeURLPath:@"/" relativeToBaseURL:baseURLString parameters:nil], resultURL);
}

- (void)testNormalization {
    NSString *baseURLString = @"http://oba.yrt.ca/";
    XCTAssertEqualObjects([OBAURLHelpers normalizeURLPath:kOBACurrentTimeURLPath relativeToBaseURL:baseURLString parameters:@{@"key": @"org.onebusaway.iphone"}], [OBAURLHelpers_Tests yorkResultURL]);
}

- (void)testNormalizationWithMissingScheme {
    NSString *baseURLString = @"oba.yrt.ca/";
    XCTAssertEqualObjects([OBAURLHelpers normalizeURLPath:kOBACurrentTimeURLPath relativeToBaseURL:baseURLString parameters:@{@"key": @"org.onebusaway.iphone"}], [OBAURLHelpers_Tests yorkResultURL]);
}

- (void)testNormalizationWithPath {
    NSString *baseURLString = @"http://api.tampa.onebusaway.org/api/";
    XCTAssertEqualObjects([OBAURLHelpers normalizeURLPath:kOBACurrentTimeURLPath relativeToBaseURL:baseURLString parameters:@{@"key": @"org.onebusaway.iphone"}], [OBAURLHelpers_Tests tampaResultURL]);
}

- (void)testNormalizationWithHTTPS {
    NSString *baseURLString = @"https://api.pugetsound.onebusaway.org/";
    XCTAssertEqualObjects([OBAURLHelpers normalizeURLPath:kOBACurrentTimeURLPath relativeToBaseURL:baseURLString parameters:@{@"key": @"org.onebusaway.iphone"}], [OBAURLHelpers_Tests httpsPugetSoundResultURL]);
}

- (void)testNormalizationWithMissingSlash {
    NSString *baseURLString = @"http://bustime.mta.info";
    XCTAssertEqualObjects([OBAURLHelpers normalizeURLPath:kOBACurrentTimeURLPath relativeToBaseURL:baseURLString parameters:@{@"key": @"org.onebusaway.iphone"}], [OBAURLHelpers_Tests busTimeResultURL]);
}

- (void)testNormalizationWithIPAndPort {
    NSString *baseURLString = @"http://194.89.230.196:8080/";

    XCTAssertEqualObjects([OBAURLHelpers normalizeURLPath:kOBACurrentTimeURLPath relativeToBaseURL:baseURLString parameters:@{@"key": @"org.onebusaway.iphone"}], [OBAURLHelpers_Tests IPAndPortResultURL]);
}

- (void)testNormalizationWithPortAndPath {
    NSString *baseURLString = @"http://oba.rvtd.org:8080/onebusaway-api-webapp/";
    XCTAssertEqualObjects([OBAURLHelpers normalizeURLPath:kOBACurrentTimeURLPath relativeToBaseURL:baseURLString parameters:@{@"key": @"org.onebusaway.iphone"}], [OBAURLHelpers_Tests portAndPathResultURL]);
}

@end
