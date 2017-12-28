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
#import <OBAKit/NSArray+OBAAdditions.h>
#import <OBAKit/OBARegionV2.h>

@interface OBABookmarkGroup ()
@property(nonatomic,strong) NSMutableArray<OBABookmarkV2*> *internalBookmarks;
@end

@implementation OBABookmarkGroup
@dynamic bookmarks;

- (instancetype)init {
    if ([self initWithBookmarkGroupType:OBABookmarkGroupTypeRegular]) {
        _name = OBALocalized(@"bookmark_group.default_title", @"Default title of a bookmark group. In English, this is 'Untitled'.");
    }
    return self;
}

- (instancetype)initWithBookmarkGroupType:(OBABookmarkGroupType)bookmarkGroupType {
    if (self = [super init]) {
        _bookmarkGroupType = bookmarkGroupType;
        _internalBookmarks = [NSMutableArray array];
        _open = YES;
        _UUID = [[NSUUID UUID] UUIDString];
        _sortOrder = 0;
    }
    return self;
}

- (id)initWithName:(NSString *)name {
    if ([self initWithBookmarkGroupType:OBABookmarkGroupTypeRegular]) {
        _name = [name copy];
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)coder {
    OBABookmarkGroupType groupType = [coder oba_decodeInteger:@selector(bookmarkGroupType)];

    if ([self initWithBookmarkGroupType:groupType]) {
        if ([coder oba_containsValue:@selector(name)]) {
            _name = [coder oba_decodeObject:@selector(name)];
        }

        _internalBookmarks = [NSMutableArray arrayWithArray:[coder oba_decodeObject:@selector(bookmarks)] ?: @[]];

        for (OBABookmarkV2 *bookmark in _internalBookmarks) {
            bookmark.group = self;
        }

        if ([coder oba_containsValue:@selector(open)]) {
            _open = [coder oba_decodeBool:@selector(open)];
        }

        if ([coder oba_containsValue:@selector(UUID)]) {
            _UUID = [coder oba_decodeObject:@selector(UUID)];
        }

        if ([coder oba_containsValue:@selector(sortOrder)]) {
            _sortOrder = [coder oba_decodeInteger:@selector(sortOrder)];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
    [coder oba_encodeObject:_name forSelector:@selector(name)];
    [coder oba_encodeObject:_internalBookmarks forSelector:@selector(bookmarks)];
    [coder oba_encodeBool:_open forSelector:@selector(open)];
    [coder oba_encodeObject:_UUID forSelector:@selector(UUID)];
    [coder oba_encodeInteger:_sortOrder forSelector:@selector(sortOrder)];
    [coder oba_encodeInteger:_bookmarkGroupType forSelector:@selector(bookmarkGroupType)];
}

#pragma mark -

- (NSString*)name {
    if (self.bookmarkGroupType == OBABookmarkGroupTypeTodayWidget) {
        return OBALocalized(@"bookmark_group.today_widget_title", @"Title of the Bookmark Group that contains the Today Screen widget's bookmarks.");
    }
    else {
        return _name;
    }
}

#pragma mark - Bookmarks

- (NSArray<OBABookmarkV2*>*)bookmarksInRegion:(OBARegionV2*)region {
    return [self.bookmarks filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"regionIdentifier == %d", region.identifier]];
}

- (NSArray*)bookmarks {
    return [NSArray arrayWithArray:self.internalBookmarks];
}

- (void)addBookmark:(OBABookmarkV2*)bookmark {
    [self.internalBookmarks addObject:bookmark];
}

- (void)removeBookmark:(OBABookmarkV2*)bookmark {
    [self.internalBookmarks removeObject:bookmark];
}

- (void)insertBookmark:(OBABookmarkV2*)bookmark atIndex:(NSUInteger)index {
    [self.internalBookmarks insertObject:bookmark atIndex:index];
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
