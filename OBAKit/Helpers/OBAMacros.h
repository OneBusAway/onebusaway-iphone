//
//  OBAMacros.h
//  OneBusAwaySDK
//
//  Created by Aaron Brethorst on 2/16/16.
//  Copyright © 2016 One Bus Away. All rights reserved.
//

#import <OBAKit/OBACommon.h>

#ifndef OBAMacros_h
#define OBAMacros_h

#define APP_DELEGATE ((OBAApplicationDelegate*)[UIApplication sharedApplication].delegate)

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#define OBAAssert(__param) \
    if (![OBACommon isRunningInsideTests]) { NSParameterAssert(__param); }

#define OBAGuard(CONDITION) \
    if (!(CONDITION)) { OBAAssert(CONDITION); } \
    if (CONDITION) {}

#define OBAGuardClass(object, typeName) \
    OBAGuard([object isKindOfClass:[typeName class]])

#define OBALocalized(key, comment) \
    [[NSBundle bundleWithIdentifier:@"org.onebusaway.iphone.OBAKit"] localizedStringForKey:(key) value:@"" table:nil]

#define INIT_NIB_UNAVAILABLE \
    - (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

#define INIT_CODER_UNAVAILABLE \
    - (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;


#endif /* OBAMacros_h */
