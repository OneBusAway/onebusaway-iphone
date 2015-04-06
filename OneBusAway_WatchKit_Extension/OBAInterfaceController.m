//
//  OBAInterfaceController.m
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/14/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAInterfaceController.h"

#import "OBAStopWK.h"
#import "OBAStopBookmarkWK.h"
#import "OBAArrivalAndDepartureWK.h"
#import "OBARouteWK.h"

#import "OBAStopRowController.h"

#define kStopRouteDetailRowType @"Route Detail Row"

@interface OBAInterfaceController ()

@property (nonatomic) NSInteger currentNumberOfRows;

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, weak) NSTimer *timer;

@end

@implementation OBAInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Setup defaults
    self.session = [NSURLSession sharedSession];
    self.arrivalsAndDepartures = [NSMutableArray new];
    self.stops = [NSMutableDictionary new];
    self.maxCount = NSIntegerMax;
    self.minutesBefore = 5;
    self.minutesAfter = 60;
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    [self refreshArrivalsAndDepartures];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(refreshArrivalsAndDepartures) userInfo:nil repeats:NO];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
    
    [self.timer invalidate];
    self.timer = nil;
}

- (void)fetchRequest:(NSString*)urlString completion:(void(^)(id json))completion {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request
                               completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       id json = nil;
                                       if (error) {
                                           [weakSelf.messageLabel setText:[error localizedDescription]];
                                       }
                                       else {
                                           NSError *jsonError;
                                           json = [NSJSONSerialization JSONObjectWithData:data
                                                                                  options:0
                                                                                    error:&jsonError];
                                           if (jsonError) {
                                               NSString *message = NSLocalizedString(@"Could not connect to server.", @"Could not connect to server.");
                                               [weakSelf.messageLabel setText:message];
                                           }
                                       }
                                       completion(json);
                                   });
                               }];
    [dataTask resume];
}

- (void)fetchStopInfoForBookmark:(OBAStopBookmarkWK *)bookmark completion:(void(^)(void))completion
{
    __weak typeof(self) weakSelf = self;
    [self fetchRequest:bookmark.stopInfoURLString completion:^(id json){
        [weakSelf updateStopInfoWithJSON:json bookmark:bookmark];
        if (completion) {
            completion();
        }
    }];
}

- (void)updateStopInfoWithJSON:(NSDictionary *)json bookmark:(OBAStopBookmarkWK *)bookmark
{
    NSDictionary *stopDictionary = [json valueForKeyPath:@"data.entry"];
    if (stopDictionary) {
        
        // create the stop
        OBAStopWK *stop = [[OBAStopWK alloc] initWithDictionary:stopDictionary];
        
        // create the stop detail string
        NSMutableArray *routeNames = [NSMutableArray new];
        NSArray *routes = [json valueForKeyPath:@"data.references.routes"];
        for (NSDictionary *routeDictionary in routes) {
            OBARouteWK *route = [[OBARouteWK alloc] initWithDictionary:routeDictionary];
            if (![bookmark.routeFilter containsObject:route.routeId]) {
                [routeNames addObject:route.name];
            }
        }
        [routeNames sortUsingComparator:^(id a, id b) {
            return [a compare:b options:NSNumericSearch];
        }];
        NSString *stopDetail = [routeNames componentsJoinedByString:@", "];
        if (stop.direction) {
            stopDetail = [NSString stringWithFormat:@"%@ - %@", stop.direction, stopDetail];
        }
        stop.detail = stopDetail;
        
        // update the stop info
        self.stops[stop.stopId] = stop;
    }
}

- (void)refreshArrivalsAndDepartures {
    
    // filter the arrivals and departures to only include items in the current list of bookmarks
    NSArray *stopIds = [self.bookmarks valueForKey:@"stopId"];
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"stopId IN %@", stopIds];
    [self.arrivalsAndDepartures filterUsingPredicate:filter];
    [self updateArrivalsAndDeparturesTable:YES];
    
    // fetch updated arrivals and departures
    __weak typeof(self) weakSelf = self;
    for (OBAStopBookmarkWK *bookmark in self.bookmarks) {
        [self fetchArrivalsAndDeparturesForBookmark:bookmark completion:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                // update the arrivals table
                [weakSelf updateArrivalsAndDeparturesTable:NO];
            });
        }];
    }
}

