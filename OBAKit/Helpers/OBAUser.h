//
//  OBAUser.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface OBAUser : NSObject
@property(nonatomic,copy,class,readonly) NSString *userIDFromDefaults;
@end

NS_ASSUME_NONNULL_END
