//
//  OBALogging.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/11/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;
@import CocoaLumberjack;
@import CocoaLumberjackSwift;

extern const DDLogLevel ddLogLevel;

@interface OBALogging : NSObject
+ (void)configureLogging;
@end
