//
//  OBAProblemReport.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/22/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import <Parse/Parse.h>

typedef NS_ENUM(NSInteger, OBAProblemReportType) {
    OBAProblemReportTypeFullBus = 0,
    OBAProblemReportTypeUnknown //Make sure this is always the *last* item in the list
};

@interface OBAProblemReport : PFObject<PFSubclassing>
@property(nonatomic,strong) NSString *tripID;
@property(nonatomic,strong) NSNumber *reportType;
@property(nonatomic,strong) PFGeoPoint *location;

@property(nonatomic,assign) OBAProblemReportType problemReportType;
@end
