//
//  OBAEmailHelper.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 7/10/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAEmailHelper.h"
#import <sys/utsname.h>
#import "OBAModelDAO.h"
#import "OBARegionV2.h"
#import "OBACommon.h"

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

#pragma mark - Public Methods

+ (NSString*)messageBodyForModelDAO:(OBAModelDAO*)modelDAO currentLocation:(CLLocation*)location {
    //device model, thanks to http://stackoverflow.com/a/11197770/1233435
    struct utsname systemInfo;
    uname(&systemInfo);

    NSString *unformattedMessageBody = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"feedback_message_body" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];

    NSString *messageBody = [NSString stringWithFormat:unformattedMessageBody,
                             [self appVersion],
                             [NSString stringWithCString:systemInfo.machine
                                                encoding:NSUTF8StringEncoding],
                             [self OSVersion],
                             OBAStringFromBool(modelDAO.readSetRegionAutomatically),
                             modelDAO.region.regionName,
                             modelDAO.readCustomApiUrl,
                             location.coordinate.latitude,
                             location.coordinate.longitude
                             ];
    return messageBody;
}

+ (MFMailComposeViewController*)mailComposeViewControllerForModelDAO:(OBAModelDAO*)modelDAO currentLocation:(CLLocation*)location {

    if (![MFMailComposeViewController canSendMail]) {
        return nil;
    }

    NSString *emailAddress = modelDAO.region.contactEmail ?: kDefaultEmailAddress;
    NSString *messageBody = [self messageBodyForModelDAO:modelDAO currentLocation:location];

    MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
    [composer setToRecipients:@[emailAddress]];
    [composer setSubject:NSLocalizedString(@"OneBusAway iOS Feedback", @"feedback mail subject")];
    [composer setMessageBody:messageBody isHTML:YES];

    return composer;
}

@end
