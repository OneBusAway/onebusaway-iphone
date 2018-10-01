//
//  OBAApplicationConfiguration.m
//  OBAKit
//
//  Created by Aaron Brethorst on 5/10/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

#import "OBAApplicationConfiguration.h"

NSString * const OBAAppConfigPropertyGoogleAnalyticsKey = @"google_analytics_id";
NSString * const OBAAppConfigPropertyOneSignalKey = @"onesignal_api_key";
NSString * const OBAAppConfigPropertyAppStoreKey = @"appstore_id";

@interface OBAApplicationConfiguration ()
@property(nonatomic,copy,readwrite) NSDictionary *appProperties;
@end

@implementation OBAApplicationConfiguration

- (NSDictionary*)appProperties {
    if (!_appProperties) {
        _appProperties = [[NSDictionary alloc] initWithContentsOfFile:_appPropertiesFilePath];
    }
    return _appProperties;
}

@end
