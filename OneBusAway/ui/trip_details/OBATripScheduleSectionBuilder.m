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
#import "OBAArrivalDepartureRow.h"
#import "OBATimelineBarRow.h"

@implementation OBATripScheduleSectionBuilder

// TODO: This and the next method are very nearly duplicates. I am including this for the
// moment because I want to keep making forward progress without getting bogged down in
// the (I hope) soon-to-be-unnecessary view controllers that still use this method.
// The ideal solution, to my mind, would be to delete this method and the view controllers
// that depend on it.
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

        OBAArrivalDepartureRow *row = [[OBAArrivalDepartureRow alloc] initWithTitle:stop.name action:^(OBABaseRow *r2) {
            OBAStopViewController *vc = [[OBAStopViewController alloc] initWithStopID:stopTime.stopId];
            [navigationController pushViewController:vc animated:YES];
        }];

        row.routeType = stop.firstAvailableRouteTypeForStop;
        row.subtitle = [self formattedStopTime:stopTime tripDetails:tripDetails];
        row.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        [stopsSection addRow:row];
    }

    if (continuingRow) {
        [stopsSection addRow:continuingRow];
    }
    
    return stopsSection;
}

+ (OBATableSection*)buildStopsSection:(OBATripDetailsV2*)tripDetails arrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture currentStopIndex:(NSUInteger)currentStopIndex navigationController:(UINavigationController*)navigationController {
    OBATripInstanceRef *tripInstance = arrivalAndDeparture.tripInstance;
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

        OBAArrivalDepartureRow *row = [[OBAArrivalDepartureRow alloc] initWithTitle:stop.name action:^(OBABaseRow *r2) {
            OBAStopViewController *vc = [[OBAStopViewController alloc] initWithStopID:stopTime.stopId];
            [navigationController pushViewController:vc animated:YES];
        }];

        row.selectedStopForRider = [stop.stopId isEqual:arrivalAndDeparture.stopId];
        row.closestStopToVehicle = [stop.stopId isEqual:arrivalAndDeparture.tripStatus.closestStopID];
        row.routeType = stop.firstAvailableRouteTypeForStop;
        row.subtitle = [self formattedStopTime:stopTime tripDetails:tripDetails];
        row.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        row.model = stopTime;

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
        return [NSString stringWithFormat:@"%@ %@", @(minutes), NSLocalizedString(@"msg_mins", @"minutes")];
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

    NSString *labelText = [NSString stringWithFormat:NSLocalizedString(@"text_starts_as_param", @""), [tripDetails.schedule.previousTrip asLabel]];
    OBATimelineBarRow *row = [[OBATimelineBarRow alloc] initWithTitle:labelText action:^(OBABaseRow *r2) {
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

    NSString *labelText = [NSString stringWithFormat:NSLocalizedString(@"text_continues_as_param", @""), [tripDetails.schedule.nextTrip asLabel]];
    OBATimelineBarRow *row = [[OBATimelineBarRow alloc] initWithTitle:labelText action:^(OBABaseRow *r2) {
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
