//
//  OBAURLHelpers_Tests.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/22/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "OBAURLHelpers.h"

@interface OBAURLHelpers_Tests : XCTestCase

@end

@implementation OBAURLHelpers_Tests

- (void)test3rdAndPike
{
    XCTAssertEqualObjects(@"3rd%20and%20Pike", [OBAURLHelpers escapeStringForUrl:@"3rd and Pike"]);
}

- (void)test3rdAmpPike
{
    XCTAssertEqualObjects(@"3rd%20%26%20Pike", [OBAURLHelpers escapeStringForUrl:@"3rd & Pike"]);
}

- (void)testFullAddress
{
    XCTAssertEqualObjects(@"915%20Northwest%2045th%20Street%2C%20Seattle%2C%20WA%2098107", [OBAURLHelpers escapeStringForUrl:@"915 Northwest 45th Street, Seattle, WA 98107"]);
}

- (void)testPartialAddress
{
    XCTAssertEqualObjects(@"915%20Northwest%2045th%20Street", [OBAURLHelpers escapeStringForUrl:@"915 Northwest 45th Street"]);
}

#pragma mark - URL Normalization

static NSString * const kOBACurrentTimeURLPath = @"/where/current-time.json";

- (void)testNormalization {
    NSString *baseURLString = @"http://oba.yrt.ca/";
    NSURL *resultURL = [NSURL URLWithString:@"http://oba.yrt.ca/where/current-time.json?key=org.onebusaway.iphone"];
    XCTAssertEqualObjects([OBAURLHelpers normalizeURLPath:kOBACurrentTimeURLPath relativeToBaseURL:baseURLString parameters:@{@"key": @"org.onebusaway.iphone"}], resultURL);
}

- (void)testNormalizationWithMissingScheme {
    NSString *baseURLString = @"oba.yrt.ca/";
    NSURL *resultURL = [NSURL URLWithString:@"http://oba.yrt.ca/where/current-time.json?key=org.onebusaway.iphone"];
    XCTAssertEqualObjects([OBAURLHelpers normalizeURLPath:kOBACurrentTimeURLPath relativeToBaseURL:baseURLString parameters:@{@"key": @"org.onebusaway.iphone"}], resultURL);
}

- (void)testNormalizationWithPath {
    NSString *baseURLString = @"http://api.tampa.onebusaway.org/api/";
    NSURL *resultURL = [NSURL URLWithString:@"http://api.tampa.onebusaway.org/api/where/current-time.json?key=org.onebusaway.iphone"];
    XCTAssertEqualObjects([OBAURLHelpers normalizeURLPath:kOBACurrentTimeURLPath relativeToBaseURL:baseURLString parameters:@{@"key": @"org.onebusaway.iphone"}], resultURL);
}

- (void)testNormalizationWithHTTPS {
    NSString *baseURLString = @"https://api.pugetsound.onebusaway.org/";
    NSURL *resultURL = [NSURL URLWithString:@"https://api.pugetsound.onebusaway.org/where/current-time.json?key=org.onebusaway.iphone"];
    XCTAssertEqualObjects([OBAURLHelpers normalizeURLPath:kOBACurrentTimeURLPath relativeToBaseURL:baseURLString parameters:@{@"key": @"org.onebusaway.iphone"}], resultURL);
}

- (void)testNormalizationWithMissingSlash {
    NSString *baseURLString = @"http://bustime.mta.info";
    NSURL *resultURL = [NSURL URLWithString:@"http://bustime.mta.info/where/current-time.json?key=org.onebusaway.iphone"];
    XCTAssertEqualObjects([OBAURLHelpers normalizeURLPath:kOBACurrentTimeURLPath relativeToBaseURL:baseURLString parameters:@{@"key": @"org.onebusaway.iphone"}], resultURL);
}

- (void)testNormalizationWithIPAndPort {
    NSString *baseURLString = @"http://194.89.230.196:8080/";
    NSURL *resultURL = [NSURL URLWithString:@"http://194.89.230.196:8080/where/current-time.json?key=org.onebusaway.iphone"];
    XCTAssertEqualObjects([OBAURLHelpers normalizeURLPath:kOBACurrentTimeURLPath relativeToBaseURL:baseURLString parameters:@{@"key": @"org.onebusaway.iphone"}], resultURL);
}

- (void)testNormalizationWithPortAndPath {
    NSString *baseURLString = @"http://oba.rvtd.org:8080/onebusaway-api-webapp/";
    NSURL *resultURL = [NSURL URLWithString:@"http://oba.rvtd.org:8080/onebusaway-api-webapp/where/current-time.json?key=org.onebusaway.iphone"];
    XCTAssertEqualObjects([OBAURLHelpers normalizeURLPath:kOBACurrentTimeURLPath relativeToBaseURL:baseURLString parameters:@{@"key": @"org.onebusaway.iphone"}], resultURL);
}

@end
