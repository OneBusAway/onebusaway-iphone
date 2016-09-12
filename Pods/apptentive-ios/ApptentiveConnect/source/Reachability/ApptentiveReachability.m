//
//  ApptentiveReachability.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 4/13/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ApptentiveReachability.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveLog.h"

NSString *const ApptentiveReachabilityStatusChanged = @"ATReachabilityStatusChanged";


@interface ApptentiveReachability ()
- (BOOL)start;
- (void)stop;
@end


@implementation ApptentiveReachability {
	SCNetworkReachabilityRef reachabilityRef;
}

+ (ApptentiveReachability *)sharedReachability {
	static ApptentiveReachability *sharedSingleton = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedSingleton = [[ApptentiveReachability alloc] init];
	});
	return sharedSingleton;
}

- (id)init {
	if ((self = [super init])) {
		SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, [kApptentiveHostName UTF8String]);
		if (reachability != NULL) {
			reachabilityRef = reachability;
			[self start];
		}
	}
	return self;
}

static void ATReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
	@autoreleasepool {
		if (info == NULL) return;
		if (![(__bridge NSObject *)info isKindOfClass:[ApptentiveReachability class]]) return;

		ApptentiveReachability *reachability = (__bridge ApptentiveReachability *)info;

		[[ApptentiveReachability sharedReachability] updateDeviceInfoWithCurrentNetworkType:reachability];

		[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveReachabilityStatusChanged object:reachability];
	}
}

- (void)updateDeviceInfoWithCurrentNetworkType:(ApptentiveReachability *)reachability {
	//TODO: ATDeviceInfo is not currently being updated with the new network type.
	ApptentiveNetworkStatus status = [reachability currentNetworkStatus];

	NSString *statusString = @"network not reachable";
	if (status == ApptentiveNetworkWifiReachable) {
		statusString = @"WiFi";
	} else if (status == ApptentiveNetworkWWANReachable) {
		statusString = @"WWAN";
	}
	ApptentiveLogDebug(@"Apptentive Reachability changed: %@", statusString);
}

- (void)dealloc {
	[self stop];
	if (reachabilityRef != NULL) {
		CFRelease(reachabilityRef);
		reachabilityRef = NULL;
	}
}

- (ApptentiveNetworkStatus)currentNetworkStatus {
	ApptentiveNetworkStatus status = ApptentiveNetworkNotReachable;

	do { // once
		if (reachabilityRef == NULL) {
			break;
		}

		SCNetworkReachabilityFlags flags;

		if (!SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
			break;
		}

		if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
			break;
		}

		if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
			status = ApptentiveNetworkWifiReachable;
		}

		BOOL onDemand = ((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0);
		BOOL onTraffic = ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0);
		BOOL interventionRequired = ((flags & kSCNetworkReachabilityFlagsInterventionRequired) != 0);

		if ((onDemand || onTraffic) && !interventionRequired) {
			status = ApptentiveNetworkWifiReachable;
		}
		BOOL isWWAN = ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN);
		if (isWWAN) {
			status = ApptentiveNetworkWWANReachable;
		}
	} while (NO);

	return status;
}

#pragma mark - Private methods

- (BOOL)start {
	BOOL result = NO;
	SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
	do { // once
		if (!SCNetworkReachabilitySetCallback(reachabilityRef, ATReachabilityCallback, &context)) {
			break;
		}

		if (!SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode)) {
			break;
		}

		result = YES;
	} while (NO);

	return result;
}

- (void)stop {
	if (reachabilityRef != NULL) {
		SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
	}
}
@end
