//
//  NSArray_OBAAdditions_Tests.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 9/23/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OBAKit/OBAKit.h>

@interface NSArray_OBAAdditions_Tests : XCTestCase

@end

@implementation NSArray_OBAAdditions_Tests

- (void)testSimpleCase {
    NSArray *input = @[@{@"category": @"clothes", @"name": @"pants"}, @{@"category": @"clothes", @"name": @"socks"}, @{@"category": @"power tools", @"name": @"power saw"}];
    NSDictionary *expectedOutput = @{
                                     @"clothes": @[@{@"category": @"clothes", @"name": @"pants"}, @{@"category": @"clothes", @"name": @"socks"}],
                                     @"power tools": @[@{@"category": @"power tools", @"name": @"power saw"}]
                                     };
    NSDictionary *actualOutput = [input oba_groupByKey:@"category"];

    XCTAssertEqualObjects(expectedOutput, actualOutput);
}

- (void)testNull {
    NSArray *input = @[@{@"category": @"clothes", @"name": @"pants"}, @{@"category": @"clothes", @"name": @"socks"}, @{@"category": @"power tools", @"name": @"power saw"}, @{@"name": @"Uncategorized"}];
    NSDictionary *expectedOutput = @{
                                     @"clothes": @[@{@"category": @"clothes", @"name": @"pants"}, @{@"category": @"clothes", @"name": @"socks"}],
                                     @"power tools": @[@{@"category": @"power tools", @"name": @"power saw"}]
                                     };
    NSDictionary *actualOutput = [input oba_groupByKey:@"category"];

    XCTAssertEqualObjects(expectedOutput, actualOutput);
}

@end
