//
//  OBARegionHelper.m
//  org.onebusaway.iphone
//
//  Created by Sebastian Kießling on 11.08.13.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

#import "OBARegionHelper.h"
#import "OBAApplication.h"
#import "OBAMacros.h"
#import <OBAKit/OBAKit.h>

NSString * const OBARegionDidUpdateNotification = @"OBARegionDidUpdateNotification";

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
    [[OBAApplication sharedApplication].modelService requestRegions:^(id responseData, NSUInteger responseCode, NSError *error) {
        if (error && !responseData) {
            responseData = [self loadDefaultRegions];
        }
        [self processRegionData:responseData];
     }];
}

- (OBAListWithRangeAndReferencesV2*)loadDefaultRegions {

    NSLog(@"Unable to retrieve regions file. Loading default regions from the app bundle.");

    OBAModelFactory *factory = [OBAApplication sharedApplication].modelService.modelFactory;
    NSError *error = nil;

    NSData *data = [[NSData alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"regions-v3" ofType:@"json"]];

    OBAGuard(data.length > 0) else {
        NSLog(@"Unable to load regions from app bundle.");
        return nil;
    }

    id defaultJSONData = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:&error];

    if (!defaultJSONData) {
        NSLog(@"Unable to convert bundled regions into an object. %@", error);
        return nil;
    }

    OBAListWithRangeAndReferencesV2 *references = [factory getRegionsV2FromJson:defaultJSONData error:&error];

    if (error) {
        NSLog(@"Issue parsing bundled JSON data: %@", error);
    }

    return references;
}

- (void)processRegionData:(OBAListWithRangeAndReferencesV2*)regionData {
    OBAGuard(regionData) else {
        return;
    }

    self.regions = [[NSMutableArray alloc] initWithArray:regionData.values];

    if ([OBAApplication sharedApplication].modelDao.automaticallySelectRegion && [OBAApplication sharedApplication].locationManager.locationServicesEnabled) {
        [self setNearestRegion];
    }
    else {
        [self setRegion];
    }
}

- (void)setNearestRegion {
    if (!self.regions || !self.location) {
        return;
    }

    NSMutableArray *notSupportedRegions = [NSMutableArray array];

    for (OBARegionV2 *region in self.regions) {
        if (!region.supportsObaRealtimeApis || !region.active) {
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
        [OBAApplication sharedApplication].modelDao.automaticallySelectRegion = NO;
        [[OBAApplication sharedApplication].locationManager removeDelegate:self];

        [self.delegate regionHelperShowRegionListController:self];
        return;
    }

    [self.regions sortUsingComparator:^(OBARegionV2 *region1, OBARegionV2 *region2) {
        CLLocationDistance distance1 = [region1 distanceFromLocation:newLocation];
        CLLocationDistance distance2 = [region2 distanceFromLocation:newLocation];

        if (distance1 > distance2) {
            return NSOrderedDescending;
        }
        else if (distance1 < distance2) {
            return NSOrderedAscending;
        }
        else {
            return NSOrderedSame;
        }
     }];

    NSString *oldRegion = @"null";

    if ([OBAApplication sharedApplication].modelDao.currentRegion) {
        oldRegion = [OBAApplication sharedApplication].modelDao.currentRegion.regionName;
    }

    [OBAApplication sharedApplication].modelDao.currentRegion = self.regions[0];
    [[OBAApplication sharedApplication] refreshSettings];
    [[OBAApplication sharedApplication].locationManager removeDelegate:self];
    [OBAApplication sharedApplication].modelDao.automaticallySelectRegion = YES;

    [[NSNotificationCenter defaultCenter] postNotificationName:OBARegionDidUpdateNotification object:nil];
}

- (void)setRegion {
    NSString *regionName = [OBAApplication sharedApplication].modelDao.currentRegion.regionName;

    if (!regionName) {
        [self.delegate regionHelperShowRegionListController:self];
        return;
    }

    // TODO: instead of comparing name, the regions' identifiers should be used instead.
    for (OBARegionV2 *region in self.regions) {
        if ([region.regionName isEqual:regionName]) {
            [OBAApplication sharedApplication].modelDao.currentRegion = region;
            break;
        }
    }
}

#pragma mark OBALocationManagerDelegate Methods


- (void)locationManager:(OBALocationManager *)manager didUpdateLocation:(CLLocation *)location {
    self.location = [OBAApplication sharedApplication].locationManager.currentLocation;
    [self setNearestRegion];
}

- (void)locationManager:(OBALocationManager *)manager didFailWithError:(NSError *)error {
    if (![OBAApplication sharedApplication].modelDao.currentRegion) {
        [self.delegate regionHelperShowRegionListController:self];
    }

    [[OBAApplication sharedApplication].locationManager removeDelegate:self];
}

@end
