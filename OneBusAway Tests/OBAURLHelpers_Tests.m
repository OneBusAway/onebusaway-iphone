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

@end
