//
//  OBATestHarnessPersistenceLayer.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 4/3/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBATestHarnessPersistenceLayer.h"
#import <MapKit/MapKit.h>
#import "OBARegionV2.h"

@implementation OBATestHarnessPersistenceLayer

- (NSArray*)readBookmarks {
    return nil;
}

- (void)writeBookmarks:(NSArray*)source {
    //
}

- (NSArray*)readBookmarkGroups {
    return nil;
}

- (void)writeBookmarkGroups:(NSArray*)source {
    //
}

- (NSArray*)readMostRecentStops {
    return nil;
}

- (void)writeMostRecentStops:(NSArray*)source {
    //
}

- (NSDictionary*)readStopPreferences {
    return nil;
}

- (void)writeStopPreferences:(NSDictionary*)stopPreferences {
    //
}

- (CLLocation *)readMostRecentLocation {
    return nil;
}

- (void)writeMostRecentLocation:(CLLocation*)mostRecentLocation {
    //
}

- (BOOL)hideFutureLocationWarnings {
    return NO;
}

- (void)setHideFutureLocationWarnings:(BOOL)hideFutureLocationWarnings {
    //
}

- (NSSet*)readVisistedSituationIds {
    return nil;
}

- (void)writeVisistedSituationIds:(NSSet*)situationIds {
    //
}

- (OBARegionV2 *)readOBARegion {
    return nil;
}

- (void)writeOBARegion:(OBARegionV2*)region {
    //
}

- (BOOL)readSetRegionAutomatically {
    return NO;
}

- (void)writeSetRegionAutomatically:(BOOL)setRegionAutomatically {
    //
}

- (NSString*)readCustomApiUrl {
    return nil;
}

- (void)writeCustomApiUrl:(NSString*)customApiUrl {
    //
}

- (NSArray*)readMostRecentCustomApiUrls {
    return nil;
}

- (void)writeMostRecentCustomApiUrls:(NSArray*)customApiUrls {
    //
}

@end
