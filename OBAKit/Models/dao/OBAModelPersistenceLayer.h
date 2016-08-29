//
//  OBAModelPersistenceLayer.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 4/3/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLLocation;
@class OBARegionV2;

NS_ASSUME_NONNULL_BEGIN

@protocol OBAModelPersistenceLayer <NSObject>
@property(nonatomic,assign) BOOL hideFutureLocationWarnings;
@property(nonatomic,assign) BOOL ungroupedBookmarksOpen;

- (NSArray*) readBookmarks;
- (void) writeBookmarks:(NSArray*)source;

- (NSArray*) readBookmarkGroups;
- (void) writeBookmarkGroups:(NSArray*)source;

- (NSArray*) readMostRecentStops;
- (void) writeMostRecentStops:(NSArray*)source;

- (NSDictionary*) readStopPreferences;
- (void) writeStopPreferences:(NSDictionary*)stopPreferences;

- (CLLocation * _Nullable) readMostRecentLocation;
- (void) writeMostRecentLocation:(CLLocation*)mostRecentLocation;

- (NSSet*) readVisistedSituationIds;
- (void) writeVisistedSituationIds:(NSSet*)situationIds;

- (OBARegionV2 * _Nullable) readOBARegion;
- (void)writeOBARegion:(OBARegionV2*)region;

- (BOOL) readSetRegionAutomatically;
- (void) writeSetRegionAutomatically:(BOOL)setRegionAutomatically;

- (NSSet<OBARegionV2*>*)customRegions;
- (void)addCustomRegion:(OBARegionV2*)region;
- (void)removeCustomRegion:(OBARegionV2*)region;
@end

NS_ASSUME_NONNULL_END