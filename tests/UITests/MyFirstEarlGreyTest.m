//
//  MyFirstEarlGreyTest.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 9/17/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import EarlGrey;
#import <XCTest/XCTest.h>

@interface MyFirstEarlGreyTest : XCTestCase

@end

@implementation MyFirstEarlGreyTest

- (void)testPresenceOfKeyWindow {
    [[EarlGrey selectElementWithMatcher:grey_keyWindow()]
     assertWithMatcher:grey_sufficientlyVisible()];
}
@end
