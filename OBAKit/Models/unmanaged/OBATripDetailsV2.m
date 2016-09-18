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

#import <OBAKit/OBATripDetailsV2.h>

@implementation OBATripDetailsV2

- (id) initWithReferences:(OBAReferencesV2*)refs {
    self = [super initWithReferences:refs];
    if( self ) {
        _situationIds = [[NSMutableArray alloc] init];
    }
    return self;
}

- (OBATripV2*) trip {
    OBAReferencesV2 * refs = self.references;
    return [refs getTripForId:self.tripId];
}

- (OBATripInstanceRef *) tripInstance {
    return [OBATripInstanceRef tripInstance:self.tripId serviceDate:self.serviceDate vehicleId:self.status.vehicleId];
}

- (NSArray*) situationIds {
    return _situationIds;
}

- (NSArray*) situations {
    
    NSMutableArray * rSituations = [NSMutableArray array];
    
    OBAReferencesV2 * refs = self.references;
    
    for( NSString * situationId in self.situationIds ) {
        OBASituationV2 * situation = [refs getSituationForId:situationId];
        if( situation )
            [rSituations addObject:situation];
    }
    
    return rSituations;
}

- (void) addSituationId:(NSString*)situationId {
    [_situationIds addObject:situationId];
}

- (BOOL)hasTripConnections {
    return self.schedule.previousTripId || self.schedule.nextTripId;
}

@end
