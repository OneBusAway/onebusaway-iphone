//
//  OBABookmarkGroup.h
//  org.onebusaway.iphone
//
//  Created by Aengus McMillin on 12/19/13.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

@import Foundation;
#import <OBAKit/OBABookmarkV2.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBABookmarkGroup : NSObject<NSCoding>

/**
 The set of bookmarks contained in this group.
 */
@property(nonatomic,strong) NSMutableArray<OBABookmarkV2*> *bookmarks;

/**
 The name of this group.
 */
@property(nonatomic,copy) NSString *name;

/**
 The unique identifier of this group.
 */
@property(nonatomic,copy) NSString *UUID;

/**
 Determines where this group should be placed in a sorted list.
 */
@property(nonatomic,assign) NSUInteger sortOrder;

/**
 Whether or not this group should be rendered as 'open'.
 Ideally, this wouldn't be contained at the model level,
 but it's an integral part of the presentation of this
 data, and should be shared both inter-device, and intra-
 device in experiences ranging from Apple Watch apps to
 Today screen extensions.
 */
@property(nonatomic,assign) BOOL open;

- (instancetype)initWithName:(NSString*)name;

@end

NS_ASSUME_NONNULL_END
