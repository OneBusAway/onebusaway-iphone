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

@interface OBATestHarnessPersistenceLayer ()
@property(nonatomic,strong) NSArray *bookmarks;
@property(nonatomic,strong) CLLocation *mostRecentLocation;
@property(nonatomic,assign) BOOL automaticallySetRegion;
@end

@implementation OBATestHarnessPersistenceLayer
@synthesize hideFutureLocationWarnings;

- (instancetype)init {
    self = [super init];

    if (self) {
        self.bookmarks = @[];
        self.automaticallySetRegion = YES; // per the NSUD-default setting that happens in OBAApplicationDelegate.m
    }
    return self;
}

- (NSArray*)readBookmarks {
    return self.bookmarks;
}

- (void)writeBookmarks:(NSArray*)source {
    self.bookmarks = source;
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
    return self.mostRecentLocation;
}

- (void)writeMostRecentLocation:(CLLocation*)mostRecentLocation {
    self.mostRecentLocation = mostRecentLocation;
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
    return self.automaticallySetRegion;
}

- (void)writeSetRegionAutomatically:(BOOL)setRegionAutomatically {
    self.automaticallySetRegion = setRegionAutomatically;
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
