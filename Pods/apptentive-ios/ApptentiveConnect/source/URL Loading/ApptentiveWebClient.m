//
//  ApptentiveWebClient.m
//  apptentive-ios
//
//  Created by Andrew Wooster on 7/28/09.
//  Copyright 2009 Apptentive, Inc.. All rights reserved.
//

#import "ApptentiveWebClient.h"
#import "ApptentiveWebClient_Private.h"
#import "ApptentiveAPIRequest.h"
#import "ApptentiveURLConnection.h"

#import "ApptentiveBackend.h"
#import "Apptentive.h"
#import "ApptentiveConversationUpdater.h"
#import "ApptentiveURLConnection.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveWebClient_Private.h"

NSString *const ATWebClientDefaultChannelName = @"ATWebClient";

#define kApptentiveAPIVersion @"6"


@implementation ApptentiveWebClient

- (instancetype)initWithBaseURL:(NSURL *)baseURL APIKey:(NSString *)APIKey {
	self = [super init];

	if (self) {
		_baseURL = baseURL;
		_APIKey = APIKey;
	}

	return self;
}

- (NSString *)commonChannelName {
	return ATWebClientDefaultChannelName;
}

- (NSString *)APIVersion {
	return kApptentiveAPIVersion;
}

- (ApptentiveAPIRequest *)requestForGettingAppConfiguration {
	ApptentiveConversation *conversation = [ApptentiveConversationUpdater currentConversation];
	if (!conversation) {
		return nil;
	}
	ApptentiveURLConnection *conn = [self connectionToGet:@"/conversation/configuration"];
	conn.timeoutInterval = 20.0;
	[self updateConnection:conn withOAuthToken:conversation.token];
	ApptentiveAPIRequest *request = [[ApptentiveAPIRequest alloc] initWithConnection:conn channelName:[self commonChannelName]];
	request.returnType = ApptentiveAPIRequestReturnTypeJSON;
	return request;
}

- (NSString *)stringForParameters:(NSDictionary *)parameters {
	NSMutableString *result = [[NSMutableString alloc] init];
	do { // once
		if (!parameters || [parameters count] == 0) {
			[result appendString:@""];
			break;
		}

		BOOL appendAmpersand = NO;
		for (NSString *key in [parameters keyEnumerator]) {
			NSString *val = [self stringForParameter:[parameters objectForKey:key]];
			if (!val) continue;

			if (appendAmpersand) {
				[result appendString:@"&"];
			}
			[result appendString:[ApptentiveUtilities stringByEscapingForURLArguments:key]];
			[result appendString:@"="];
			[result appendString:[ApptentiveUtilities stringByEscapingForURLArguments:val]];
			appendAmpersand = YES;
		}
	} while (NO);
	return result;
}

- (NSString *)stringForParameter:(id)value {
	NSString *result = nil;
	if ([value isKindOfClass:[NSString class]]) {
		result = (NSString *)value;
	} else if ([value isKindOfClass:[NSNumber class]]) {
		result = [(NSNumber *)value stringValue];
	}
	return result;
}

- (NSURL *)APIURLWithPath:(NSString *)path {
	return [NSURL URLWithString:path relativeToURL:self.baseURL];
}

- (NSString *)userAgentString {
	return [NSString stringWithFormat:@"ApptentiveConnect/%@ (%@)", kApptentiveVersionString, kApptentivePlatformString];
}

- (ApptentiveURLConnection *)connectionToGet:(NSString *)path {
	ApptentiveURLConnection *conn = [[ApptentiveURLConnection alloc] initWithURL:[self APIURLWithPath:path]];
	[self addAPIHeaders:conn];
	return conn;
}

- (ApptentiveURLConnection *)connectionToPost:(NSString *)path {
	ApptentiveURLConnection *conn = [[ApptentiveURLConnection alloc] initWithURL:[self APIURLWithPath:path]];
	[self addAPIHeaders:conn];
	[conn setHTTPMethod:@"POST"];
	return conn;
}

