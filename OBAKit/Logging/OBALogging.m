//
//  OBALogging.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/11/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBALogging.h>
#import <OBAKit/OBAConsoleLogger.h>
#import <OBAKit/NSArray+OBAAdditions.h>

const DDLogLevel ddLogLevel = DDLogLevelInfo;

@interface OBALogging ()
@property(nonatomic,strong,readwrite) OBAConsoleLogger *consoleLogger;
@property(nonatomic,strong) DDFileLogger *fileLogger;
@end

@implementation OBALogging

- (instancetype)init {
    return [self initWithLoggers:nil];
}

- (instancetype)initWithLoggers:(nullable NSArray<DDAbstractLogger*>*)loggers {
    self = [super init];

    if (self) {
        _consoleLogger = [[OBAConsoleLogger alloc] init];
        [DDLog addLogger:_consoleLogger];
        [DDLog addLogger:[DDASLLogger sharedInstance] withLevel:ddLogLevel]; // ASL = Apple System Logs
        [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:ddLogLevel]; // TTY = Xcode console

        for (DDAbstractLogger *logger in loggers) {
            [DDLog addLogger:logger withLevel:ddLogLevel];
        }

        _fileLogger = [[DDFileLogger alloc] init];
        _fileLogger.rollingFrequency = 60*60*24;  // 24 hours
        _fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
        [DDLog addLogger:self.fileLogger];
    }
    return self;
}

- (NSArray<NSData*>*)logFileData {
    NSMutableArray<NSData*> *logFiles = [[NSMutableArray alloc] init];
    NSArray *sortedLogFileInfos = [self.fileLogger.logFileManager.sortedLogFileInfos oba_pickFirst:3];

    for (DDLogFileInfo *logFileInfo in sortedLogFileInfos) {
        NSData *fileData = [NSData dataWithContentsOfFile:logFileInfo.filePath];
        [logFiles addObject:fileData];
    }

    return [NSArray arrayWithArray:logFiles];
}

@end
