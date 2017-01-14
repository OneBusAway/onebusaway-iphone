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
#import <OBAKit/NSCoder+OBAAdditions.h>

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
        _name = [coder oba_decodeObject:@selector(name)];
        _bookmarks = [coder oba_decodeObject:@selector(bookmarks)];
        for (OBABookmarkV2 *bookmark in _bookmarks) {
            bookmark.group = self;
        }

        if ([coder oba_containsValue:@selector(open)]) {
            _open = [coder oba_decodeBool:@selector(open)];
        }
        else {
            _open = YES;
        }

        if ([coder oba_containsValue:@selector(UUID)]) {
            _UUID = [coder oba_decodeObject:@selector(UUID)];
        }
        else {
            _UUID = [[NSUUID UUID] UUIDString];
        }

        if ([coder oba_containsValue:@selector(sortOrder)]) {
            _sortOrder = [coder oba_decodeInteger:@selector(sortOrder)];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
    [coder oba_encodeObject:_name forSelector:@selector(name)];
    [coder oba_encodeObject:_bookmarks forSelector:@selector(bookmarks)];
    [coder oba_encodeBool:_open forSelector:@selector(open)];
    [coder oba_encodeObject:_UUID forSelector:@selector(UUID)];
    [coder oba_encodeInteger:_sortOrder forSelector:@selector(sortOrder)];
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
    return [self oba_description:@[@"name", @"bookmarks", @"open", @"UUID", @"sortOrder"]];
}

@end
