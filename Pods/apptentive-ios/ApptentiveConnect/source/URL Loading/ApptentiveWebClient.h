//
//  ApptentiveWebClient.h
//  apptentive-ios
//
//  Created by Andrew Wooster on 7/28/09.
//  Copyright 2009 Apptentive, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ATFeedback;
@class ApptentiveAPIRequest;

extern NSString *const ATWebClientDefaultChannelName;


@interface ApptentiveWebClient : NSObject

@property (readonly, nonatomic) NSURL *baseURL;
@property (readonly, nonatomic) NSString *APIKey;
@property (readonly, nonatomic) NSString *APIVersion;

- (instancetype)initWithBaseURL:(NSURL *)baseURL APIKey:(NSString *)APIKey;

- (NSString *)commonChannelName;
- (ApptentiveAPIRequest *)requestForGettingAppConfiguration;
@end
