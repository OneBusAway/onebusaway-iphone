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

NS_ASSUME_NONNULL_BEGIN

@class OBAConsoleLogger;

extern const DDLogLevel ddLogLevel;

#define OBALogFunction() DDLogInfo(@"%s", __PRETTY_FUNCTION__)

@interface OBALogging : NSObject
@property(nonatomic,strong,readonly) OBAConsoleLogger *consoleLogger;
- (NSArray<NSData*>*)logFileData;
- (instancetype)initWithLoggers:(nullable NSArray*)loggers;
@end

NS_ASSUME_NONNULL_END
