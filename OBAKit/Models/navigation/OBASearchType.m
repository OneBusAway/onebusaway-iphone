//
//  OBASearchType.m
//  OBAKit
//
//  Created by Aaron Brethorst on 2/21/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBASearchType.h>
#import <OBAKit/OBAMacros.h>

NSString * NSStringFromOBASearchType(OBASearchType searchType) {
    switch (searchType) {
        case OBASearchTypePending: {
            return OBALocalized(@"search_type.pending", @"OBASearchTypePending. Rendered as 'Pending' in English.");
        }
        case OBASearchTypeRegion: {
            return OBALocalized(@"search_type.region", @"OBASearchTypeRegion. Rendered as 'Region' in English.");
        }
        case OBASearchTypeRoute: {
            return OBALocalized(@"search_type.route", @"OBASearchTypeRoute. Rendered as 'Route' in English.");
        }
        case OBASearchTypeStops: {
            return OBALocalized(@"search_type.stops", @"OBASearchTypeStops. Rendered as 'Stops' in English.");
        }
        case OBASearchTypeAddress: {
            return OBALocalized(@"search_type.address", @"OBASearchTypeAddress. Rendered as 'Address' in English.");
        }
        case OBASearchTypePlacemark: {
            return OBALocalized(@"search_type.placemark", @"OBASearchTypePlacemark. Rendered as 'Placemark' in English.");
        }
        case OBASearchTypeStopIdSearch:
        case OBASearchTypeStopId: {
            return OBALocalized(@"search_type.stop_id", @"OBASearchTypeStopId. Rendered as 'Stop ID' in English.");
        }
        default: {
            return nil;
        }
    }
}
