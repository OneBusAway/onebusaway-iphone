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

@interface OBARegionHelper ()

@property (nonatomic) NSMutableArray *regions;
@property (nonatomic) CLLocation *location;
@property (nonatomic) OBAApplicationDelegate *appDelegate;
- (void) setNearestRegion;
- (void) setRegion;
@end

@implementation OBARegionHelper

- (id) init {
    self = [super init];
    if (self) {
        self.appDelegate = APP_DELEGATE;
    }
    return self;
}


- (void) updateNearestRegion {
    [self updateRegion];
    OBALocationManager * lm = self.appDelegate.locationManager;
	[lm addDelegate:self];
	[lm startUpdatingLocation];
}

- (void) updateRegion {
    [self.appDelegate.modelService requestRegions:^(id responseData, NSUInteger responseCode, NSError *error) {
        [self processRegionData:responseData];
    }];
}

-(void) processRegionData:(id) regionData {
    OBAListWithRangeAndReferencesV2 * list = regionData;
	self.regions = [[NSMutableArray alloc] initWithArray:list.values];
    
    if (self.appDelegate.modelDao.readSetRegionAutomatically && self.appDelegate.locationManager.locationServicesEnabled) {
        [self setNearestRegion];
    } else {
        [self setRegion];
    }
}

- (void) setNearestRegion{
    
    if (self.regions && self.location) {
        NSMutableArray *notSupportedRegions = [NSMutableArray array];
        for (id obj in self.regions) {
            OBARegionV2 *region = (OBARegionV2 *)obj;
            BOOL showExperimentalRegions = NO;
            if ([[NSUserDefaults standardUserDefaults] boolForKey: @"kOBAShowExperimentalRegionsDefaultsKey"])
                showExperimentalRegions = [[NSUserDefaults standardUserDefaults]
                                            boolForKey: @"kOBAShowExperimentalRegionsDefaultsKey"];
            
            if (!region.supportsObaRealtimeApis || !region.active  ||
                (region.experimental && !showExperimentalRegions)) {
                [notSupportedRegions addObject:region];
            }
        }
        [self.regions removeObjectsInArray:notSupportedRegions];
        
        OBALocationManager * lm = self.appDelegate.locationManager;
        CLLocation * newLocation = lm.currentLocation;
        
        NSMutableArray *regionsToRemove = [NSMutableArray array];
        for (id obj in self.regions) {
            OBARegionV2 *region = (OBARegionV2 *) obj;
            CLLocationDistance distance = [region distanceFromLocation:newLocation];
            if (distance > 160934) { // 100 miles
                [regionsToRemove addObject:obj];
            }
        }
        
        [self.regions removeObjectsInArray:regionsToRemove];
        if (self.regions.count == 0) {
            [self.appDelegate.modelDao writeSetRegionAutomatically:NO];
            [self.appDelegate.locationManager removeDelegate:self];
            [self.appDelegate showRegionListViewController];
            return;
        }
        [self.regions sortUsingComparator:^(id obj1, id obj2) {
            OBARegionV2 *region1 = (OBARegionV2*) obj1;
            OBARegionV2 *region2 = (OBARegionV2*) obj2;
            
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

        NSString * oldRegion = @"null";
        if(self.appDelegate.modelDao.region != nil){
            oldRegion = self.appDelegate.modelDao.region.regionName;
        }

        [self.appDelegate.modelDao setOBARegion:[self.regions objectAtIndex:0]];
        [self.appDelegate refreshSettings];
        [self.appDelegate.locationManager removeDelegate:self];
        [self.appDelegate.modelDao writeSetRegionAutomatically:YES];

        [OBAAnalytics reportEventWithCategory:@"app_settings" action:@"configured_region_auto" label:[NSString stringWithFormat:@"Set Region Automatically: %@; Old Region: %@", self.appDelegate.modelDao.region.regionName, oldRegion] value:nil];
    }
     
}

- (void) setRegion {
    NSString *regionName = self.appDelegate.modelDao.region.regionName;
    if (regionName) {
        for (OBARegionV2 *region in self.regions) {
            if ([region.regionName isEqualToString:regionName]) {
                [self.appDelegate.modelDao setOBARegion:region];
                break;
            }
        }
    } else {
        [self.appDelegate showRegionListViewController]; 
    }

}

#pragma mark OBALocationManagerDelegate Methods


- (void) locationManager:(OBALocationManager *)manager didUpdateLocation:(CLLocation *)location {
    OBALocationManager * lm = self.appDelegate.locationManager;
	self.location = lm.currentLocation;

    [self setNearestRegion];
}
- (void)locationManager:(OBALocationManager *)manager didFailWithError:(NSError *)error {
    if (self.appDelegate.modelDao.region == nil) {
        [self.appDelegate showRegionListViewController];
    }
    [self.appDelegate.locationManager removeDelegate:self];

}


@end
