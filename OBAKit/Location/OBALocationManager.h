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

NS_ASSUME_NONNULL_BEGIN

@class OBALocationManager;

@protocol OBALocationManagerDelegate <NSObject>
- (void) locationManager:(OBALocationManager *)manager didUpdateLocation:(CLLocation *)location;
- (void) locationManager:(OBALocationManager *)manager didFailWithError:(NSError*)error;

@optional
- (void)locationManager:(OBALocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status;
@end


@interface OBALocationManager : NSObject <CLLocationManagerDelegate>
@property(nonatomic,copy,readonly) CLLocation * currentLocation;
@property(nonatomic,assign,readonly) BOOL locationServicesEnabled;

- (instancetype)initWithModelDAO:(OBAModelDAO*)modelDAO;

- (void)addDelegate:(id<OBALocationManagerDelegate>)delegate;
- (void)removeDelegate:(id<OBALocationManagerDelegate>)delegate;

- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

// iOS 8 Location Manager Support
- (BOOL)hasRequestedInUseAuthorization;
- (void)requestInUseAuthorization;

@end

NS_ASSUME_NONNULL_END
