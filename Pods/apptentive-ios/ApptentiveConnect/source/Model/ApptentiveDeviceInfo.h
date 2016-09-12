//
//  ApptentiveDeviceInfo.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ApptentiveDeviceInfo : NSObject
@property (readonly, nonatomic) NSDictionary *dictionaryRepresentation;

+ (NSString *)carrier;

- (NSDictionary *)apiJSON;
@end
