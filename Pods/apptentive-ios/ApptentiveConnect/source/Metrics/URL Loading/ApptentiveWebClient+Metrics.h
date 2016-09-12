//
//  ApptentiveWebClient+Metrics.h
//  ApptentiveMetrics
//
//  Created by Andrew Wooster on 1/10/12.
//  Copyright (c) 2012 Apptentive. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ApptentiveWebClient.h"

@class ApptentiveAPIRequest, ApptentiveMetric, ApptentiveEvent;


@interface ApptentiveWebClient (Metrics)
- (ApptentiveAPIRequest *)requestForSendingMetric:(ApptentiveMetric *)metric;
- (ApptentiveAPIRequest *)requestForSendingEvent:(ApptentiveEvent *)event;
@end
