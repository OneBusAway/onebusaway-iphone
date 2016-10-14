//
//  OBAAgencyV2_Tests.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/25/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OBATestHelpers.h"

#import <OBAKit/OBAModelFactory.h>
#import <OBAKit/OBAReferencesV2.h>
#import <OBAKit/OBAAgencyV2.h>

@interface OBAAgencyV2_Tests : XCTestCase
@property(nonatomic,strong) OBAModelFactory *modelFactory;
@property(nonatomic,strong) OBAReferencesV2 *references;
@end

@implementation OBAAgencyV2_Tests

- (void)setUp {
    [super setUp];

    self.references = [[OBAReferencesV2 alloc] init];
    self.modelFactory = [[OBAModelFactory alloc] initWithReferences:self.references];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - NSCoding

- (void)testCoding {
    OBAAgencyV2 *agency = [[OBAAgencyV2 alloc] initWithReferences:self.references];
    agency.agencyId = @"an_id";
    agency.url = @"http://example.com/an_id";
    agency.name = @"a name";

    NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:agency];

    OBAAgencyV2 *unarchived = [NSKeyedUnarchiver unarchiveObjectWithData:archivedData];

    XCTAssertNotEqual(agency, unarchived);

    XCTAssertNotNil(unarchived.agencyId);
    XCTAssertEqualObjects(agency.agencyId, unarchived.agencyId);

    XCTAssertNotNil(unarchived.url);
    XCTAssertEqualObjects(agency.url, unarchived.url);

    XCTAssertNotNil(unarchived.name);
    XCTAssertEqualObjects(agency.name, unarchived.name);
}

@end
