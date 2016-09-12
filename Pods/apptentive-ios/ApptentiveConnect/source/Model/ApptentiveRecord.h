//
//  ApptentiveRecord.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/13/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "ApptentiveJSONModel.h"


@interface ApptentiveRecord : NSManagedObject <ApptentiveJSONModel>

@property (copy, nonatomic) NSString *apptentiveID;
@property (strong, nonatomic) NSNumber *creationTime;
@property (strong, nonatomic) NSNumber *clientCreationTime;
@property (copy, nonatomic) NSString *clientCreationTimezone;
@property (strong, nonatomic) NSNumber *clientCreationUTCOffset;

- (void)setup;
- (void)updateClientCreationTime;
- (BOOL)isClientCreationTimeEmpty;
- (BOOL)isCreationTimeEmpty;

@end
