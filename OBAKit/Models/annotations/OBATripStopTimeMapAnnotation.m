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

#import <OBAKit/OBATripStopTimeMapAnnotation.h>

@implementation OBATripStopTimeMapAnnotation

- (id) initWithTripDetails:(OBATripDetailsV2*)tripDetails stopTime:(OBATripStopTimeV2*)stopTime {
    if( self = [super init] ) {
        _tripDetails = tripDetails;
        _stopTime = stopTime;
    }
    return self;
}

#pragma mark MKAnnotation

- (NSString*) title {
    return _stopTime.stop.name;
}

- (NSString*) subtitle {
    
    long long serviceDate = 0;
    NSInteger scheduleDeviation = 0;
    
    OBATripStatusV2 * status = _tripDetails.status;
    if( status ) {
        serviceDate = status.serviceDate;
        scheduleDeviation = status.scheduleDeviation;
    }
    
    OBATripScheduleV2 * schedule = _tripDetails.schedule;
    
    if( schedule.frequency ) {
        OBATripStopTimeV2 * firstStopTime = (schedule.stopTimes)[0];
        NSInteger minutes = (_stopTime.arrivalTime - firstStopTime.departureTime) / 60;
        return [NSString stringWithFormat:@"%ld %@",(long)minutes,NSLocalizedString(@"mins",@"minutes")];                                      
    }
    
    NSInteger stopTime = _stopTime.arrivalTime;
    
    NSDate * date = [NSDate dateWithTimeIntervalSince1970:(serviceDate/1000 + stopTime + scheduleDeviation)];
    return [self.timeFormatter stringFromDate:date];
}

- (CLLocationCoordinate2D) coordinate {
    return _stopTime.stop.coordinate;
}

@end
