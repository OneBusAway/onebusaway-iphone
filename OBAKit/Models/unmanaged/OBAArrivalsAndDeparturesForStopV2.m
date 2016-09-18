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

#import <OBAKit/OBAArrivalsAndDeparturesForStopV2.h>
#import <OBAKit/OBASituationV2.h>
#import <OBAKit/NSObject+OBADescription.h>

@interface OBAArrivalsAndDeparturesForStopV2 ()
@property(nonatomic,strong) NSMutableArray *arrivalsAndDeparturesM;
@property(nonatomic,strong) NSMutableArray *situationIds;
@end

@implementation OBAArrivalsAndDeparturesForStopV2

- (instancetype)initWithReferences:(OBAReferencesV2*)refs {
    self = [super initWithReferences:refs];
    if (self) {
        _arrivalsAndDeparturesM = [[NSMutableArray alloc] init];
        _situationIds = [[NSMutableArray alloc] init];
    }
    return self;
}

- (OBAStopV2*) stop {
    OBAReferencesV2 * refs = [self references];
    return [refs getStopForId:self.stopId];
}

#pragma mark - Public

- (void)addArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    [self.arrivalsAndDeparturesM addObject:arrivalAndDeparture];
}

- (NSArray<OBAArrivalAndDepartureV2*>*)arrivalsAndDepartures {
    return [NSArray arrayWithArray:self.arrivalsAndDeparturesM];
}

#pragma mark - OBAHasServiceAlerts

- (NSArray<OBASituationV2*>*)situations {
    NSMutableArray *rSituations = [NSMutableArray array];

    for (NSString * situationId in self.situationIds) {
        OBASituationV2 * situation = [self.references getSituationForId:situationId];
        if (situation) {
            [rSituations addObject:situation];
        }
    }
    
    return rSituations;
}

- (void) addSituationId:(NSString*)situationId {
    [_situationIds addObject:situationId];
}

#pragma mark - NSObject

- (NSString*)description {
    return [self oba_description:@[@"stopId", @"stop", @"arrivalsAndDepartures"]];
}

@end
