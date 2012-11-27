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

#if TARGET_IPHONE_SIMULATOR
static const BOOL kUseLocationTraceInSimulator = NO;
#endif

@interface OBALocationManager (Private)

-(void) handleNewLocation:(CLLocation*)location;

#if TARGET_IPHONE_SIMULATOR
-(void) handleSimulatedLocationTrace;
#endif    

@end



@implementation OBALocationManager

@synthesize currentLocation = _currentLocation;

- (id) initWithModelDao:(OBAModelDAO*)modelDao {
    if( self = [super init]) {
        _modelDao = modelDao;
        _disabled = NO;
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _delegates = [[NSMutableArray alloc] init];
        
        
#if TARGET_IPHONE_SIMULATOR
        _currentLocation = [[CLLocation alloc] initWithLatitude:  47.653435121376894 longitude: -122.3056411743164];
#endif
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

#if TARGET_IPHONE_SIMULATOR
    
    if ( kUseLocationTraceInSimulator ) {
        
        NSBundle *bundle = [NSBundle mainBundle];
        NSString * path = [bundle pathForResource:@"LocationTrace" ofType:@"plist"];
        _locationTrace = [NSArray arrayWithContentsOfFile:path];
        _locationTraceIndex = 0;
        [self handleSimulatedLocationTrace];
        return;
    }
    else {
         
        //newLocation = [[[CLLocation alloc] initWithLatitude:47.677553240051175 longitude: -122.31267894201659] autorelease]; // Roosevelt HS
        //newLocation = [[[CLLocation alloc] initWithLatitude:47.66869649992775  longitude:-122.377610206604] autorelease]; // Ballard
        newLocation = [[CLLocation alloc] initWithLatitude:  47.653435121376894 longitude: -122.3056411743164]; // UW CSE
        //newLocation = [[[CLLocation alloc] initWithLatitude:  47.60983759756863 longitude: -122.33782768249512] autorelease];        
    }
    
#endif
    
    [self handleNewLocation:newLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    if( [error code] == kCLErrorDenied ) {
        _disabled = YES;
        [self stopUpdatingLocation];
        for( id<OBALocationManagerDelegate> delegate in _delegates )
            [delegate locationManager:self didFailWithError:error];
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
        _currentLocation = [NSObject releaseOld:_currentLocation retainNew:location];
        
        for( id<OBALocationManagerDelegate> delegate in _delegates )
            [delegate locationManager:self didUpdateLocation:_currentLocation];
    }    
}


#if TARGET_IPHONE_SIMULATOR

-(void) handleSimulatedLocationTrace {
    if( ! _locationTrace )
        return;
    if( _locationTraceIndex >= [_locationTrace count] )
        return;
    
    NSDictionary * record = _locationTrace[_locationTraceIndex];
    
    NSNumber * lat = record[@"lat"];
    NSNumber * lon = record[@"lon"];
    NSNumber * accuracy = record[@"accuracy"];
    NSNumber * time = record[@"time"];
    
    CLLocationCoordinate2D point = { [lat doubleValue], [lon doubleValue] };
    CLLocation * newLocation = [[CLLocation alloc] initWithCoordinate:point
                                                             altitude:0
                                                   horizontalAccuracy:[accuracy doubleValue]
                                                     verticalAccuracy:0
                                                            timestamp:[NSDate date]];

    [self handleNewLocation:newLocation];

    _locationTraceIndex++;
    if( _locationTraceIndex < [_locationTrace count] ) { 
        NSDictionary * record2 = _locationTrace[_locationTraceIndex];
        NSNumber * time2 = record2[@"time"];
        NSTimeInterval interval = [time2 doubleValue] - [time doubleValue];
        interval = MAX(interval,0);
        [self performSelector:@selector(handleSimulatedLocationTrace) withObject:nil afterDelay:interval];
    }
}

#endif

@end



