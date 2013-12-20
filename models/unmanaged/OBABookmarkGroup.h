//
//  OBABookmarkGroup.h
//  org.onebusaway.iphone
//
//  Created by Aengus McMillin on 12/19/13.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OBABookmarkV2;

@interface OBABookmarkGroup : NSObject

- (id) initWithName:(NSString*)name;
- (id) initWithCoder:(NSCoder*)coder;

@property (nonatomic, strong) NSMutableArray *bookmarks;
@property (nonatomic, strong) NSString *name;

@end
