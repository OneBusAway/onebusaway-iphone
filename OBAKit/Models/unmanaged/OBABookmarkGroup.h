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

typedef NS_ENUM(NSUInteger, OBABookmarkGroupType) {
    OBABookmarkGroupTypeRegular = 0,
    OBABookmarkGroupTypeTodayWidget,
};

@interface OBABookmarkGroup : NSObject<NSCoding>

/**
 Used to distinguish between normal bookmark groups and the bookmark group
 used for the Today screen widget.
 */
@property(nonatomic,assign,readonly) OBABookmarkGroupType bookmarkGroupType;

/**
 The set of bookmarks contained in this group.
 */
@property(nonatomic,copy,readonly) NSArray<OBABookmarkV2*> *bookmarks;

- (void)addBookmark:(OBABookmarkV2*)bookmark;
- (void)removeBookmark:(OBABookmarkV2*)bookmark;
- (void)insertBookmark:(OBABookmarkV2*)bookmark atIndex:(NSUInteger)index;

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

- (instancetype)initWithBookmarkGroupType:(OBABookmarkGroupType)bookmarkGroupType NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithName:(NSString*)name;

@end

NS_ASSUME_NONNULL_END
