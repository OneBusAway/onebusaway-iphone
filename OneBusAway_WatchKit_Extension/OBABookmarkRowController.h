//
//  OBABookmarkRowController.h
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/5/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import <WatchKit/WatchKit.h>

@interface OBABookmarkRowController : NSObject

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *titleLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *detailLabel;

@end
