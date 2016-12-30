//
//  OBAEmailHelper.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 7/10/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAEmailHelper.h>
#import <sys/utsname.h>
#import <OBAKit/OBAModelDAO.h>
#import <OBAKit/OBARegionV2.h>
#import <OBAKit/OBACommon.h>
#import <OBAKit/OBAMacros.h>

static NSString const * kDefaultEmailAddress = @"contact@onebusaway.org";

static NSString * OSVersion = nil;
static NSString * appVersion = nil;

@implementation OBAEmailHelper

#pragma mark - Gross, internal test helpers

// TODO: Remove these once we have a proper mocking library that can do this for us :-\

+ (void)setOSVersion:(NSString*)OSVersionOverride {
    OSVersion = OSVersionOverride;
}

+ (NSString*)OSVersion {
    if (!OSVersion) {
        OSVersion = [[UIDevice currentDevice] systemVersion];
    }

    return OSVersion;
}

+ (void)setAppVersion:(NSString*)appVersionOverride {
    appVersion = appVersionOverride;
}

+ (NSString*)appVersion {
    if (!appVersion) {
        appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    }
    return appVersion;
}

+ (NSString*)deviceInfo {
    //device model, thanks to http://stackoverflow.com/a/11197770/1233435
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceInfo = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];

    return deviceInfo;
}

#pragma mark - Public Methods

+ (NSString*)messageBodyForModelDAO:(OBAModelDAO*)modelDAO currentLocation:(CLLocation*)location {

    NSMutableString *messageBody = [NSMutableString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"feedback_message_body" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];

    [messageBody replaceOccurrencesOfString:@"{{app_version}}" withString:[self appVersion] options:NSCaseInsensitiveSearch range:NSMakeRange(0, messageBody.length)];

    [messageBody replaceOccurrencesOfString:@"{{device}}" withString:[self deviceInfo] options:NSCaseInsensitiveSearch range:NSMakeRange(0, messageBody.length)];

    [messageBody replaceOccurrencesOfString:@"{{ios_version}}" withString:[self OSVersion] options:NSCaseInsensitiveSearch range:NSMakeRange(0, messageBody.length)];

    [messageBody replaceOccurrencesOfString:@"{{set_region_automatically}}" withString:OBAStringFromBool(modelDAO.automaticallySelectRegion) options:NSCaseInsensitiveSearch range:NSMakeRange(0, messageBody.length)];

    [messageBody replaceOccurrencesOfString:@"{{region_name}}" withString:modelDAO.currentRegion.regionName options:NSCaseInsensitiveSearch range:NSMakeRange(0, messageBody.length)];

    [messageBody replaceOccurrencesOfString:@"{{region_identifier}}" withString:[@(modelDAO.currentRegion.identifier) description] options:NSCaseInsensitiveSearch range:NSMakeRange(0, messageBody.length)];

    [messageBody replaceOccurrencesOfString:@"{{region_base_api_url}}" withString:modelDAO.currentRegion.baseURL.absoluteString options:NSCaseInsensitiveSearch range:NSMakeRange(0, messageBody.length)];

    NSString *locationString = @"Unknown";
    if (location) {
        locationString = [NSString stringWithFormat:@"(%@, %@)", @(location.coordinate.latitude), @(location.coordinate.longitude)];
    }

    [messageBody replaceOccurrencesOfString:@"{{location}}" withString:locationString options:NSCaseInsensitiveSearch range:NSMakeRange(0, messageBody.length)];

    return messageBody;
}

+ (MFMailComposeViewController*)mailComposeViewControllerForModelDAO:(OBAModelDAO*)modelDAO currentLocation:(CLLocation*)location {

    if (![MFMailComposeViewController canSendMail]) {
        return nil;
    }

    NSString *emailAddress = modelDAO.currentRegion.contactEmail ?: kDefaultEmailAddress;
    NSString *messageBody = [self messageBodyForModelDAO:modelDAO currentLocation:location];

    MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
    [composer setToRecipients:@[emailAddress]];
    [composer setSubject:OBALocalized(@"msg_oba_ios_feedback", @"feedback mail subject")];
    [composer setMessageBody:messageBody isHTML:YES];

    return composer;
}

@end
