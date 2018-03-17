//
//  OBAStopSearchNavigationTarget.h
//  OBAKit
//
//  Created by Aaron Brethorst on 2/22/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBANavigationTarget.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAStopSearchNavigationTarget : OBANavigationTarget
@property(nonatomic,copy) NSString *stopSearchQuery;
+ (instancetype)targetWithStopSearchQuery:(NSString*)searchQuery;
@end

NS_ASSUME_NONNULL_END
