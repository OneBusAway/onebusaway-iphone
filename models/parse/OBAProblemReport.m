//
//  OBAProblemReport.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/22/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAProblemReport.h"
#import <Parse/PFObject+Subclass.h>

@implementation OBAProblemReport
@dynamic tripID;
@dynamic reportType;
@dynamic location;

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return @"OBAProblemReport";
}

#pragma mark - Problem Report Type Enum Translation Nonsense

- (void)setProblemReportType:(OBAProblemReportType)problemReportType
{
    self.reportType = @(problemReportType);
}

- (OBAProblemReportType)problemReportType
{
    if (self.reportType.integerValue >= OBAProblemReportTypeUnknown)
    {
        return OBAProblemReportTypeUnknown;
    }
    else
    {
        return (OBAProblemReportType)self.reportType.integerValue;
    }
}
@end
