//
//  OBARegionHelper.m
//  org.onebusaway.iphone
//
//  Created by Sebastian Kießling on 11.08.13.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

#import <OBAKit/OBARegionHelper.h>
#import <OBAKit/OBAApplication.h>
#import <OBAKit/OBAMacros.h>

@interface OBARegionHelper ()
@property(nonatomic,strong) NSMutableArray *regions;
@end

@implementation OBARegionHelper

- (instancetype)initWithLocationManager:(OBALocationManager*)locationManager {
    self = [super init];

    if (self) {
        _locationManager = locationManager;
        [self registerForLocationNotifications];
    }
    return self;
}

- (void)dealloc {
    [self unregisterFromLocationNotifications];
}

- (void)updateNearestRegion {
    [self updateRegion];
    [self.locationManager startUpdatingLocation];
}

- (void)updateRegion {
    [self.modelService requestRegions:^(id responseData, NSUInteger responseCode, NSError *error) {
        if (error && !responseData) {
            responseData = [self loadDefaultRegions];
        }
        [self processRegionData:responseData];
     }];
}

- (OBAListWithRangeAndReferencesV2*)loadDefaultRegions {
    NSLog(@"Unable to retrieve regions file. Loading default regions from the app bundle.");

    OBAModelFactory *factory = self.modelService.modelFactory;
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

    if (self.modelDAO.automaticallySelectRegion && self.locationManager.locationServicesEnabled) {
        [self setNearestRegion];
    }
    else {
        [self setRegion];
    }
}

- (void)setNearestRegion {
    OBAGuard(self.regions.count > 0) else {
        return;
    }

    NSMutableArray *notSupportedRegions = [NSMutableArray array];

    for (OBARegionV2 *region in self.regions) {
        if (!region.supportsObaRealtimeApis || !region.active) {
            [notSupportedRegions addObject:region];
        }
    }

    [self.regions removeObjectsInArray:notSupportedRegions];

    CLLocation *newLocation = self.locationManager.currentLocation;

    NSMutableArray *regionsToRemove = [NSMutableArray array];

    for (OBARegionV2 *region in self.regions) {
        CLLocationDistance distance = [region distanceFromLocation:newLocation];

        if (distance > 160934) { // 100 miles
            [regionsToRemove addObject:region];
        }
    }

    [self.regions removeObjectsInArray:regionsToRemove];

    if (self.regions.count == 0) {
        self.modelDAO.automaticallySelectRegion = NO;
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

    self.modelDAO.currentRegion = self.regions[0];
    self.modelDAO.automaticallySelectRegion = YES;
}

- (void)setRegion {
    NSString *regionName = self.modelDAO.currentRegion.regionName;

    if (!regionName) {
        [self.delegate regionHelperShowRegionListController:self];
        return;
    }

    // TODO: instead of comparing name, the regions' identifiers should be used instead.
    for (OBARegionV2 *region in self.regions) {
        if ([region.regionName isEqual:regionName]) {
            self.modelDAO.currentRegion = region;
            break;
        }
    }
}

#pragma mark - Lazy Loaders

- (OBAModelDAO*)modelDAO {
    if (!_modelDAO) {
        _modelDAO = [OBAApplication sharedApplication].modelDao;
    }
    return _modelDAO;
}

- (OBAModelService*)modelService {
    if (!_modelService) {
        _modelService = [OBAApplication sharedApplication].modelService;
    }
    return _modelService;
}

#pragma mark - OBALocationManager Notifications

- (void)registerForLocationNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationManagerDidUpdateLocation:) name:OBALocationDidUpdateNotification object:self.locationManager];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationManagerDidFailWithError:) name:OBALocationManagerDidFailWithErrorNotification object:self.locationManager];
}

- (void)unregisterFromLocationNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OBALocationDidUpdateNotification object:self.locationManager];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OBALocationManagerDidFailWithErrorNotification object:self.locationManager];
}

- (void)locationManagerDidUpdateLocation:(NSNotification*)note {
    if (self.modelDAO.automaticallySelectRegion) {
        [self setNearestRegion];
    }
}

- (void)locationManagerDidFailWithError:(NSNotification*)note {
    if (!self.modelDAO.currentRegion) {
        [self.delegate regionHelperShowRegionListController:self];
    }
}

@end
