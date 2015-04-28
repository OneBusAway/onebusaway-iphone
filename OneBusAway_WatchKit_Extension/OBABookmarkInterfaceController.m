//
//  OBABookmarkInterfaceController.m
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/4/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBABookmarkInterfaceController.h"

#import "OBABookmarkRowController.h"

#import "OBAStopGroupWK.h"
#import "OBAStopBookmarkWK.h"
#import "OBAStopWK.h"

@interface OBABookmarkInterfaceController ()

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *noBookmarksLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceTable *bookmarkTable;

@property (nonatomic) NSMutableArray *rowObjects;
@property (nonatomic) NSMutableDictionary *rowIndexStopMap;
@property (nonatomic) NSMutableDictionary *stopDetails;

@end


@implementation OBABookmarkInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    self.stopDetails = [NSMutableDictionary new];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    __weak typeof(self) weakSelf = self;
    [WKInterfaceController openParentApplication:@{ @"requestId": OBARequestIdRecentAndBookmarkStopGroups }
                                           reply:^(NSDictionary *userInfo, NSError *error) {
                                               [weakSelf loadTable:userInfo];
                                           }];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

#define headerRowType @"Bookmark Group Header Row"
#define detailRowType @"Bookmark Row"

- (void)loadTable:(NSDictionary *)userInfo {
    NSArray *stopGroups = userInfo[@"stopGroups"];

    if ([stopGroups count] > 0) {
        // Hide the "no bookmarks" label if there are stops
        [self.noBookmarksLabel setText:@""];
    }

    self.rowObjects = [NSMutableArray new];
    self.rowIndexStopMap = [NSMutableDictionary new];

    NSMutableDictionary *bookmarks = [NSMutableDictionary new];
    
    for (NSDictionary *stopGroupDict in stopGroups) {
        OBAStopGroupWK *stopGroup = [[OBAStopGroupWK alloc] initWithDictionary:stopGroupDict];
        NSDictionary *headerRow = @{ @"rowType": headerRowType,
                                     @"name": stopGroup.name };
        [self.rowObjects addObject:headerRow];
        
        for (OBAStopBookmarkWK *bookmark in stopGroup.bookmarks) {
            
            // store the row indexes
            NSNumber *rowIndex = @(self.rowObjects.count);
            NSArray *rowIndexMap = self.rowIndexStopMap[bookmark.stopId];
            if (rowIndexMap == nil) {
                self.rowIndexStopMap[bookmark.stopId] = @[rowIndex];
            }
            else {
                self.rowIndexStopMap[bookmark.stopId] = [rowIndexMap arrayByAddingObject:rowIndex];
            }
  
            // add the row object
            NSMutableDictionary *rowDictionary = [NSMutableDictionary dictionary];
            rowDictionary[@"rowType"] = detailRowType,
            rowDictionary[@"name"] = bookmark.name,
            rowDictionary[@"detail"] = @"",
            rowDictionary[@"bookmark"] = [bookmark dictionaryRepresentation];
            OBAStopWK *stop = self.stops[bookmark.stopId];
            if (stop) {
                rowDictionary[@"stop"] = [stop dictionaryRepresentation];
                rowDictionary[@"detail"] = stop.detail;
            }
            [self.rowObjects addObject:rowDictionary];
            
            bookmarks[bookmark.stopId] = bookmark;
        }
    }

    [self.bookmarkTable setRowTypes:[self.rowObjects valueForKey:@"rowType"]];
    [self.rowObjects
     enumerateObjectsUsingBlock:^(NSDictionary *rowInfo, NSUInteger idx, BOOL *stop) {
         OBABookmarkRowController *rowController = [self.bookmarkTable rowControllerAtIndex:idx];
         [rowController.titleLabel setText:rowInfo[@"name"]];
         [rowController.detailLabel setText:rowInfo[@"detail"]];
     }];
    
    __weak typeof(self) weakSelf = self;
    for (OBAStopBookmarkWK *bookmark in [bookmarks allValues]) {
        if (!self.stops[bookmark.stopId]) {
            [self fetchStopInfoForBookmark:bookmark completion:^{
                [weakSelf updateRowForBookmark:bookmark];
            }];
        }
        else {
            [self updateRowForBookmark:bookmark];
        }
    }
}

- (void)updateRowForBookmark:(OBAStopBookmarkWK *)bookmark {
    NSArray *rowIndexMap = self.rowIndexStopMap[bookmark.stopId];
    for (NSNumber *row in rowIndexMap) {
        NSInteger rowIndex = [row integerValue];
        NSMutableDictionary *rowObject = [self.rowObjects[rowIndex] mutableCopy];
        OBAStopWK *stop = self.stops[bookmark.stopId];
        rowObject[@"stop"] = [stop dictionaryRepresentation];
        rowObject[@"detail"] = stop.detail;
        [self.rowObjects replaceObjectAtIndex:rowIndex withObject:rowObject];
        OBABookmarkRowController *rowController = [self.bookmarkTable rowControllerAtIndex:rowIndex];
        [rowController.detailLabel setText:stop.detail];
    }
}

- (id)contextForSegueWithIdentifier:(NSString *)segueIdentifier
                            inTable:(WKInterfaceTable *)table
                           rowIndex:(NSInteger)rowIndex {
    return (self.rowObjects.count > rowIndex) ? self.rowObjects[rowIndex] : nil;
}

@end
