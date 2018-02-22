//
//  OBASearchType.h
//  OBAKit
//
//  Created by Aaron Brethorst on 2/21/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

@import Foundation;

typedef NS_ENUM(NSUInteger, OBASearchType) {
    OBASearchTypeNone=0,
    OBASearchTypePending,
    OBASearchTypeRegion,
    OBASearchTypeRoute,
    OBASearchTypeStops,
    OBASearchTypeAddress,
    OBASearchTypePlacemark,
    OBASearchTypeStopId,
    OBASearchTypeRegionalAlert,
};

NSString * _Nullable NSStringFromOBASearchType(OBASearchType searchType);

