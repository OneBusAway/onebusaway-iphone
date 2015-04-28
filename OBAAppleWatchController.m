//
//  OBAAppleWatchController.m
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/6/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAAppleWatchController.h"
#import "OBAApplicationDelegate.h"

#import "OBAModelDAO.h"
#import "OBABookmarkGroup.h"
#import "OBABookmarkV2.h"
#import "OBAStopAccessEventV2.h"
#import "OBARouteV2.h"

#import "OBAStopGroupWK.h"
#import "OBAStopBookmarkWK.h"

@implementation OBAAppleWatchController

+ (instancetype)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (void)handleWatchKitExtensionRequestForAppDelegate:(OBAApplicationDelegate *)appDelegate
                                            userInfo:(NSDictionary *)userInfo
                                               reply:(void (^)(NSDictionary *replyInfo))reply {
    NSString *requestId = userInfo[@"requestId"];

    if ([requestId isEqualToString:OBARequestIdRecentAndBookmarkStopGroups]) {
        [self requestRecentAndBookmarkStopGroupsForAppDelegate:appDelegate reply:reply];
    }
    else {
        reply(@{ @"status": @"notImplemented"});
    }
}

- (void)requestRecentAndBookmarkStopGroupsForAppDelegate:(OBAApplicationDelegate *)appDelegate reply:(void (^)(NSDictionary *replyInfo))reply {

    NSMutableArray *stopGroups = [NSMutableArray new];
    
    OBAStopGroupWK *mostRecentStopGroup = [self mostRecentStopGroupForAppDelegate:appDelegate];
    [stopGroups addObject:[mostRecentStopGroup dictionaryRepresentation]];

    // Add bookmarks
    NSArray *bookmarkGroups = [self bookmarkGroupsForAppDelegate:appDelegate];
    for (OBAStopGroupWK *stopGroup in bookmarkGroups) {
        [stopGroups addObject:[stopGroup dictionaryRepresentation]];
    }
    
    // wait for all requests to complete then send reply
    NSDictionary *userInfo = @{ @"stopGroups": [stopGroups copy],
                                @"mostRecentStopId": [[mostRecentStopGroup.bookmarks firstObject] stopId] ? : @""};
    reply(userInfo);
}

- (OBAStopGroupWK *)mostRecentStopGroupForAppDelegate:(OBAApplicationDelegate *)appDelegate {
    OBAStopGroupWK *stopGroup = nil;
    OBAStopAccessEventV2 *event = [appDelegate.modelDao.mostRecentStops firstObject];

    if (event) {
        stopGroup = [[OBAStopGroupWK alloc] init];
        stopGroup.groupType = OBAStopGroupTypeRecent;
        stopGroup.name = NSLocalizedString(@"Most Recent Stop", @"Most Recent Stop");

        NSString *stopId = [event.stopIds firstObject];
        OBAStopBookmarkWK *bookmark = [self bookmarkForStopId:stopId longName:event.title usingAppDelegate:appDelegate];
        stopGroup.bookmarks = @[bookmark];
    }

    return stopGroup;
}

- (NSArray *)bookmarkGroupsForAppDelegate:(OBAApplicationDelegate *)appDelegate {
    NSMutableArray *stopGroups = [NSMutableArray new];
    NSArray *bookmarkGroups = appDelegate.modelDao.bookmarkGroups;

    if (appDelegate.modelDao.bookmarks.count > 0) {
        OBABookmarkGroup *group = [[OBABookmarkGroup alloc] initWithName:NSLocalizedString(@"Bookmarks", @"Bookmarks")];
        [group.bookmarks addObjectsFromArray:appDelegate.modelDao.bookmarks];
        bookmarkGroups = [bookmarkGroups arrayByAddingObject:group];
    }

    for (OBABookmarkGroup *group in bookmarkGroups) {
        // create a stop group for this bookmark group
        OBAStopGroupWK *stopGroup = [[OBAStopGroupWK alloc] init];
        stopGroup.groupType = OBAStopGroupTypeBookmark;
        stopGroup.name = group.name;
        
        NSMutableArray *bookmarks = [NSMutableArray new];
        for (OBABookmarkV2 *bookmark in group.bookmarks) {
            NSString *stopId = [bookmark.stopIds firstObject];
            OBAStopBookmarkWK *stopBookmark = [self bookmarkForStopId:stopId longName:bookmark.name usingAppDelegate:appDelegate];
            [bookmarks addObject:stopBookmark];
        }
        stopGroup.bookmarks = [bookmarks copy];
        
        [stopGroups addObject:stopGroup];
    }

    return stopGroups;
}

- (OBAStopBookmarkWK *)bookmarkForStopId:(NSString*)stopId longName:(NSString*)longName usingAppDelegate:(OBAApplicationDelegate *)appDelegate {
    OBAStopBookmarkWK *bookmark = [[OBAStopBookmarkWK alloc] init];
    bookmark.name = [OBAAppleWatchController shortenStopName:longName];
    bookmark.stopId = stopId;
    
    OBAStopPreferencesV2 *prefs = [appDelegate.modelDao stopPreferencesForStopWithId:stopId];
    bookmark.routeFilter = [prefs.routeFilter allObjects];
    
    bookmark.stopInfoURLString = [[appDelegate.modelService urlForStopInfoForId:stopId] absoluteString];
    bookmark.arrivalsAndDeparturesURLString = [[appDelegate.modelService urlForStopWithArrivalsAndDeparturesForId:stopId] absoluteString];
    
    return bookmark;
}

+ (NSString *)shortenStopName:(NSString *)name {
    // shorten the default name used by the service by removing Ave, St, etc.
    NSArray *streetNames = @[@"St", @"Ave", @"Way", @"Rd", @"Ln", @"Ct", @"Dr", @"Aly"];
    NSMutableString *stopName = [name mutableCopy];

    for (NSString *streetName in streetNames) {
        [stopName replaceOccurrencesOfString:[NSString stringWithFormat:@" %@ ", streetName]
                                  withString:@" "
                                     options:NSCaseInsensitiveSearch
                                       range:NSMakeRange(0, stopName.length)];
        NSInteger endLength = streetName.length + 1;
        [stopName replaceOccurrencesOfString:[NSString stringWithFormat:@" %@", streetName]
                                  withString:@""
                                     options:NSCaseInsensitiveSearch
                                       range:NSMakeRange(stopName.length - endLength, endLength)];
    }

    NSRange bracketRange = [stopName rangeOfString:@" [" options:NSBackwardsSearch];

    if (bracketRange.location != NSNotFound) {
        if (bracketRange.location > 3) {
            bracketRange.length = stopName.length - bracketRange.location;
            [stopName replaceCharactersInRange:bracketRange withString:@""];
        }
    }

    return stopName;
}

@end
