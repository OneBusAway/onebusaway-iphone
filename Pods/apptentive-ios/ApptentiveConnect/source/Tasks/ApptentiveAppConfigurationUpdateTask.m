//
//  ApptentiveAppConfigurationUpdateTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 7/20/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveAppConfigurationUpdateTask.h"
#import "Apptentive_Private.h"
#import "ApptentiveConversationUpdater.h"


@implementation ApptentiveAppConfigurationUpdateTask {
	ApptentiveAppConfigurationUpdater *configurationUpdater;
}

+ (void)load {
	[NSKeyedUnarchiver setClass:self forClassName:@"ATAppConfigurationUpdateTask"];
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
}

- (void)dealloc {
	[self stop];
}

- (BOOL)canStart {
	if ([Apptentive sharedConnection].webClient == nil) {
		return NO;
	}
	if (![ApptentiveConversationUpdater conversationExists]) {
		return NO;
	}
	return YES;
}

- (BOOL)shouldArchive {
	return NO;
}

- (void)start {
	if (configurationUpdater == nil && [ApptentiveAppConfigurationUpdater shouldCheckForUpdate]) {
		configurationUpdater = [[ApptentiveAppConfigurationUpdater alloc] initWithDelegate:self];
		self.inProgress = YES;
		[configurationUpdater update];
	} else {
		self.finished = YES;
	}
}

- (void)stop {
	if (configurationUpdater) {
		[configurationUpdater cancel];
		configurationUpdater = nil;
		self.inProgress = NO;
	}
}

- (float)percentComplete {
	if (configurationUpdater) {
		return [configurationUpdater percentageComplete];
	} else {
		return 0.0f;
	}
}

- (NSString *)taskName {
	return @"configuration update";
}

#pragma mark ATAppConfigurationUpdaterDelegate
- (void)configurationUpdaterDidFinish:(BOOL)success {
	@synchronized(self) {
		if (configurationUpdater) {
			if (!success) {
				self.failed = YES;
				[self stop];
			} else {
				self.finished = YES;
			}
		}
	}
}
@end