- (ApptentiveURLConnection *)connectionToPost:(NSString *)path JSON:(NSString *)body {
	ApptentiveURLConnection *conn = [[ApptentiveURLConnection alloc] initWithURL:[self APIURLWithPath:path]];
	[self addAPIHeaders:conn];
	[conn setHTTPMethod:@"POST"];
	[conn setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	NSUInteger length = [body lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	[conn setValue:[NSString stringWithFormat:@"%lu", (unsigned long)length] forHTTPHeaderField:@"Content-Length"];
	[conn setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
	return conn;
}

- (ApptentiveURLConnection *)connectionToPost:(NSString *)path parameters:(NSDictionary *)parameters {
	NSDictionary *postParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
	NSString *bodyString = [self stringForParameters:postParameters];
	return [self connectionToPost:path body:bodyString];
}

- (ApptentiveURLConnection *)connectionToPost:(NSString *)path body:(NSString *)body {
	ApptentiveURLConnection *conn = [[ApptentiveURLConnection alloc] initWithURL:[self APIURLWithPath:path]];
	[self addAPIHeaders:conn];
	[conn setHTTPMethod:@"POST"];
	[conn setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	NSUInteger length = [body lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	[conn setValue:[NSString stringWithFormat:@"%lu", (unsigned long)length] forHTTPHeaderField:@"Content-Length"];
	[conn setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
	return conn;
}

- (ApptentiveURLConnection *)connectionToPut:(NSString *)path JSON:(NSString *)body {
	ApptentiveURLConnection *conn = [self connectionToPost:path JSON:body];
	[conn setHTTPMethod:@"PUT"];
	return conn;
}

- (void)addAPIHeaders:(ApptentiveURLConnection *)conn {
	[conn setValue:[self userAgentString] forHTTPHeaderField:@"User-Agent"];
	[conn setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	[conn setValue:@"utf-8" forHTTPHeaderField:@"Accept-Charset"];

	// Apptentive API Version
	[conn setValue:self.APIVersion forHTTPHeaderField:@"X-API-Version"];

	// Apptentive API Key
	[self updateConnection:conn withOAuthToken:self.APIKey];
}

- (void)updateConnection:(ApptentiveURLConnection *)conn withOAuthToken:(NSString *)token {
	if (token) {
		NSString *value = [NSString stringWithFormat:@"OAuth %@", token];
		[conn setValue:value forHTTPHeaderField:@"Authorization"];
	} else {
		[conn removeHTTPHeaderField:@"Authorization"];
	}
}

- (ApptentiveURLConnection *)connectionToPost:(NSString *)path JSON:(NSString *)body withAttachments:(NSArray *)attachments {
	ApptentiveURLConnection *conn = [[ApptentiveURLConnection alloc] initWithURL:[self APIURLWithPath:path]];
	[self addAPIHeaders:conn];
	[conn setHTTPMethod:@"POST"];
	NSString *boundary = [ApptentiveUtilities randomStringOfLength:20];
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
	[conn setValue:contentType forHTTPHeaderField:@"Content-Type"];

	NSMutableData *multipartEncodedData = [NSMutableData data];
	//[multipartEncodedData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	NSMutableString *debugString = [NSMutableString string];

	for (NSString *key in [conn headers]) {
		[debugString appendFormat:@"%@: %@\n", key, [[conn headers] objectForKey:key]];
	}
	[debugString appendString:@"\n"];

	if (body) {
		NSMutableString *bodyHeader = [NSMutableString string];
		[bodyHeader appendString:[NSString stringWithFormat:@"--%@\r\n", boundary]];
		[bodyHeader appendString:[NSString stringWithFormat:@"Content-Type: %@\r\n", @"text/plain"]];
		[bodyHeader appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"message"]];
		[debugString appendString:bodyHeader];

		[multipartEncodedData appendData:[bodyHeader dataUsingEncoding:NSUTF8StringEncoding]];
		[multipartEncodedData appendData:[(NSString *)body dataUsingEncoding:NSUTF8StringEncoding]];
		[debugString appendString:body];
	}

	for (ApptentiveFileAttachment *attachment in attachments) {
		NSString *boundaryString = [NSString stringWithFormat:@"\r\n--%@\r\n", boundary];
		[multipartEncodedData appendData:[boundaryString dataUsingEncoding:NSUTF8StringEncoding]];
		[debugString appendString:boundaryString];

		NSMutableString *multipartHeader = [NSMutableString string];
		[multipartHeader appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", @"file[]", attachment.name]];
		[multipartHeader appendString:[NSString stringWithFormat:@"Content-Type: %@\r\n", attachment.mimeType]];
		[multipartHeader appendString:@"Content-Transfer-Encoding: binary\r\n\r\n"];
		[debugString appendString:multipartHeader];

		[multipartEncodedData appendData:[multipartHeader dataUsingEncoding:NSUTF8StringEncoding]];
		[multipartEncodedData appendData:attachment.fileData];
		[debugString appendFormat:@"<NSData of length: %lu>", (unsigned long)[attachment.fileData length]];
	}

	NSString *finalBoundary = [NSString stringWithFormat:@"\r\n--%@--\r\n", boundary];
	[multipartEncodedData appendData:[finalBoundary dataUsingEncoding:NSUTF8StringEncoding]];
	[debugString appendString:finalBoundary];

	//NSLog(@"\n%@", debugString);

	[conn setHTTPBody:multipartEncodedData];

	// Debugging helpers:
	/*
	 NSLog(@"wtf parameters: %@", parameters);
	 NSLog(@"-length: %d", [multipartEncodedData length]);
	 NSLog(@"-data: %@", [NSString stringWithUTF8String:[multipartEncodedData bytes]]);
	 */
	return conn;
}

@end