- (void)fetchArrivalsAndDeparturesForBookmark:(OBAStopBookmarkWK *)bookmark completion:(void(^)(void))completion {
    NSString *urlString = [NSString stringWithFormat:@"%@&minutesBefore=%@&minutesAfter=%@",
                           bookmark.arrivalsAndDeparturesURLString, @(self.minutesBefore), @(self.minutesAfter)];
    
    __weak typeof(self) weakSelf = self;
    [self fetchRequest:urlString completion:^(id json){
        if (json) {
            [weakSelf updateArrivalsAndDeparturesWithJSON:json bookmark:bookmark];
        }
        if (completion) {
            completion();
        }
    }];
}

- (void)updateArrivalsAndDeparturesWithJSON:(NSDictionary *)json bookmark:(OBAStopBookmarkWK *)bookmark {
    
    // Load table
    NSArray *nextArrivalsAndDepartures = [json valueForKeyPath:@"data.entry.arrivalsAndDepartures"];

    // For each arrival returned, update or add
    for (NSDictionary *ad in nextArrivalsAndDepartures) {
        OBAArrivalAndDepartureWK *arrival = [[OBAArrivalAndDepartureWK alloc] initWithDictionary:ad];
        if (![bookmark.routeFilter containsObject:arrival.routeId]) {
            NSUInteger idx = [self.arrivalsAndDepartures indexOfObject:arrival];
            if (idx == NSNotFound) {
                [self.arrivalsAndDepartures addObject:arrival];
            }
            else {
                [self.arrivalsAndDepartures replaceObjectAtIndex:idx withObject:arrival];
            }
        }
    }
    
    // Sort the updated times
    [self.arrivalsAndDepartures sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"bestTime" ascending:YES]]];
}

- (void)updateArrivalsAndDeparturesTable:(BOOL)isLoading {
    
    // remove any old rows.
    NSTimeInterval pastTime = ([[NSDate date] timeIntervalSince1970] - self.minutesBefore*60);
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"(bestTime >= %@)", @(pastTime)];
    [self.arrivalsAndDepartures filterUsingPredicate:filter];
    
    // Add, remove or set the current number of rows
    NSInteger count = self.maxCount < self.arrivalsAndDepartures.count ? self.maxCount : self.arrivalsAndDepartures.count;
    if ((self.currentNumberOfRows == 0) && (count > 0)) {
        [self.arrivalsAndDeparturesTable setNumberOfRows:count withRowType:kStopRouteDetailRowType];
    }
    else if (self.currentNumberOfRows > count) {
        NSRange range = NSMakeRange(count, self.currentNumberOfRows - count);
        [self.arrivalsAndDeparturesTable removeRowsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];
    }
    else if (self.currentNumberOfRows < count) {
        NSRange range = NSMakeRange(self.currentNumberOfRows, count - self.currentNumberOfRows);
        [self.arrivalsAndDeparturesTable insertRowsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range] withRowType:kStopRouteDetailRowType];
    }
    
    // Update the table
    self.currentNumberOfRows = count;
    if (count > 0) {
        [self.messageLabel setText:@""];
        for (NSUInteger idx = 0; idx < self.currentNumberOfRows; idx++) {
            OBAArrivalAndDepartureWK *item = [self.arrivalsAndDepartures objectAtIndex:idx];
            OBAStopRowController *rowController = [self.arrivalsAndDeparturesTable rowControllerAtIndex:idx];
            [rowController.routeLabel
            setText:item.routeShortName];
            NSDate *time = [item time];
            [rowController.routeTimeLabel
            setText:[NSDateFormatter localizedStringFromDate:time
                                                dateStyle:NSDateFormatterNoStyle
                                                timeStyle:NSDateFormatterShortStyle]];
            
            if ([time compare:[NSDate date]] > 0) {
                [rowController.routeTimeLabel setTextColor:[UIColor whiteColor]];
                [rowController.routeMinutesTimer setHidden:NO];
                [rowController.routeMinutesTimer setDate:time];
                [rowController.routeMinutesTimer start];
            }
            else {
                [rowController.routeTimeLabel setTextColor:[UIColor redColor]];
                [rowController.routeMinutesTimer setHidden:YES];
            }
        }
    }
    else if (isLoading) {
        [self.messageLabel setText:NSLocalizedString(@"Loading...", @"Loading...")];
    }
    else {
        NSString *localizedFormat = NSLocalizedString(@"No arrivals in the next %@ minutes", @"[arrivals count] == 0");
        NSString *message = [NSString stringWithFormat:localizedFormat, @(self.minutesAfter)];
        [self.messageLabel setText:message];
    }
}

@end
