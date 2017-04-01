//
//  OBARegionalAlert.h
//  OBAKit
//
//  Created by Aaron Brethorst on 3/16/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

@import Foundation;
@import Mantle;

typedef NS_ENUM(NSUInteger, OBARegionalAlertPriority) {
    OBARegionalAlertPriorityNormal=0,
    OBARegionalAlertPriorityHigh
};

@interface OBARegionalAlert : MTLModel <MTLJSONSerializing>
@property(nonatomic,assign) BOOL unread;
@property(nonatomic,assign) NSUInteger identifier;
@property(nonatomic,copy) NSString *title;
@property(nonatomic,copy) NSString *feedName;
@property(nonatomic,assign) OBARegionalAlertPriority priority;
@property(nonatomic,copy) NSString *summary;
@property(nonatomic,copy) NSURL *URL;
@property(nonatomic,assign) NSUInteger alertFeedID;
@property(nonatomic,copy) NSDate *publishedAt;
@property(nonatomic,copy) NSString *externalID;
@end
