//
//  OBAErrorMessages.h
//  OBAKit
//
//  Created by Aaron Brethorst on 11/5/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface OBAErrorMessages : NSObject

@property(nonatomic,copy,class,readonly) NSError *stopNotFoundError;
+ (NSError*)connectionError:(NSHTTPURLResponse*)response;
@property(nonatomic,copy,class,readonly) NSError *cannotRegisterAlarm;

@end

NS_ASSUME_NONNULL_END
