//
//  ApptentiveWebClient_Private.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ApptentiveURLConnection;
@class ApptentiveWebClient;


@interface ApptentiveWebClient ()
- (NSString *)userAgentString;

#pragma mark API URL String
- (NSURL *)APIURLWithPath:(NSString *)path;

#pragma mark Query Parameter Encoding
- (NSString *)stringForParameters:(NSDictionary *)parameters;
- (NSString *)stringForParameter:(id)value;

#pragma mark Internal Methods
- (ApptentiveURLConnection *)connectionToGet:(NSString *)path;
- (ApptentiveURLConnection *)connectionToPost:(NSString *)path;
- (ApptentiveURLConnection *)connectionToPost:(NSString *)path JSON:(NSString *)body;
- (ApptentiveURLConnection *)connectionToPost:(NSString *)path parameters:(NSDictionary *)parameters;
- (ApptentiveURLConnection *)connectionToPost:(NSString *)path body:(NSString *)body;
- (ApptentiveURLConnection *)connectionToPost:(NSString *)path JSON:(NSString *)body withAttachments:(NSArray *)attachments;
- (ApptentiveURLConnection *)connectionToPut:(NSString *)path JSON:(NSString *)body;
- (void)addAPIHeaders:(ApptentiveURLConnection *)conn;
- (void)updateConnection:(ApptentiveURLConnection *)conn withOAuthToken:(NSString *)token;
@end
