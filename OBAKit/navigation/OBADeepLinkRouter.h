//
//  OBADeepLinkRouter.h
//  OBAKit
//
//  Created by Aaron Brethorst on 10/28/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;
#import <OBAKit/OBARegionV2.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const OBADeepLinkStopRegexPattern;
extern NSString * const OBADeepLinkTripRegexPattern;

typedef void(^OBADeepLinkAction)(NSArray<NSString*> *matchGroupResults, NSURLComponents *URLComponents);

NS_SWIFT_NAME(DeepLinkRouter)
@interface OBADeepLinkRouter : NSObject

- (instancetype)initWithBaseURL:(NSURL*)baseURL NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)routePattern:(NSString*)pattern toAction:(OBADeepLinkAction)action;
- (BOOL)performActionForURL:(NSURL*)URL;

- (nullable NSURL*)deepLinkURLForStopID:(NSString*)stopID regionIdentifier:(NSInteger)regionIdentifier NS_SWIFT_NAME(deepLinkURL(stopID:regionID:));

@end

NS_ASSUME_NONNULL_END
