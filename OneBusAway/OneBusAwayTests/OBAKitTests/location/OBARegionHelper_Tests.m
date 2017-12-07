//
//  OBARegionHelper_Tests.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 9/29/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <XCTest/XCTest.h>
@import OBAKit;
#import "OBATestHelpers.h"

@interface OBALocationManager (Testing)
@property(nonatomic,copy,readwrite) CLLocation *currentLocation;
@end

@interface OBARegionHelper (Testing)
@property(nonatomic,strong) NSMutableArray *regions;
@end

@interface OBARegionHelper_Tests : XCTestCase
@property(nonatomic,strong) OBATestHarnessPersistenceLayer *persistenceLayer;
@property(nonatomic,strong) OBAModelDAO *modelDAO;
@property(nonatomic,strong) OBAModelService *modelService;
@property(nonatomic,strong) OBALocationManager *locationManager;
@end

@implementation OBARegionHelper_Tests

- (void)setUp {
    [super setUp];

    CLLocation *tampaLocation = [[CLLocation alloc] initWithLatitude:28.0587 longitude:-82.4139];

    self.persistenceLayer = [[OBATestHarnessPersistenceLayer alloc] init];
    [self.persistenceLayer writeSetRegionAutomatically:NO];
    [self.persistenceLayer writeOBARegion:[OBATestHelpers pugetSoundRegion]];
    self.modelDAO = [[OBAModelDAO alloc] initWithModelPersistenceLayer:self.persistenceLayer];
    self.modelService = [OBATestHelpers tampaModelService];
    self.locationManager = [[OBALocationManager alloc] initWithModelDAO:self.modelDAO];
    self.locationManager.currentLocation = tampaLocation;
}

- (void)testSetup {
    XCTAssertEqualObjects(self.modelDAO.currentRegion, [OBATestHelpers pugetSoundRegion]);
}

- (void)testRegionUpdates {
    OBARegionHelper *regionHelper = [[OBARegionHelper alloc] initWithLocationManager:self.locationManager modelService:self.modelService];
    regionHelper.modelDAO = self.modelDAO;
    regionHelper.regions = [[NSMutableArray alloc] initWithObjects:[OBATestHelpers pugetSoundRegion], [OBATestHelpers tampaRegion], nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:OBALocationDidUpdateNotification object:self.locationManager userInfo:nil];

    XCTAssertEqualObjects(self.modelDAO.currentRegion, [OBATestHelpers pugetSoundRegion]);
}

@end
