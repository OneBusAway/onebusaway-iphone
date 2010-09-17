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


#import "OBAModelDAO.h"


@class OBALocationManager;

@protocol OBALocationManagerDelegate <NSObject>
- (void) locationManager:(OBALocationManager *)manager didUpdateLocation:(CLLocation *)location;
- (void) locationManager:(OBALocationManager *)manager didFailWithError:(NSError*)error;
@end


@interface OBALocationManager : NSObject <CLLocationManagerDelegate> {

	OBAModelDAO * _modelDao;
	CLLocationManager * _locationManager;
	NSMutableArray * _delegates;
	
	CLLocation * _currentLocation;
	BOOL _disabled;
	
#if TARGET_IPHONE_SIMULATOR
	NSArray * _locationTrace;
	int _locationTraceIndex;
#endif	
}

- (id) initWithModelDao:(OBAModelDAO*)modelDao;

@property (nonatomic,retain) CLLocation * currentLocation;
@property (readonly, nonatomic) BOOL locationServicesEnabled;

- (void) addDelegate:(id<OBALocationManagerDelegate>)delegate;
- (void) removeDelegate:(id<OBALocationManagerDelegate>)delegate;

-(void) startUpdatingLocation;
-(void) stopUpdatingLocation;

@end
