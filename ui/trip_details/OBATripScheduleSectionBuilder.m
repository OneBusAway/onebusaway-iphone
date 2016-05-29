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

+ (OBATableSection*)buildStopsSection:(OBATripDetailsV2*)tripDetails navigationController:(UINavigationController*)navigationController {
    OBATripScheduleV2 *schedule = tripDetails.schedule;

    OBATableSection *stopsSection = [[OBATableSection alloc] initWithTitle:nil];
    for (OBATripStopTimeV2 *stopTime in schedule.stopTimes) {
        OBAStopV2 *stop = stopTime.stop;

        [stopsSection addRow:^OBABaseRow *{
            OBATableRow *row = [[OBATableRow alloc] initWithTitle:stop.name action:^{
                OBAStopViewController *vc = [[OBAStopViewController alloc] initWithStopID:stopTime.stopId];
                [navigationController pushViewController:vc animated:YES];
            }];
            row.subtitle = [self formattedStopTime:stopTime tripDetails:tripDetails];
            row.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            row.style = UITableViewCellStyleValue1;

            return row;
        }];
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

+ (nullable OBATableSection*)buildConnectionsSectionWithTripDetails:(OBATripDetailsV2*)tripDetails tripInstance:(OBATripInstanceRef*)tripInstance navigationController:(UINavigationController*)navigationController {

    if (!tripDetails.schedule.previousTripId && !tripDetails.schedule.nextTripId) {
        return nil;
    }

    OBATableSection *connectionsSection = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"Connections", @"Connections section at the bottom of the Trip Schedule List view controller")];

    if (tripDetails.schedule.previousTrip) {
        [connectionsSection addRow:^OBABaseRow *{
            NSString *labelText = [NSString stringWithFormat:NSLocalizedString(@"Starts as %@", @""), [tripDetails.schedule.previousTrip asLabel]];
            OBATableRow *row = [[OBATableRow alloc] initWithTitle:labelText action:^{
                OBATripInstanceRef *prevTripInstance = [tripInstance copyWithNewTripId:tripDetails.schedule.previousTripId];
                OBATripDetailsViewController *vc = [[OBATripDetailsViewController alloc] initWithTripInstance:prevTripInstance];
                [navigationController pushViewController:vc animated:YES];
            }];
            return row;
        }];
    }

    if (tripDetails.schedule.nextTrip) {
        [connectionsSection addRow:^OBABaseRow *{
            NSString *labelText = [NSString stringWithFormat:NSLocalizedString(@"Continues as %@", @""), [tripDetails.schedule.nextTrip asLabel]];
            OBATableRow *row = [[OBATableRow alloc] initWithTitle:labelText action:^{
                OBATripInstanceRef *nextTripInstance = [tripInstance copyWithNewTripId:tripDetails.schedule.nextTripId];
                OBATripDetailsViewController *vc = [[OBATripDetailsViewController alloc] initWithTripInstance:nextTripInstance];
                [navigationController pushViewController:vc animated:YES];
            }];
            return row;
        }];
    }

    return connectionsSection;
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
