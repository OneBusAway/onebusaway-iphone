//
//  ApptentiveConversation.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/4/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ApptentiveJSONModel.h"


@interface ApptentiveConversation : NSObject <NSCoding, ApptentiveJSONModel>
@property (copy, nonatomic) NSString *token;
@property (copy, nonatomic) NSString *personID;
@property (copy, nonatomic) NSString *deviceID;

- (NSDictionary *)apiUpdateJSON;
@end
