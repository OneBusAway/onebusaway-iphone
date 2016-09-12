//
//  ATAPIRequest.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 5/24/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveAPIRequest.h"
#import "Apptentive.h"
#import "Apptentive+Debugging.h"
#import "Apptentive_Private.h"
#import "ApptentiveConnectionManager.h"
#import "ApptentiveJSONSerialization.h"
#import "ApptentiveURLConnection.h"
#import "ApptentiveWebClient.h"
#import "ApptentiveWebClient_Private.h"

NSString *const ApptentiveAPIRequestStatusChanged = @"ApptentiveAPIRequestStatusChanged";


@interface ApptentiveAPIRequest ()

@property (strong, nonatomic) ApptentiveURLConnection *connection;
@property (copy, nonatomic) NSString *channelName;
@property (assign, nonatomic) BOOL cancelled;

@end


@implementation ApptentiveAPIRequest

- (id)initWithConnection:(ApptentiveURLConnection *)aConnection channelName:(NSString *)aChannelName {
	if ((self = [super init])) {
		_connection = aConnection;
		_connection.delegate = self;
		_channelName = aChannelName;
	}
	return self;
}

- (void)dealloc {
	self.delegate = nil;
	if (_connection) {
		_connection.delegate = nil;
		[[ApptentiveConnectionManager sharedSingleton] cancelConnection:_connection inChannel:_channelName];
	}
}

- (void)start {
	@synchronized(self) {
		if (_connection) {
			[[ApptentiveConnectionManager sharedSingleton] addConnection:self.connection toChannel:self.channelName];
			[[ApptentiveConnectionManager sharedSingleton] start];
		}
	}
}

- (void)cancel {
	@synchronized(self) {
		_cancelled = YES;
		if (_connection) {
			[[ApptentiveConnectionManager sharedSingleton] cancelConnection:self.connection inChannel:self.channelName];
		}
	}
}

- (void)showAlert {
	if (self.failed) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.errorTitle message:self.errorMessage delegate:nil cancelButtonTitle:ApptentiveLocalizedString(@"Close", nil) otherButtonTitles:nil];
		[alert show];
	}
}

