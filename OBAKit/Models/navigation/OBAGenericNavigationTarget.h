//
//  OBAGenericNavigationTarget.h
//  OBAKit
//
//  Created by Aaron Brethorst on 7/6/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

@import Foundation;
#import <OBAKit/OBANavigationTarget.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAGenericNavigationTarget : OBANavigationTarget
@property(nonatomic,copy,readonly) NSString *query;
- (instancetype)initWithQuery:(NSString*)query;
@end

NS_ASSUME_NONNULL_END
