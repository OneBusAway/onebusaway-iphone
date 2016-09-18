//
//  OBABookmarkGroup.m
//  org.onebusaway.iphone
//
//  Created by Aengus McMillin on 12/19/13.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

#import <OBAKit/OBABookmarkGroup.h>
#import <OBAKit/NSObject+OBADescription.h>
#import <OBAKit/OBAMacros.h>

static NSString * const kNameKey = @"name";
static NSString * const kBookmarksKey = @"bookmarks";
static NSString * const kOpenKey = @"open";
static NSString * const kUUIDKey = @"UUID";
static NSString * const kSortOrderKey = @"sortOrder";

@implementation OBABookmarkGroup

- (id)initWithName:(NSString *)name
{
    if (self = [super init]) {
        _name = [name copy];
        _bookmarks = [NSMutableArray array];
        _open = YES;
        _UUID = [[NSUUID UUID] UUIDString];
        _sortOrder = 0;
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
    if (self = [super init]) {
        _name = [coder decodeObjectForKey:kNameKey];
        _bookmarks = [coder decodeObjectForKey:kBookmarksKey];
        for (OBABookmarkV2 *bookmark in _bookmarks) {
            bookmark.group = self;
        }

        if ([coder containsValueForKey:kOpenKey]) {
            _open = [coder decodeBoolForKey:kOpenKey];
        }
        else {
            _open = YES;
        }

        if ([coder containsValueForKey:kUUIDKey]) {
            _UUID = [coder decodeObjectForKey:kUUIDKey];
        }
        else {
            _UUID = [[NSUUID UUID] UUIDString];
        }

        if ([coder containsValueForKey:kSortOrderKey]) {
            _sortOrder = [coder decodeIntegerForKey:kSortOrderKey];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:_name forKey:kNameKey];
    [coder encodeObject:_bookmarks forKey:kBookmarksKey];
    [coder encodeBool:_open forKey:kOpenKey];
    [coder encodeObject:_UUID forKey:kUUIDKey];
    [coder encodeInteger:_sortOrder forKey:kSortOrderKey];
}

#pragma mark - NSObject

- (NSComparisonResult)compare:(OBABookmarkGroup*)group {
    OBAGuardClass(group, [OBABookmarkGroup class]) else {
        return NSOrderedAscending; //shrug.
    }

    if (self.sortOrder > group.sortOrder) {
        return NSOrderedDescending;
    }
    else if (self.sortOrder < group.sortOrder) {
        return NSOrderedAscending;
    }
    else {
        return NSOrderedSame;
    }
}

- (NSString*)description {
    return [self oba_description:@[kNameKey, kBookmarksKey, kOpenKey, kUUIDKey, kSortOrderKey]];
}

@end
