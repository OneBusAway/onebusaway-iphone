//
//  ApptentiveMetrics.h
//  ApptentiveMetrics
//
//  Created by Andrew Wooster on 12/27/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ApptentiveInteraction.h"

@class ApptentiveMetric;


@interface ApptentiveMetrics : NSObject
+ (ApptentiveMetrics *)sharedMetrics;

- (void)addMetricWithName:(NSString *)name info:(NSDictionary *)userInfo;
- (void)addMetricWithName:(NSString *)name info:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData;
- (void)addMetricWithName:(NSString *)name fromInteraction:(ApptentiveInteraction *)fromInteraction info:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData;

- (BOOL)upgradeLegacyMetric:(ApptentiveMetric *)metric;

@end
