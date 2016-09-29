//
//  OBATestHarnessPersistenceLayer.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 4/3/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBATestHarnessPersistenceLayer.h"
#import <MapKit/MapKit.h>
#import <OBAKit/OBAKit.h>

@interface OBATestHarnessPersistenceLayer ()
@property(nonatomic,strong) NSArray *bookmarks;
@property(nonatomic,strong) CLLocation *mostRecentLocation;
@property(nonatomic,assign) BOOL automaticallySetRegion;
@property(nonatomic,strong) NSArray *bookmarkGroups;
@property(nonatomic,strong) OBARegionV2 *currentRegion;
@end

@implementation OBATestHarnessPersistenceLayer
@synthesize hideFutureLocationWarnings;
@synthesize ungroupedBookmarksOpen;

- (instancetype)init {
    self = [super init];

    if (self) {
        self.bookmarks = @[];
        self.bookmarkGroups = @[];
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
    return self.bookmarkGroups;
}

- (void)writeBookmarkGroups:(NSArray*)source {
    self.bookmarkGroups = source;
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
    return self.currentRegion;
}

- (void)writeOBARegion:(OBARegionV2*)region {
    self.currentRegion = region;
}


- (BOOL)readSetRegionAutomatically {
    return self.automaticallySetRegion;
}

- (void)writeSetRegionAutomatically:(BOOL)setRegionAutomatically {
    self.automaticallySetRegion = setRegionAutomatically;
}

- (NSSet<OBARegionV2*>*)customRegions {
    return [NSSet set];
}

- (void)addCustomRegion:(OBARegionV2*)region {
    //
}

- (void)removeCustomRegion:(OBARegionV2*)region {
    //
}

@end
