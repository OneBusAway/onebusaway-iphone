//
//  OBADeepLinkRouter.h
//  OBAKit
//
//  Created by Aaron Brethorst on 10/28/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

typedef void(^OBADeepLinkAction)(NSArray<NSString*> *matchGroupResults, NSURLComponents *URLComponents);

@interface OBADeepLinkRouter : NSObject

- (void)routePattern:(NSString*)pattern toAction:(OBADeepLinkAction)action;
- (BOOL)performActionForURL:(NSURL*)URL;

@end

NS_ASSUME_NONNULL_END
