//
//  OBARefreshRow.h
//  OBAKit
//
//  Created by Aaron Brethorst on 2/14/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBABaseRow.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, OBARefreshRowState) {
    OBARefreshRowStateNormal,
    OBARefreshRowStateRefreshing,
};

@interface OBARefreshRow : OBABaseRow
@property(nonatomic,copy,readonly) NSDate *date;
@property(nonatomic,assign) OBARefreshRowState rowState;

- (instancetype)initWithDate:(nullable NSDate*)date action:(nullable OBARowAction)action;

@end

NS_ASSUME_NONNULL_END
