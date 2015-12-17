//
//  OBAURLHelpers.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/22/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAURLHelpers : NSObject
+ (NSURL*)normalizeURLPath:(NSString*)path relativeToBaseURL:(NSString*)baseURLString parameters:(NSDictionary*)params;
@end

NS_ASSUME_NONNULL_END