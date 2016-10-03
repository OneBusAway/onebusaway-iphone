//
//  OBARouteFilter.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/23/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;
#import <OBAKit/OBAStopPreferencesV2.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBARouteFilter : NSObject
@property(nonatomic,strong) OBAStopPreferencesV2 *stopPreferences;
@property(nonatomic,assign) BOOL showFilteredRoutes;

- (instancetype)initWithStopPreferences:(OBAStopPreferencesV2*)stopPreferences;

- (BOOL)shouldShowRouteID:(NSString*)routeID;
- (BOOL)hasFilteredRoutes;
@end

NS_ASSUME_NONNULL_END
