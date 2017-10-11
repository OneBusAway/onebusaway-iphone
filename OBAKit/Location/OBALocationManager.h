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


#import <OBAKit/OBAModelDAO.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

NSString* locationAuthorizationStatusToString(CLAuthorizationStatus status);

extern NSString * const OBALocationDidUpdateNotification;
extern NSString * const OBALocationAuthorizationStatusChangedNotification;
extern NSString * const OBALocationManagerDidFailWithErrorNotification;

extern NSString * const OBALocationAuthorizationStatusUserInfoKey;
extern NSString * const OBALocationErrorUserInfoKey;

extern NSString * const OBAHeadingDidUpdateNotification;
extern NSString * const OBAHeadingUserInfoKey;

@interface OBALocationManager : NSObject <CLLocationManagerDelegate>
@property(nonatomic,assign,readonly) BOOL hasRequestedInUseAuthorization;
@property(nonatomic,copy,nullable,readonly) CLLocation *currentLocation;
@property(nonatomic,copy,nullable,readonly) CLHeading *currentHeading;

/**
 Informs the caller whether or not location services are enabled for the app.

 Returns true if device-level location services are enabled and the user has
 authorized location services for the app.
 */
@property(nonatomic,assign,readonly) BOOL locationServicesEnabled;

@property(nonatomic,assign,class,readonly) BOOL awaitingLocationAuthorization;

@property(nonatomic,assign,readonly) CLAuthorizationStatus authorizationStatus;

- (instancetype)initWithModelDAO:(OBAModelDAO*)modelDAO;

- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

- (void)startUpdatingHeading;
- (void)stopUpdatingHeading;

@end

NS_ASSUME_NONNULL_END
