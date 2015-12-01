//
//  OBADateHelpers.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/11/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBADateHelpers : NSObject
+ (NSString*)formatShortTimeNoDate:(NSDate*)date;
@end

NS_ASSUME_NONNULL_END