//
//  OBADeepLinkNavigationTarget.h
//  OBAKit
//
//  Created by Aaron Brethorst on 2/21/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAKit.h>

@class OBATripDeepLink;

NS_ASSUME_NONNULL_BEGIN

@interface OBADeepLinkNavigationTarget : OBANavigationTarget
@property(nonatomic,copy,nullable) OBATripDeepLink *tripDeepLink;

+ (instancetype)targetWithTripDeepLink:(OBATripDeepLink*)tripDeepLink;
@end

NS_ASSUME_NONNULL_END
