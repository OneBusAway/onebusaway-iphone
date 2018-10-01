//
//  OBAApplicationConfiguration.h
//  OBAKit
//
//  Created by Aaron Brethorst on 5/10/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

@import Foundation;
@import CocoaLumberjack;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const OBAAppConfigPropertyGoogleAnalyticsKey;
extern NSString * const OBAAppConfigPropertyOneSignalKey;
extern NSString * const OBAAppConfigPropertyAppStoreKey;

@interface OBAApplicationConfiguration : NSObject
@property(nonatomic,assign) BOOL extensionMode;
@property(nonatomic,copy,nullable) NSArray<DDAbstractLogger*> *loggers;
@property(nonatomic,copy) NSString *appPropertiesFilePath;
@property(nonatomic,copy,readonly) NSDictionary *appProperties;
@end

NS_ASSUME_NONNULL_END
