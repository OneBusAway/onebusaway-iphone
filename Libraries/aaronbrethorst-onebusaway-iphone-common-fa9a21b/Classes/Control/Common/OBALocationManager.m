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

#import "OBALocationManager.h"
#import "OBALogger.h"

static const NSTimeInterval kSuccessiveLocationComparisonWindow = 3;



@interface OBALocationManager (Private)

-(void) handleNewLocation:(CLLocation*)location;



@end



@implementation OBALocationManager

@synthesize currentLocation = _currentLocation;

- (id) initWithModelDao:(OBAModelDAO*)modelDao {
    if( self = [super init]) {
        _modelDao = modelDao;
        _disabled = NO;
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.purpose = @"Your location will be used to show nearby stops and routes.";
        _delegates = [[NSMutableArray alloc] init];
        
    }
    return self;
}


- (BOOL) locationServicesEnabled {
    return _disabled ? NO : [CLLocationManager locationServicesEnabled];
}

- (void) addDelegate:(id<OBALocationManagerDelegate>)delegate {
    @synchronized(self) {
        [_delegates addObject:delegate];
    }
}

- (void) removeDelegate:(id<OBALocationManagerDelegate>)delegate {
    @synchronized(self) {
        [_delegates removeObject:delegate];
    }
}

-(void) startUpdatingLocation {
    if( [CLLocationManager locationServicesEnabled] ) {
        [_locationManager startUpdatingLocation];
    }
    else {
        if (! [_modelDao hideFutureLocationWarnings]) {
            [_locationManager startUpdatingLocation];
            [_modelDao setHideFutureLocationWarnings:YES];            
        }
    }
}

-(void) stopUpdatingLocation {
    [_locationManager stopUpdatingLocation];
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    _disabled = NO;
    [_modelDao setHideFutureLocationWarnings:NO];
    [self handleNewLocation:newLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    if( [error code] == kCLErrorDenied ) {
        _disabled = YES;
        [self stopUpdatingLocation];
        for (int i = 0; i < [_delegates count]; i++) {
            [(id<OBALocationManagerDelegate>)[_delegates objectAtIndex:i ] locationManager:self didFailWithError:error];
        }

    }
}

@end



@implementation OBALocationManager (Private)

-(void) handleNewLocation:(CLLocation*)location {
    
    //OBALogDebug(@"location: %@", [location description]);
    //long long t = [location.timestamp timeIntervalSince1970] * 1000;
    //NSLog(@"location=%lld,%f,%f,%f", t,location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy);
    
    @synchronized(self) {
        
        /**
         * We have this issue where we get a high-accuracy location reading immediately
         * followed by a low-accuracy location reading, such as if wifi-localization
         * completed before cell-tower-localization.  We want to ignore the low-accuracy
         * reading
         */
        if( _currentLocation ) {
            
            NSDate * currentTime = [_currentLocation timestamp];
            NSDate * newTime = [location timestamp];

            NSTimeInterval interval = [newTime timeIntervalSinceDate:currentTime];
            
            //OBALogDebug(@"location time diff: %f", interval);
            
            if ( interval < kSuccessiveLocationComparisonWindow &&
                [_currentLocation horizontalAccuracy] < [location horizontalAccuracy]) {
                OBALogDebug(@"pruning location reading with low accuracy");
                return;
            }
        }
        _currentLocation = location;
        
        for (int i = 0; i < [_delegates count]; i++) {
            [(id<OBALocationManagerDelegate>)[_delegates objectAtIndex:i ] locationManager:self didUpdateLocation:_currentLocation];
        }
    }    
}

@end



