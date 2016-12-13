/**
 * Copyright (C) 2009-2016 bdferris <bdferris@onebusaway.org>, University of Washington
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <OBAKit/OBAVehicleMapAnnotation.h>
#import <OBAKit/OBADateHelpers.h>
#import <OBAKit/OBAMacros.h>

@implementation OBAVehicleMapAnnotation

- (id) initWithTripStatus:(OBATripStatusV2*)tripStatus {
    if( self = [super init] ) {
        _tripStatus = tripStatus;
    }
    return self;    
}

#pragma mark MKAnnotation

- (NSString*) title {
    if (_tripStatus.vehicleId) {
        return [NSString stringWithFormat:@"%@: %@", OBALocalized(@"msg_mayus_vehicle",@"title"), _tripStatus.vehicleId];
    }
    else {
        return OBALocalized(@"msg_mayus_vehicle",@"title");
    }
}

- (NSString*) subtitle {
    return [OBADateHelpers formatShortTimeNoDate:[NSDate dateWithTimeIntervalSince1970:_tripStatus.lastUpdateTime/1000.0]];
}

- (CLLocationCoordinate2D) coordinate {
    if (_showLastKnownLocation) {
        return _tripStatus.lastKnownLocation.coordinate;
    }
    else {
        return _tripStatus.location.coordinate;
    }
}

@end
