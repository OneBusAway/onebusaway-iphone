//
//  OBATripDetailsV2_Tests.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/25/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OBATestHelpers.h"

#import <OBAKit/OBAModelFactory.h>
#import <OBAKit/OBAReferencesV2.h>
#import <OBAKit/OBATripDetailsV2.h>

/**
 TODO: WRITE TESTS
 */

@interface OBATripDetailsV2_Tests : XCTestCase
@property(nonatomic,strong) OBAModelFactory *modelFactory;
@end

@implementation OBATripDetailsV2_Tests

- (void)setUp {
    [super setUp];

    OBAReferencesV2 *references = [[OBAReferencesV2 alloc] init];
    self.modelFactory = [[OBAModelFactory alloc] initWithReferences:references];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    XCTAssertTrue(YES);
}

@end
