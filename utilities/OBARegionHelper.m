//
//  OBARegionHelper.m
//  org.onebusaway.iphone
//
//  Created by Sebastian Kießling on 11.08.13.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

#import "OBARegionHelper.h"
#import "OBAApplicationDelegate.h"

@interface OBARegionHelper ()

@property (nonatomic) NSMutableArray *regions;
@property (nonatomic) CLLocation *location;
- (void) setNearestRegion;
@end

@implementation OBARegionHelper

- (void) updateNearestRegion {
    OBAApplicationDelegate *appDelegate = APP_DELEGATE;
    [appDelegate.modelService requestRegions:self withContext:nil];
    OBALocationManager * lm = appDelegate.locationManager;
	[lm addDelegate:self];
	[lm startUpdatingLocation];
}

- (void) setNearestRegion{
    
    if (self.regions && self.location) {
        NSMutableArray *notSupportedRegions = [NSMutableArray array];
        for (id obj in self.regions) {
            OBARegionV2 *region = (OBARegionV2 *)obj;
            if (!region.supportsObaRealtimeApis || !region.active) {
                [notSupportedRegions addObject:region];
            }
        }
        [self.regions removeObjectsInArray:notSupportedRegions];
        
        OBAApplicationDelegate *appDelegate = APP_DELEGATE;
        OBALocationManager * lm = appDelegate.locationManager;
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
        
        [appDelegate.modelDao setOBARegion:[self.regions objectAtIndex:0]];
        [appDelegate regionSelected];
        [appDelegate.locationManager removeDelegate:self];
        [appDelegate.modelDao writeSetRegionAutomatically:YES];
    }
     
}
#pragma mark OBAModelServiceDelegate

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {
    
    OBAListWithRangeAndReferencesV2 * list = obj;
	self.regions = [[NSMutableArray alloc] initWithArray:list.values];
    [self setNearestRegion];
    

}

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withCode:(NSInteger)code context:(id)context {
}

- (void)requestDidFail:(id<OBAModelServiceRequest>)request withError:(NSError *)error context:(id)context {
}

- (void)request:(id<OBAModelServiceRequest>)request withProgress:(float)progress context:(id)context {

}



#pragma mark OBALocationManagerDelegate Methods


- (void) locationManager:(OBALocationManager *)manager didUpdateLocation:(CLLocation *)location {
    OBAApplicationDelegate *appDelegate = APP_DELEGATE;
    OBALocationManager * lm = appDelegate.locationManager;
	self.location = lm.currentLocation;

    [self setNearestRegion];
}
- (void)locationManager:(OBALocationManager *)manager didFailWithError:(NSError *)error {
    OBAApplicationDelegate *appDelegate = APP_DELEGATE;
    if (appDelegate.modelDao.region == nil) {
        [appDelegate showRegionListViewController];
    }
    [appDelegate.locationManager removeDelegate:self];

}


@end
