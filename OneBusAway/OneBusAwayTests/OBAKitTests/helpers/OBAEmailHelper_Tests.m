//
//  OBAEmailHelper_Tests.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 7/10/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <XCTest/XCTest.h>
@import OBAKit;

#import "OBATestHelpers.h"
#import "OBATestHarnessPersistenceLayer.h"

static NSString * const kOSVersion = @"10.0.OBA_SIM";
static NSString * const kAppVersion = @"2.6.OBA_SIM";

@interface OBAEmailHelper (Internal)
+ (void)setOSVersion:(NSString*)OSVersionOverride;
+ (void)setAppVersion:(NSString*)appVersionOverride;
+ (NSString*)messageBodyForModelDAO:(OBAModelDAO*)modelDAO currentLocation:(CLLocation*)location;
@end

@interface OBAEmailHelper_Tests : XCTestCase
@property(nonatomic,strong) OBATestHarnessPersistenceLayer *persistenceLayer;
@property(nonatomic,strong) OBAModelDAO *modelDAO;
@end

@implementation OBAEmailHelper_Tests

- (void)setUp {
    [super setUp];
    [OBAEmailHelper setOSVersion:kOSVersion];
    [OBAEmailHelper setAppVersion:kAppVersion];
    self.persistenceLayer = [[OBATestHarnessPersistenceLayer alloc] init];
    self.modelDAO = [[OBAModelDAO alloc] initWithModelPersistenceLayer:self.persistenceLayer];
    self.modelDAO.currentRegion = [OBATestHelpers pugetSoundRegion];
}

- (void)testMessageBodyForModelDAO {
    CLLocation *location = [[CLLocation alloc] initWithLatitude:45.12 longitude:45.99];

    NSString *messageBody = [OBAEmailHelper messageBodyForModelDAO:self.modelDAO currentLocation:location];
    NSString *expectedBody = [OBATestHelpers contentsOfTestFile:@"testMessageBodyForModelDAO.html"];

    XCTAssertEqualObjects(expectedBody, messageBody);
}

@end
