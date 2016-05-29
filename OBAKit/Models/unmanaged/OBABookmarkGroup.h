//
//  OBABookmarkGroup.h
//  org.onebusaway.iphone
//
//  Created by Aengus McMillin on 12/19/13.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OBABookmarkV2;

@interface OBABookmarkGroup : NSObject<NSCoding>
@property(nonatomic,strong) NSMutableArray *bookmarks;
@property(nonatomic,copy) NSString *name;

- (instancetype)initWithName:(NSString*)name;

@end

NS_ASSUME_NONNULL_END