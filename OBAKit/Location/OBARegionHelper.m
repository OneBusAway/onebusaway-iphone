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
#import <OBAKit/OBALogging.h>
#import <OBAKit/OBARegionStorage.h>
#import <OBAKit/OBAKit-Swift.h>

@interface OBARegionHelper ()
@property(nonatomic,strong) OBARegionsService* modelService;
@property(nonatomic,strong) PromiseWrapper *promiseWrapper;
@property(nonatomic,copy,readwrite) NSArray<OBARegionV2*> *regions;
@property(nonatomic,strong) OBARegionStorage *regionStorage;
@property(nonatomic,strong) NSLock *refreshLock;
@end

@implementation OBARegionHelper

- (instancetype)initWithLocationManager:(OBALocationManager*)locationManager modelService:(OBARegionsService*)modelService {
    self = [super init];

    if (self) {
        _refreshLock = [[NSLock alloc] init];
        _locationManager = locationManager;
        _modelService = modelService;
        _regionStorage = [[OBARegionStorage alloc] init];
        _regions = [_regionStorage regions];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationManagerDidUpdateLocation:) name:OBALocationDidUpdateNotification object:self.locationManager];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationManagerDidFailWithError:) name:OBALocationManagerDidFailWithErrorNotification object:self.locationManager];
    }
    return self;
}

- (nullable AnyPromise*)refreshData {
    if (![self.refreshLock tryLock]) {
        return nil;
    }

    self.promiseWrapper = [self.modelService requestRegions];

    return self.promiseWrapper.anyPromise.then(^(NetworkResponse* response) {
        self.regionStorage.regions = response.object;
        self.regions = [OBARegionHelper filterAcceptableRegions:response.object];

        if (self.modelDAO.automaticallySelectRegion && self.locationManager.locationServicesEnabled) {
            [self setNearestRegion];
        }
        else {
            [self refreshCurrentRegionData];
        }
        [self.delegate regionHelperDidRefreshRegions:self];
    }).catch(^(NSError *error) {
        DDLogError(@"Error occurred while updating regions: %@", error);
    }).always(^{
        [self.refreshLock unlock];
    }).then(^{
        return @([CLLocationManager authorizationStatus]);
    });
}

- (void)setNearestRegion {
    NSArray<OBARegionV2*> *candidateRegions = self.regionsWithin100Miles;

    // If the location manager is being lame and is refusing to
    // give us a location, then we need to proactively bail on the
    // process of picking a new region. Otherwise, Objective-C's
    // non-clever treatment of nil will result in us unexpectedly
    // selecting Tampa. This happens because Tampa is the closest
    // region to lat long point (0,0).
    if (candidateRegions.count == 0) {
        self.modelDAO.automaticallySelectRegion = NO;
        [self.delegate regionHelperShowRegionListController:self];
        return;
    }

    self.modelDAO.currentRegion = candidateRegions[0];
    self.modelDAO.automaticallySelectRegion = YES;
}

- (BOOL)selectRegionWithIdentifier:(NSInteger)identifier {
    OBARegionV2 *region = nil;

    for (OBARegionV2 *r in self.regions) {
        if (r.identifier == identifier) {
            region = r;
            break;
        }
    }

    if (region) {
        self.modelDAO.automaticallySelectRegion = NO;
        self.modelDAO.currentRegion = region;
        return YES;
    }

    return NO;
}

- (void)refreshCurrentRegionData {
    OBARegionV2 *currentRegion = self.modelDAO.currentRegion;

    if (!currentRegion) {
        [self.delegate regionHelperShowRegionListController:self];
        return;
    }

    for (OBARegionV2 *region in self.regions) {
        if (currentRegion.identifier == region.identifier) {
            self.modelDAO.currentRegion = region;
            break;
        }
    }
}

#pragma mark - Public Properties

- (NSArray<OBARegionV2*>*)regionsWithin100Miles {
    if (self.regions.count == 0) {
        return @[];
    }

    CLLocation *currentLocation = self.locationManager.currentLocation;

    if (!currentLocation) {
        return @[];
    }

    return [[self.regions sortedArrayUsingComparator:^NSComparisonResult(OBARegionV2 *r1, OBARegionV2 *r2) {
        CLLocationDistance distance1 = [r1 distanceFromLocation:currentLocation];
        CLLocationDistance distance2 = [r2 distanceFromLocation:currentLocation];

        if (distance1 > distance2) {
            return NSOrderedDescending;
        }
        else if (distance1 < distance2) {
            return NSOrderedAscending;
        }
        else {
            return NSOrderedSame;
        }
    }] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(OBARegionV2 *r, NSDictionary<NSString *,id> *bindings) {
        return ([r distanceFromLocation:currentLocation] < 160934); // == 100 miles
    }]];
}

#pragma mark - Lazy Loaders

- (OBAModelDAO*)modelDAO {
    if (!_modelDAO) {
        _modelDAO = [OBAApplication sharedApplication].modelDao;
    }
    return _modelDAO;
}

#pragma mark - OBALocationManager Notifications

- (void)locationManagerDidUpdateLocation:(NSNotification*)note {
    if (self.modelDAO.automaticallySelectRegion) {
        [self setNearestRegion];
    }
}

- (void)locationManagerDidFailWithError:(NSNotification*)note {
    if (!self.modelDAO.currentRegion) {
        self.modelDAO.automaticallySelectRegion = NO;
        [self.delegate regionHelperShowRegionListController:self];
    }
}

#pragma mark - Data Munging

+ (NSArray<OBARegionV2*>*)filterAcceptableRegions:(NSArray<OBARegionV2*>*)regions {
    return [regions filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(OBARegionV2 *region, NSDictionary<NSString *,id> * _Nullable bindings) {
        if (!region.active) {
            return NO;
        }

        if (!region.supportsObaRealtimeApis) {
            return NO;
        }

        return YES;
    }]];
}

@end
