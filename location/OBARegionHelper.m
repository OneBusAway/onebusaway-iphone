//
//  OBARegionHelper.m
//  org.onebusaway.iphone
//
//  Created by Sebastian Kießling on 11.08.13.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

#import "OBARegionHelper.h"
#import "OBAApplicationDelegate.h"
#import "OBAAnalytics.h"
#import "OBAApplication.h"

@interface OBARegionHelper ()
@property (nonatomic) NSMutableArray *regions;
@property (nonatomic) CLLocation *location;
@end

@implementation OBARegionHelper

- (void)updateNearestRegion {
    [self updateRegion];
    OBALocationManager *lm = [OBAApplication instance].locationManager;
    [lm addDelegate:self];
    [lm startUpdatingLocation];
}

- (void)updateRegion {
    [[OBAApplication instance].modelService
     requestRegions:^(id responseData, NSUInteger responseCode, NSError *error) {
         [self processRegionData:responseData];
     }];
}

- (void)processRegionData:(id)regionData {
    OBAListWithRangeAndReferencesV2 *list = regionData;

    self.regions = [[NSMutableArray alloc] initWithArray:list.values];

    if ([OBAApplication instance].modelDao.readSetRegionAutomatically && [OBAApplication instance].locationManager.locationServicesEnabled) {
        [self setNearestRegion];
    }
    else {
        [self setRegion];
    }
}

- (void)setNearestRegion {
    if (self.regions && self.location) {
        NSMutableArray *notSupportedRegions = [NSMutableArray array];

        for (id obj in self.regions) {
            OBARegionV2 *region = (OBARegionV2 *)obj;
            BOOL showExperimentalRegions = NO;

            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"kOBAShowExperimentalRegionsDefaultsKey"]) showExperimentalRegions = [[NSUserDefaults standardUserDefaults]
                                                                                                                                         boolForKey:@"kOBAShowExperimentalRegionsDefaultsKey"];

            if (!region.supportsObaRealtimeApis || !region.active  ||
                (region.experimental && !showExperimentalRegions)) {
                [notSupportedRegions addObject:region];
            }
        }

        [self.regions removeObjectsInArray:notSupportedRegions];

        OBALocationManager *lm = [OBAApplication instance].locationManager;
        CLLocation *newLocation = lm.currentLocation;

        NSMutableArray *regionsToRemove = [NSMutableArray array];

        for (id obj in self.regions) {
            OBARegionV2 *region = (OBARegionV2 *)obj;
            CLLocationDistance distance = [region distanceFromLocation:newLocation];

            if (distance > 160934) { // 100 miles
                [regionsToRemove addObject:obj];
            }
        }

        [self.regions removeObjectsInArray:regionsToRemove];

        if (self.regions.count == 0) {
            [APP_DELEGATE writeSetRegionAutomatically:NO];
            [[OBAApplication instance].locationManager removeDelegate:self];
            [APP_DELEGATE showRegionListViewController];
            return;
        }

        [self.regions
         sortUsingComparator:^(id obj1, id obj2) {
             OBARegionV2 *region1 = (OBARegionV2 *)obj1;
             OBARegionV2 *region2 = (OBARegionV2 *)obj2;

             CLLocationDistance distance1 = [region1 distanceFromLocation:newLocation];
             CLLocationDistance distance2 = [region2 distanceFromLocation:newLocation];

             if (distance1 > distance2) {
                return (NSComparisonResult)NSOrderedDescending;
             }
             else if (distance1 < distance2) {
                return (NSComparisonResult)NSOrderedAscending;
             }
             else {
                return (NSComparisonResult)NSOrderedSame;
             }
         }];

        NSString *oldRegion = @"null";

        if ([OBAApplication instance].modelDao.region != nil) {
            oldRegion = [OBAApplication instance].modelDao.region.regionName;
        }

        [[OBAApplication instance].modelDao setOBARegion:self.regions[0]];
        [[OBAApplication instance] refreshSettings];
        [[OBAApplication instance].locationManager removeDelegate:self];
        [APP_DELEGATE writeSetRegionAutomatically:YES];

        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryAppSettings action:@"configured_region_auto" label:[NSString stringWithFormat:@"Set Region Automatically: %@; Old Region: %@", [OBAApplication instance].modelDao.region.regionName, oldRegion] value:nil];
    }
}

- (void)setRegion {
    NSString *regionName = [OBAApplication instance].modelDao.region.regionName;

    if (regionName) {
        for (OBARegionV2 *region in self.regions) {
            if ([region.regionName isEqualToString:regionName]) {
                [[OBAApplication instance].modelDao setOBARegion:region];
                break;
            }
        }
    }
    else {
        [APP_DELEGATE showRegionListViewController];
    }
}

#pragma mark OBALocationManagerDelegate Methods


- (void)locationManager:(OBALocationManager *)manager didUpdateLocation:(CLLocation *)location {
    self.location = [OBAApplication instance].locationManager.currentLocation;
   [self setNearestRegion];
}

- (void)locationManager:(OBALocationManager *)manager didFailWithError:(NSError *)error {
    if (![OBAApplication instance].modelDao.region) {
        [APP_DELEGATE showRegionListViewController];
    }

    [[OBAApplication instance].locationManager removeDelegate:self];
}

@end
