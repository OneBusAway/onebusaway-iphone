//
//  OBATripDeepLink.m
//  OBAKit
//
//  Created by Aaron Brethorst on 10/30/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBATripDeepLink.h>
#import <OBAKit/OBAURLHelpers.h>
#import <OBAKit/NSObject+OBADescription.h>
#import <OBAKit/NSCoder+OBAAdditions.h>

NSString * const OBADeepLinkURL = @"https://www.onebusaway.co";

@implementation OBATripDeepLink

- (instancetype)init {
    return [self initWithArrivalAndDeparture:nil region:nil];
}

- (instancetype)initWithArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture region:(OBARegionV2*)region {
    self = [super init];

    if (self) {
        _createdAt = [NSDate date];

        _regionIdentifier = region.identifier;
        OBAArrivalAndDepartureInstanceRef *instance = arrivalAndDeparture.instance;
        OBATripInstanceRef *tripInstance = instance.tripInstance;

        _name = [arrivalAndDeparture.bestAvailableName copy]; // maybe add the date in too?
        _stopID = instance.stopId;
        _tripID = tripInstance.tripId;
        _serviceDate = tripInstance.serviceDate;
        _stopSequence = instance.stopSequence;
        _vehicleID = [tripInstance.vehicleId copy];
    }
    return self;
}

#pragma mark - NSCoding

#define kName @"name"
#define kRegion @"region"
#define kStopID @"stopID"
#define kTripID @"tripID"
#define kVehicleID @"vehicleID"
#define kServiceDate @"serviceDate"
#define kStopSequence @"stopSequence"
#define kCreatedAt @"createdAt"

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];

    if (self) {
        _name = [aDecoder oba_decodeObject:@selector(name)];
        _regionIdentifier = [aDecoder oba_decodeInteger:@selector(regionIdentifier)];
        _stopID = [aDecoder oba_decodeObject:@selector(stopID)];
        _tripID = [aDecoder oba_decodeObject:@selector(tripID)];
        _vehicleID = [aDecoder oba_decodeObject:@selector(vehicleID)];
        _serviceDate = [aDecoder oba_decodeInt64:@selector(serviceDate)];
        _stopSequence = [aDecoder oba_decodeInteger:@selector(stopSequence)];
        _createdAt = [aDecoder oba_decodeObject:@selector(createdAt)];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder oba_encodePropertyOnObject:self withSelector:@selector(name)];
    [aCoder oba_encodeInteger:self.regionIdentifier forSelector:@selector(regionIdentifier)];
    [aCoder oba_encodePropertyOnObject:self withSelector:@selector(stopID)];
    [aCoder oba_encodePropertyOnObject:self withSelector:@selector(tripID)];
    [aCoder oba_encodePropertyOnObject:self withSelector:@selector(vehicleID)];
    [aCoder encodeInt64:self.serviceDate forKey:kServiceDate];
    [aCoder encodeInteger:self.stopSequence forKey:kStopSequence];
    [aCoder encodeObject:self.createdAt forKey:kCreatedAt];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    OBATripDeepLink *link = [[self.class alloc] init];
    link->_name = [self->_name copyWithZone:zone];
    link->_regionIdentifier = self->_regionIdentifier;
    link->_stopID = [self->_stopID copyWithZone:zone];
    link->_tripID = [self->_tripID copyWithZone:zone];
    link->_vehicleID = [self->_vehicleID copyWithZone:zone];
    link->_serviceDate = self->_serviceDate;
    link->_stopSequence = self->_stopSequence;
    link->_createdAt = [self->_createdAt copyWithZone:zone];

    return link;
}

#pragma mark - Equality/Comparison

- (NSUInteger)hash {
    return [NSString stringWithFormat:@"%ld_%@_%@_%@_%lld_%ld", (long)self.regionIdentifier, self.stopID, self.tripID, self.vehicleID, self.serviceDate, (long)self.stopSequence].hash;
}

- (BOOL)isEqual:(OBATripDeepLink*)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:self.class]) {
        return NO;
    }

    return self.hash == object.hash;
}

- (NSComparisonResult)compare:(OBATripDeepLink*)link {
    // This will result in a list that is sorted newest-to-oldest.
    return [link.createdAt compare:self.createdAt];
}

#pragma mark - Public Methods

- (NSURL*)deepLinkURL {
    NSString *stopID = [OBAURLHelpers escapePathVariable:self.stopID];

    NSURLComponents *URLComponents = [NSURLComponents componentsWithString:OBADeepLinkURL];
    URLComponents.path = [NSString stringWithFormat:@"/regions/%@/stops/%@/trips", @(self.regionIdentifier), stopID];

    URLComponents.queryItems = @[
                                 [NSURLQueryItem queryItemWithName:@"trip_id" value:self.tripID],
                                 [NSURLQueryItem queryItemWithName:@"service_date" value:@(self.serviceDate).description],
                                 [NSURLQueryItem queryItemWithName:@"stop_sequence" value:@(self.stopSequence).description]
                                 ];

    return URLComponents.URL;
}

#pragma mark - Miscellaneous

- (NSString*)description {
    return [self oba_description:@[@"name", @"regionIdentifier", @"stopID", @"tripID", @"serviceDate", @"stopSequence", @"createdAt"]];
}

@end
