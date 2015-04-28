//
//  OBAGlanceController.m
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/4/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAGlanceController.h"

#import "OBAStopGroupWK.h"
#import "OBAStopBookmarkWK.h"
#import "OBAStopWK.h"

@interface OBAGlanceController () <CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *titleLabel;

@property (nonatomic) NSArray *stopGroups;
@property (nonatomic) OBAStopGroupWK *currentStopGroup;

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) CLLocation *currentLocation;

@end


@implementation OBAGlanceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    // Initially, do not show any text for the title and message
    [self.titleLabel setText:@""];
    [self.messageLabel setText:@""];

    // Configure interface objects here.
    self.maxCount = 2;
    self.minutesBefore = 1;
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    // update location
    [self startUpdatingLocation];
    
    // Update bookmarks
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __weak typeof(self) weakSelf = self;
        [WKInterfaceController openParentApplication:@{ @"requestId": OBARequestIdRecentAndBookmarkStopGroups }
                                               reply:^(NSDictionary *userInfo, NSError *error) {
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                       [weakSelf loadRecentAndBookmarkStopGroups:userInfo];
                                                   });
                                               }];
    });
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];

    [self stopUpdatingLocation];
}

- (void)startUpdatingLocation {
    if ([CLLocationManager locationServicesEnabled]) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        [self.locationManager startUpdatingLocation];
    }
}

- (void)stopUpdatingLocation {
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
    self.locationManager = nil;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    self.currentLocation = [locations lastObject];
    [self findAndUpdateNearestStop];
}

- (void)loadRecentAndBookmarkStopGroups:(NSDictionary *)userInfo {

    // Build the stop groups
    NSArray *stopGroupDictionaries = userInfo[@"stopGroups"];
    NSMutableArray *stopGroups = [NSMutableArray new];
    NSMutableDictionary *bookmarks = [NSMutableDictionary new];
    for (NSDictionary *stopGroupDictionary in stopGroupDictionaries) {
        OBAStopGroupWK *stopGroup = [[OBAStopGroupWK alloc] initWithDictionary:stopGroupDictionary];
        [stopGroups addObject:stopGroup];
        for (OBAStopBookmarkWK *bookmark in stopGroup.bookmarks) {
            if (!self.stops[bookmark.stopId]) {
                bookmarks[bookmark.stopId] = bookmark;
            }
        }
    }
    self.stopGroups = [stopGroups copy];
    
    if (self.stopGroups.count == 0) {
        // If no stops then stop looking for current location and
        // just show the no info message
        [self stopUpdatingLocation];
        [self.messageLabel setText:NSLocalizedString(@"You have no recently viewed or bookmarked stops.",
                                                     @"You have no recently viewed or bookmarked stops.")];
    }
    else if ([CLLocationManager locationServicesEnabled]) {
        
        // If location services are enabled, then get the stop info
        // create a dispatch group so we return when all the operation have completed
        dispatch_group_t dataRequestGroup = dispatch_group_create();
        
        // load all the stops
        for (OBAStopBookmarkWK *bookmark in [bookmarks allValues]) {
            dispatch_group_enter(dataRequestGroup);
            [self fetchStopInfoForBookmark:bookmark completion:^{
                dispatch_group_leave(dataRequestGroup);
            }];
        }
        
        // wait for all reference completion blocks to finish and then call the completion block
        // on the main queue.
        __weak typeof(self) weakSelf = self;
        dispatch_group_notify(dataRequestGroup, dispatch_get_main_queue(), ^{
            [weakSelf findAndUpdateNearestStop];
        });
    }
    else {
        // Otherwise, kick of a request to get info for most recent
        [self findAndUpdateNearestStop];
    }
}

- (void)findAndUpdateNearestStop {
    
    OBAStopGroupWK *stopGroupWK = nil;

    if (self.currentLocation && (self.stops.count > 0)) {
        // Get the stop group with the stop nearest to the current location
        CLLocationDistance nearest = CLLocationDistanceMax;
        for (OBAStopGroupWK *stopGroup in self.stopGroups) {
            for (OBAStopBookmarkWK *bookmark in stopGroup.bookmarks) {
                OBAStopWK *stop = self.stops[bookmark.stopId];
                if (stop) {
                    CLLocationDistance dist = [self.currentLocation distanceFromLocation:stop.location];
                    if (dist < nearest) {
                        nearest = dist;
                        stopGroupWK = stopGroup;
                    }
                }
            }
        }
    }
    
    if (stopGroupWK == nil) {
        // If current location is not set or the stops haven't been populated yet,
        // then set to the most recent stop
        NSPredicate *filter = [NSPredicate predicateWithFormat:@"groupType = %@", @(OBAStopGroupTypeRecent)];
        stopGroupWK = [[self.stopGroups filteredArrayUsingPredicate:filter] firstObject];
    }

    if (stopGroupWK) {
        if (self.currentLocation) {
            [self.titleLabel setText:NSLocalizedString(@"Nearby", @"Nearby")];
        }
        else {
            [self.titleLabel setText:NSLocalizedString(@"Recent", @"Recent")];
        }
        
        self.bookmarks = [stopGroupWK.bookmarks copy];
        [self refreshArrivalsAndDepartures];
    }
}

@end
