/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <OBAKit/OBALocationManager.h>
#import <OBAKit/OBALogging.h>

NSString* locationAuthorizationStatusToString(CLAuthorizationStatus status) {
    switch (status) {
        case kCLAuthorizationStatusNotDetermined: {
            return @"Not Determined";
        }
        case kCLAuthorizationStatusRestricted: {
            return @"Restricted";
        }
        case kCLAuthorizationStatusDenied: {
            return @"Denied";
        }
        case kCLAuthorizationStatusAuthorizedAlways: {
            return @"Always";
        }
        case kCLAuthorizationStatusAuthorizedWhenInUse: {
            return @"When in Use";
        }
        default: {
            return [NSString stringWithFormat:@"Unknown value: %@", @(status)];
        }
    }
}

static const NSTimeInterval kSuccessiveLocationComparisonWindow = 3;

NSString * const OBALocationDidUpdateNotification = @"OBALocationDidUpdateNotification";
NSString * const OBALocationAuthorizationStatusChangedNotification = @"OBALocationAuthorizationStatusChangedNotification";
NSString * const OBALocationAuthorizationStatusUserInfoKey = @"OBALocationAuthorizationStatusUserInfoKey";
NSString * const OBALocationManagerDidFailWithErrorNotification = @"OBALocationManagerDidFailWithErrorNotification";
NSString * const OBALocationErrorUserInfoKey = @"OBALocationErrorUserInfoKey";

NSString * const OBAHeadingDidUpdateNotification = @"OBAHeadingDidUpdateNotification";
NSString * const OBAHeadingUserInfoKey = @"OBAHeadingUserInfoKey";

@interface OBALocationManager ()
@property(nonatomic,strong) OBAModelDAO *modelDao;
@property(nonatomic,strong) CLLocationManager *locationManager;
@property(nonatomic,copy,readwrite) CLLocation *currentLocation;
@property(nonatomic,copy,readwrite) CLHeading *currentHeading;
@end

@implementation OBALocationManager

- (instancetype)initWithModelDAO:(OBAModelDAO*)modelDAO {
    if( self = [super init]) {
        _modelDao = modelDAO;
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)startUpdatingLocation {
    if ([CLLocationManager locationServicesEnabled]) {
        [self.locationManager startUpdatingLocation];
    }
    else {
        if (!self.modelDao.hideFutureLocationWarnings) {
            [self.locationManager startUpdatingLocation];
            self.modelDao.hideFutureLocationWarnings = YES;
        }
    }
}

- (void)stopUpdatingLocation {
    if ([CLLocationManager locationServicesEnabled]) {
        [self.locationManager stopUpdatingLocation];
    }
}

- (void)startUpdatingHeading {
    if ([CLLocationManager headingAvailable]) {
        [self.locationManager startUpdatingHeading];
    }
}

- (void)stopUpdatingHeading {
    if ([CLLocationManager headingAvailable]) {
        [self.locationManager stopUpdatingHeading];
    }
}

#pragma mark - Notifications

- (void)applicationDidEnterBackground:(NSNotification*)note {
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopUpdatingHeading];
}

#pragma mark - Location Manager Permissions

- (BOOL)hasRequestedInUseAuthorization {
    return [CLLocationManager authorizationStatus] != kCLAuthorizationStatusNotDetermined;
}

- (CLAuthorizationStatus)authorizationStatus {
    return [CLLocationManager authorizationStatus];
}

- (BOOL)locationServicesEnabled {
    return [CLLocationManager locationServicesEnabled] && self.authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse;
}

+ (BOOL)awaitingLocationAuthorization {
    return [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    self.modelDao.hideFutureLocationWarnings = NO;
    [self handleNewLocation:locations.lastObject];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    self.currentHeading = newHeading;
    [[NSNotificationCenter defaultCenter] postNotificationName:OBAHeadingDidUpdateNotification object:self userInfo:@{OBAHeadingUserInfoKey: [newHeading copy]}];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [[NSNotificationCenter defaultCenter] postNotificationName:OBALocationManagerDidFailWithErrorNotification object:self userInfo:@{OBALocationErrorUserInfoKey: error}];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {

    if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
        self.modelDao.automaticallySelectRegion = NO;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:OBALocationAuthorizationStatusChangedNotification object:self userInfo:@{OBALocationAuthorizationStatusUserInfoKey: @(status)}];
}

#pragma mark - Private

- (void)handleNewLocation:(CLLocation*)location {
    @synchronized(self) {
        /**
         * We have this issue where we get a high-accuracy location reading immediately
         * followed by a low-accuracy location reading, such as if wifi-localization
         * completed before cell-tower-localization.  We want to ignore the low-accuracy
         * reading
         */
        if (self.currentLocation) {
            NSDate * currentTime = [self.currentLocation timestamp];
            NSDate * newTime = [location timestamp];

            NSTimeInterval interval = [newTime timeIntervalSinceDate:currentTime];

            if (interval < kSuccessiveLocationComparisonWindow && self.currentLocation.horizontalAccuracy < location.horizontalAccuracy) {
                DDLogWarn(@"pruning location reading with low accuracy");
                return;
            }
        }
        self.currentLocation = location;

        [[NSNotificationCenter defaultCenter] postNotificationName:OBALocationDidUpdateNotification object:self userInfo:nil];
    }
}

@end
