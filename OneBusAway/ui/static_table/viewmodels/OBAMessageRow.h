//
//  OBAMessageRow.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/22/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

@import UIKit;
#import "OBABaseRow.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAMessageRow : OBABaseRow
@property(nonatomic,copy) NSString *sender;
@property(nonatomic,copy) NSString *subject;
@property(nonatomic,copy) NSDate *date;
@property(nonatomic,assign) BOOL unread;
@property(nonatomic,assign) BOOL highPriority;
@end

NS_ASSUME_NONNULL_END
