//
//  OBACrashlyticsLogger.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 5/10/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

@import Foundation;
@import CocoaLumberjack;
@import Crashlytics;

NS_ASSUME_NONNULL_BEGIN

@interface OBACrashlyticsLogger : DDAbstractLogger

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
