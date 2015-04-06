//
//  OBAStopGroup.m
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/5/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAStopGroupWK.h"
#import "OBAStopBookmarkWK.h"

NSString *const OBARequestIdRecentAndBookmarkStopGroups = @"recentAndBookmarkStopGroups";

@interface OBAStopGroupWK ()

@end

@implementation OBAStopGroupWK

- (NSArray *)dictionaryRepresentationKeys {
    return @[@"name", @"groupType", @"bookmarks"];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"bookmarks"]) {
        NSMutableArray *bookmarks = [NSMutableArray new];
        for (id obj in value) {
            id objToAdd = [obj isKindOfClass:[NSDictionary class]] ? [[OBAStopBookmarkWK alloc] initWithDictionary:obj] : obj;
            [bookmarks addObject:objToAdd];
        }
        value = [bookmarks copy];
    }
    [super setValue:value forKey:key];
}

- (id)valueForKey:(NSString *)key {
    if ([key isEqualToString:@"bookmarks"]) {
        NSMutableArray *bookmarks = [NSMutableArray new];
        for (OBAStopBookmarkWK *obj in self.bookmarks) {
            [bookmarks addObject:[obj dictionaryRepresentation]];
        }
        return [bookmarks copy];
    }
    else {
        return [super valueForKey:key];
    }
}

@end