#pragma mark ATURLConnection Delegates
- (void)connectionFinishedSuccessfully:(ApptentiveURLConnection *)sender {
	@synchronized(self) {
		if (self.cancelled) return;
	}
	NSInteger statusCode = sender.statusCode;
	_expiresMaxAge = [sender expiresMaxAge];

	NSIndexSet *okStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(100, 300)];			// 1xx, 2xx, and 3xx status codes
	NSIndexSet *clientErrorStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(400, 100)]; // 4xx status codes
	NSIndexSet *serverErrorStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(500, 100)]; // 5xx status codes

	// TODO: Consider localizing error titles
	if ([okStatusCodes containsIndex:statusCode]) {
		_failed = NO;
	} else if ([clientErrorStatusCodes containsIndex:statusCode]) {
		_failed = YES;
		_shouldRetry = NO;
		_errorTitle = @"Bad Request";
	} else if ([serverErrorStatusCodes containsIndex:statusCode]) {
		_failed = YES;
		_shouldRetry = YES;
		_errorTitle = @"Server error.";
	} else {
		_failed = YES;
		_shouldRetry = YES;
		ApptentiveLogError(@"Unexpected HTTP status: %d", statusCode);
	}

	_errorMessage = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];

	NSObject *result = nil;
	do { // once
		NSData *d = [sender responseData];

		if (self.failed) {
			NSString *responseString = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
			if (responseString != nil) {
				_errorResponse = responseString;
				responseString = nil;
			}
			ApptentiveLogError(@"Connection failed. %@, %@", self.errorTitle, self.errorMessage);
			ApptentiveLogInfo(@"Status was: %d", sender.statusCode);
			if (sender.statusCode == 401) {
				ApptentiveLogError(@"Your Apptentive API key may not be set correctly!");
			}
			if (sender.statusCode == 422) {
				ApptentiveLogError(@"API Request was sent with malformed data");
			}
			if ([Apptentive sharedConnection].debuggingOptions & ApptentiveDebuggingOptionsLogHTTPFailures ||
				[Apptentive sharedConnection].debuggingOptions & ApptentiveDebuggingOptionsLogAllHTTPRequests) {
				ApptentiveLogDebug(@"Request was:\n%@", [self.connection requestAsString]);
				ApptentiveLogDebug(@"Response was:\n%@", [self.connection responseAsString]);
			}
		} else if ([Apptentive sharedConnection].debuggingOptions & ApptentiveDebuggingOptionsLogAllHTTPRequests) {
			ApptentiveLogDebug(@"Request was:\n%@", [self.connection requestAsString]);
			ApptentiveLogDebug(@"Response was:\n%@", [self.connection responseAsString]);
		}

		if (!d) break;
		if (self.returnType == ApptentiveAPIRequestReturnTypeData) {
			result = d;
			break;
		}

		NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
		if (!s) break;
		if (self.returnType == ApptentiveAPIRequestReturnTypeString) {
			result = s;
			break;
		}

		if (self.returnType == ApptentiveAPIRequestReturnTypeJSON && statusCode != 204) {
			NSError *error = nil;
			id json = [ApptentiveJSONSerialization JSONObjectWithString:s error:&error];
			if (!json) {
				_failed = YES;
				_errorTitle = ApptentiveLocalizedString(@"Invalid response from server.", @"");
				_errorMessage = ApptentiveLocalizedString(@"Server did not return properly formatted JSON.", @"");
				ApptentiveLogError(@"Invalid JSON: %@", error);
			}
			result = json;
			break;
		}
	} while (NO);

	if (self.delegate) {
		if (self.failed) {
			[self.delegate at_APIRequestDidFail:self];
		} else {
			[self.delegate at_APIRequestDidFinish:self result:result];
		}
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveAPIRequestStatusChanged object:self];
}

- (void)connectionFailed:(ApptentiveURLConnection *)sender {
	@synchronized(self) {
		if (self.cancelled) return;
	}
	_failed = YES;
	if (sender.failedAuthentication || sender.statusCode == 401) {
		_errorTitle = ApptentiveLocalizedString(@"Authentication Failed", @"");
		_errorMessage = ApptentiveLocalizedString(@"Wrong username and/or password.", @"");
	} else {
		_errorTitle = ApptentiveLocalizedString(@"Network Connection Error", @"");
		_errorMessage = [sender.connectionError localizedDescription];
	}
	NSData *d = [sender responseData];
	NSString *responseString = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
	if (responseString != nil) {
		_errorResponse = responseString;
		responseString = nil;
	}

	if ([Apptentive sharedConnection].debuggingOptions & ApptentiveDebuggingOptionsLogHTTPFailures ||
		[Apptentive sharedConnection].debuggingOptions & ApptentiveDebuggingOptionsLogAllHTTPRequests) {
		ApptentiveLogError(@"Connection failed. %@, %@", self.errorTitle, self.errorMessage);
		ApptentiveLogInfo(@"Status was: %d", sender.statusCode);
		ApptentiveLogDebug(@"Request was:\n%@", [self.connection requestAsString]);
		ApptentiveLogDebug(@"Response was:\n%@", [self.connection responseAsString]);
	}
	if (self.delegate) {
		[self.delegate at_APIRequestDidFail:self];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveAPIRequestStatusChanged object:self];
}

- (void)connectionDidProgress:(ApptentiveURLConnection *)sender {
	_percentageComplete = sender.percentComplete;
	if (self.delegate && [self.delegate respondsToSelector:@selector(at_APIRequestDidProgress:)]) {
		[self.delegate at_APIRequestDidProgress:self];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveAPIRequestStatusChanged object:self];
}
@end
