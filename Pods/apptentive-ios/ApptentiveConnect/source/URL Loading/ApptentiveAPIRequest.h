//
//  ApptentiveAPIRequest.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 5/24/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ApptentiveURLConnection.h"

extern NSString *const ApptentiveAPIRequestStatusChanged;

@class ApptentiveAPIRequest;

typedef enum {
	ApptentiveAPIRequestReturnTypeData,
	ApptentiveAPIRequestReturnTypeString,
	ApptentiveAPIRequestReturnTypeJSON
} ApptentiveAPIRequestReturnType;

@protocol ApptentiveAPIRequestDelegate <NSObject>
- (void)at_APIRequestDidFinish:(ApptentiveAPIRequest *)request result:(NSObject *)result;
- (void)at_APIRequestDidFail:(ApptentiveAPIRequest *)request;
@optional
- (void)at_APIRequestDidProgress:(ApptentiveAPIRequest *)request;
@end

/*! API request for the apptentive.com service. Encapsulates the connection
 connection state, completion percentage, etc. */
@interface ApptentiveAPIRequest : NSObject <ApptentiveURLConnectionDelegate>

@property (readonly, nonatomic) BOOL failed;
@property (readonly, nonatomic) BOOL shouldRetry;
@property (readonly, nonatomic) NSString *errorTitle;
@property (readonly, nonatomic) NSString *errorMessage;
@property (readonly, nonatomic) NSString *errorResponse;
@property (readonly, nonatomic) float percentageComplete;
@property (readonly, nonatomic) NSTimeInterval expiresMaxAge;

@property (assign, nonatomic) ApptentiveAPIRequestReturnType returnType;
@property (assign, nonatomic) NSTimeInterval timeoutInterval;
@property (weak, nonatomic) NSObject<ApptentiveAPIRequestDelegate> *delegate;

- (id)initWithConnection:(ApptentiveURLConnection *)connection channelName:(NSString *)channelName;
- (void)start;
- (void)cancel;
- (void)showAlert;

@end
