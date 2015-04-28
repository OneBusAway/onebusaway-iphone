//
//  OBAStopRowController.h
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/5/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import <WatchKit/WatchKit.h>

@interface OBAStopRowController : NSObject

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *routeLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *routeTimeLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceTimer *routeMinutesTimer;

@end
