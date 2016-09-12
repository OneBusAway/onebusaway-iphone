//
//  ApptentiveLegacyRecord.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 1/10/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ApptentiveAPIRequest;


@interface ApptentiveLegacyRecord : NSObject <NSCoding>
@property (copy, nonatomic) NSString *uuid;
@property (copy, nonatomic) NSString *model;
@property (copy, nonatomic) NSString *os_version;
@property (copy, nonatomic) NSString *carrier;
@property (strong, nonatomic) NSDate *date;

- (NSString *)formattedDate:(NSDate *)aDate;

- (NSDictionary *)apiJSON;
- (NSDictionary *)apiDictionary;
- (ApptentiveAPIRequest *)requestForSendingRecord;
/*! Called when we're done using this record. */
- (void)cleanup;
@end
