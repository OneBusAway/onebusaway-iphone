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
    OBALocationManager *lm = [OBAApplication sharedApplication].locationManager;
    [lm addDelegate:self];
    [lm startUpdatingLocation];
}

- (void)updateRegion {
    [[OBAApplication sharedApplication].modelService
     requestRegions:^(id responseData, NSUInteger responseCode, NSError *error) {
         [self processRegionData:responseData];
     }];
}

- (void)processRegionData:(id)regionData {
    OBAListWithRangeAndReferencesV2 *list = regionData;

    self.regions = [[NSMutableArray alloc] initWithArray:list.values];

    if ([OBAApplication sharedApplication].modelDao.readSetRegionAutomatically && [OBAApplication sharedApplication].locationManager.locationServicesEnabled) {
        [self setNearestRegion];
    }
    else {
        [self setRegion];
    }
}

- (void)setNearestRegion {
    if (self.regions && self.location) {
        NSMutableArray *notSupportedRegions = [NSMutableArray array];

        for (OBARegionV2 *region in self.regions) {
            BOOL showExperimentalRegions = NO;

            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"kOBAShowExperimentalRegionsDefaultsKey"]) showExperimentalRegions = [[NSUserDefaults standardUserDefaults]
                                                                                                                                         boolForKey:@"kOBAShowExperimentalRegionsDefaultsKey"];

            if (!region.supportsObaRealtimeApis || !region.active  ||
                (region.experimental && !showExperimentalRegions)) {
                [notSupportedRegions addObject:region];
            }
        }

        [self.regions removeObjectsInArray:notSupportedRegions];

        OBALocationManager *lm = [OBAApplication sharedApplication].locationManager;
        CLLocation *newLocation = lm.currentLocation;

        NSMutableArray *regionsToRemove = [NSMutableArray array];

        for (OBARegionV2 *region in self.regions) {
            CLLocationDistance distance = [region distanceFromLocation:newLocation];

            if (distance > 160934) { // 100 miles
                [regionsToRemove addObject:region];
            }
        }

        [self.regions removeObjectsInArray:regionsToRemove];

        if (self.regions.count == 0) {
            [APP_DELEGATE writeSetRegionAutomatically:NO];
            [[OBAApplication sharedApplication].locationManager removeDelegate:self];
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

        if ([OBAApplication sharedApplication].modelDao.region != nil) {
            oldRegion = [OBAApplication sharedApplication].modelDao.region.regionName;
        }

        [[OBAApplication sharedApplication].modelDao setOBARegion:self.regions[0]];
        [[OBAApplication sharedApplication] refreshSettings];
        [[OBAApplication sharedApplication].locationManager removeDelegate:self];
        [APP_DELEGATE writeSetRegionAutomatically:YES];

        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryAppSettings action:@"configured_region_auto" label:[NSString stringWithFormat:@"Set Region Automatically: %@; Old Region: %@", [OBAApplication sharedApplication].modelDao.region.regionName, oldRegion] value:nil];
    }
}

- (void)setRegion {
    NSString *regionName = [OBAApplication sharedApplication].modelDao.region.regionName;

    if (regionName) {
        for (OBARegionV2 *region in self.regions) {
            if ([region.regionName isEqualToString:regionName]) {
                [[OBAApplication sharedApplication].modelDao setOBARegion:region];
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
    self.location = [OBAApplication sharedApplication].locationManager.currentLocation;
    [self setNearestRegion];
}

- (void)locationManager:(OBALocationManager *)manager didFailWithError:(NSError *)error {
    if (![OBAApplication sharedApplication].modelDao.region) {
        [APP_DELEGATE showRegionListViewController];
    }

    [[OBAApplication sharedApplication].locationManager removeDelegate:self];
}

@end
