//
//  OBABookmarkGroup.m
//  org.onebusaway.iphone
//
//  Created by Aengus McMillin on 12/19/13.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

#import "OBABookmarkGroup.h"
#import "OBABookmarkV2.h"

@implementation OBABookmarkGroup

- (id)initWithName:(NSString *)name
{
    if (self = [super init]) {
        _name = name;
        _bookmarks = [NSMutableArray array];
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
    if (self = [super init]) {
        _name = [coder decodeObjectForKey:@"name"];
        _bookmarks = [coder decodeObjectForKey:@"bookmarks"];
        for (OBABookmarkV2 *bookmark in _bookmarks) {
            bookmark.group = self;
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:_name forKey:@"name"];
    [coder encodeObject:_bookmarks forKey:@"bookmarks"];
}

@end
