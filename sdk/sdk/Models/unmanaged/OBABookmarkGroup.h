//
//  OBABookmarkGroup.h
//  org.onebusaway.iphone
//
//  Created by Aengus McMillin on 12/19/13.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OBABookmarkV2;

@interface OBABookmarkGroup : NSObject<NSCoding>
@property (nonatomic, strong) NSMutableArray *bookmarks;
@property (nonatomic, strong) NSString *name;

- (instancetype)initWithName:(NSString*)name;

@end
