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
@property(nonatomic,strong) OBAEmailHelper *emailHelper;
@end

@implementation OBAEmailHelper_Tests

- (void)setUp {
    [super setUp];

    [OBAEmailHelper setOSVersion:kOSVersion];
    [OBAEmailHelper setAppVersion:kAppVersion];
    self.persistenceLayer = [[OBATestHarnessPersistenceLayer alloc] init];
    self.modelDAO = [[OBAModelDAO alloc] initWithModelPersistenceLayer:self.persistenceLayer];
    self.modelDAO.currentRegion = [OBATestHelpers pugetSoundRegion];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:45.12 longitude:45.99];
    self.emailHelper = [[OBAEmailHelper alloc] initWithModelDAO:self.modelDAO currentLocation:location registeredForRemoteNotifications:YES locationAuthorizationStatus:kCLAuthorizationStatusAuthorizedWhenInUse userDefaultsData:[NSData new]];
}

- (void)testMessageBodyForModelDAO {
    NSString *messageBody = [self.emailHelper.messageBody stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    messageBody = [messageBody stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    messageBody = [messageBody stringByReplacingOccurrencesOfString:@" " withString:@""];

    NSString *expectedBody = [OBATestHelpers contentsOfTestFile:@"testMessageBodyForModelDAO.html"];
    [expectedBody stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    expectedBody = [expectedBody stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    expectedBody = [expectedBody stringByReplacingOccurrencesOfString:@" " withString:@""];

    XCTAssertEqualObjects(expectedBody, messageBody);
}

@end
