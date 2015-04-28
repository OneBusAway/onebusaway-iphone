//
//  OBAInterfaceController.h
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/14/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import <WatchKit/WatchKit.h>

@class OBAStopWK;
@class OBAStopBookmarkWK;

@interface OBAInterfaceController : WKInterfaceController

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *messageLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceTable *arrivalsAndDeparturesTable;

@property (nonatomic) NSMutableDictionary *stops;
@property (nonatomic) NSArray *bookmarks;
@property (nonatomic) NSMutableArray *arrivalsAndDepartures;

@property (nonatomic) NSUInteger minutesBefore;
@property (nonatomic) NSUInteger minutesAfter;
@property (nonatomic) NSInteger maxCount;

- (void)fetchStopInfoForBookmark:(OBAStopBookmarkWK *)bookmark completion:(void(^)(void))completion;


- (void)refreshArrivalsAndDepartures;
- (void)fetchArrivalsAndDeparturesForBookmark:(OBAStopBookmarkWK *)bookmark completion:(void(^)(void))completion;
- (void)updateArrivalsAndDeparturesTable:(BOOL)isLoading;

@end
