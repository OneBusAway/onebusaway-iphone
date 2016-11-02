//
//  OBATripScheduleSectionBuilder.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 5/26/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBATripScheduleSectionBuilder.h"
#import "OBATableSection.h"
#import "OBATableRow.h"
#import "OBAStopViewController.h"
#import "OBATripDetailsViewController.h"

@implementation OBATripScheduleSectionBuilder

+ (OBATableSection*)buildStopsSection:(OBATripDetailsV2*)tripDetails tripInstance:(OBATripInstanceRef*)tripInstance currentStopIndex:(NSUInteger)currentStopIndex navigationController:(UINavigationController*)navigationController {
    OBATripScheduleV2 *schedule = tripDetails.schedule;
    OBATableSection *stopsSection = [[OBATableSection alloc] initWithTitle:nil];

    OBATableRow *previousRow = [self buildPreviousConnectionRowWithTripDetails:tripDetails tripInstance:tripInstance navigationController:navigationController];
    OBATableRow *continuingRow = [self buildNextConnectionRowWithTripDetails:tripDetails tripInstance:tripInstance navigationController:navigationController];

    if (previousRow) {
        [stopsSection addRow:previousRow];
    }

    for (NSUInteger i=0; i<schedule.stopTimes.count; i++) {
        OBATripStopTimeV2 *stopTime = schedule.stopTimes[i];
        OBAStopV2 *stop = stopTime.stop;

        OBATableRow *row = [[OBATableRow alloc] initWithTitle:stop.name action:^{
            OBAStopViewController *vc = [[OBAStopViewController alloc] initWithStopID:stopTime.stopId];
            [navigationController pushViewController:vc animated:YES];
        }];

        if (currentStopIndex > i) {
            row.titleColor = [OBATheme lightDisabledColor];
        }

        row.subtitle = [self formattedStopTime:stopTime tripDetails:tripDetails];
        row.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        row.style = UITableViewCellStyleValue1;

        [stopsSection addRow:row];
    }

    if (continuingRow) {
        [stopsSection addRow:continuingRow];
    }

    return stopsSection;
}

+ (NSString*)formattedStopTime:(OBATripStopTimeV2*)stopTime tripDetails:(OBATripDetailsV2*)tripDetails {
    if (tripDetails.schedule.frequency) {
        OBATripStopTimeV2 *firstStopTime = tripDetails.schedule.stopTimes[0];
        NSInteger minutes = (stopTime.arrivalTime - firstStopTime.departureTime) / 60;
        return [NSString stringWithFormat:@"%@ %@", @(minutes), NSLocalizedString(@"mins", @"minutes")];
    }
    else {
        NSDate *time = [OBADateHelpers getTripStopTimeAsDate:stopTime tripDetails:tripDetails];
        return [OBADateHelpers formatShortTimeNoDate:time];
    }
}

+ (nullable OBATableRow*)buildPreviousConnectionRowWithTripDetails:(OBATripDetailsV2*)tripDetails tripInstance:(OBATripInstanceRef*)tripInstance navigationController:(UINavigationController*)navigationController {

    if (!tripDetails.schedule.previousTrip) {
        return nil;
    }

    NSString *labelText = [NSString stringWithFormat:NSLocalizedString(@"Starts as %@", @""), [tripDetails.schedule.previousTrip asLabel]];
    OBATableRow *row = [[OBATableRow alloc] initWithTitle:labelText action:^{
        OBATripInstanceRef *prevTripInstance = [tripInstance copyWithNewTripId:tripDetails.schedule.previousTripId];
        OBATripDetailsViewController *vc = [[OBATripDetailsViewController alloc] initWithTripInstance:prevTripInstance];
        [navigationController pushViewController:vc animated:YES];
    }];
    row.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return row;
}

+ (nullable OBATableRow*)buildNextConnectionRowWithTripDetails:(OBATripDetailsV2*)tripDetails tripInstance:(OBATripInstanceRef*)tripInstance navigationController:(UINavigationController*)navigationController {

    if (!tripDetails.schedule.nextTrip) {
        return nil;
    }

    NSString *labelText = [NSString stringWithFormat:NSLocalizedString(@"Continues as %@", @""), [tripDetails.schedule.nextTrip asLabel]];
    OBATableRow *row = [[OBATableRow alloc] initWithTitle:labelText action:^{
        OBATripInstanceRef *nextTripInstance = [tripInstance copyWithNewTripId:tripDetails.schedule.nextTripId];
        OBATripDetailsViewController *vc = [[OBATripDetailsViewController alloc] initWithTripInstance:nextTripInstance];
        [navigationController pushViewController:vc animated:YES];
    }];
    row.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return row;
}

+ (NSUInteger)indexOfStopID:(NSString*)stopID inSchedule:(OBATripScheduleV2*)tripSchedule {
    NSArray<OBATripStopTimeV2*> *stopTimes = tripSchedule.stopTimes;
    for (NSUInteger i=0; i<stopTimes.count; i++) {
        OBATripStopTimeV2 *stopTime = stopTimes[i];
        if ([stopTime.stopId isEqual:stopID]) {
            return i;
        }
    }

    return NSNotFound;
}

@end
