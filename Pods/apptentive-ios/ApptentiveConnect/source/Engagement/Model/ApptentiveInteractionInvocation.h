//
//  ApptentiveInteractionInvocation.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 12/10/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ApptentiveInteractionUsageData;


@interface ApptentiveInteractionInvocation : NSObject <NSCoding, NSCopying>

@property (copy, nonatomic) NSString *interactionID;
@property (assign, nonatomic) NSInteger priority;
@property (copy, nonatomic) NSDictionary *criteria;

+ (ApptentiveInteractionInvocation *)invocationWithJSONDictionary:(NSDictionary *)jsonDictionary;
+ (NSArray *)invocationsWithJSONArray:(NSArray *)jsonArray;

- (BOOL)isValid;

- (BOOL)criteriaAreMet;
- (BOOL)criteriaAreMetForUsageData:(ApptentiveInteractionUsageData *)usageData;

- (NSPredicate *)criteriaPredicate;

@end
