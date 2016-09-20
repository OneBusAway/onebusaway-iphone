//
//  OBATripScheduleSectionBuilder.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 5/26/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OBAKit/OBAKit.h>
#import "OBATableSection.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBATripScheduleSectionBuilder : NSObject
+ (OBATableSection*)buildStopsSection:(OBATripDetailsV2*)tripDetails navigationController:(UINavigationController*)navigationController;
+ (nullable OBATableSection*)buildConnectionsSectionWithTripDetails:(OBATripDetailsV2*)tripDetails tripInstance:(OBATripInstanceRef*)tripInstance navigationController:(UINavigationController*)navigationController;
+ (NSUInteger)indexOfStopID:(NSString*)stopID inSchedule:(OBATripScheduleV2*)tripSchedule;
@end

NS_ASSUME_NONNULL_END