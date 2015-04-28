//
//  OBAStopInterfaceController.m
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/4/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAStopInterfaceController.h"

#import "OBAStopWK.h"
#import "OBAStopBookmarkWK.h"
#import "OBAArrivalAndDepartureWK.h"

#import "OBAStopRowController.h"

@interface OBAStopInterfaceController ()

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *titleLabel;

@end


@implementation OBAStopInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // get the bookmark
    NSDictionary *json = context;
    OBAStopBookmarkWK *bookmark = [[OBAStopBookmarkWK alloc] initWithDictionary:json[@"bookmark"]];
    if (bookmark) {
        self.bookmarks = @[bookmark];
    }
    
    // get the stop if there is one set
    NSDictionary *stopDictionary = json[@"stop"];
    OBAStopWK *stop = stopDictionary ? [[OBAStopWK alloc] initWithDictionary:stopDictionary] : nil;
    if (stop == nil) {
        __weak typeof(self) weakSelf = self;
        [self fetchStopInfoForBookmark:bookmark completion:^{
            [weakSelf updateStopInfo];
        }];
    }
    else {
        self.stops[stop.stopId] = stop;
        [self updateStopInfo];
    }
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (void)updateStopInfo {
    
    // Set the stop as this stop
    NSString *stopId = [[self.bookmarks firstObject] stopId];
    OBAStopWK *stop = stopId ? self.stops[stopId] : nil;
    
    // set the title
    NSString *title = stop.name;
    
    if (stop.direction) {
        title = [NSString stringWithFormat:@"%@ - %@ %@", title, stop.direction, NSLocalizedString(@"Bound", @"Bound")];
    }
    
    [self.titleLabel setText:title];
}

@end
