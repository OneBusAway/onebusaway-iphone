//
//  OBABookmarkedRouteRow.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 7/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import UIKit;
#import <OBAKit/OBABookmarkV2.h>
#import <OBAKit/OBAArrivalAndDepartureV2.h>
#import <OBAKit/OBADepartureRow.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, OBABookmarkedRouteRowState) {
    OBABookmarkedRouteRowStateLoading = 0,
    OBABookmarkedRouteRowStateError,
    OBABookmarkedRouteRowStateComplete,
};

@interface OBABookmarkedRouteRow : OBADepartureRow
@property(nonatomic,copy) OBABookmarkV2 *bookmark;
@property(nonatomic,assign) OBABookmarkedRouteRowState state;
@property(nonatomic,copy,nullable) NSString *errorMessage;

- (instancetype)initWithBookmark:(OBABookmarkV2*)bookmark action:(nullable OBARowAction)action NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithAction:(nullable OBARowAction)action NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
