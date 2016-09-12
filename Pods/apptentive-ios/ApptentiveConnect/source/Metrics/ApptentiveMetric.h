//
//  ApptentiveMetric.h
//  ApptentiveMetrics
//
//  Created by Andrew Wooster on 12/27/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ApptentiveLegacyRecord.h"


@interface ApptentiveMetric : ApptentiveLegacyRecord <NSCoding>
@property (copy, nonatomic) NSString *name;
@property (readonly, nonatomic) NSDictionary *info;

- (void)setValue:(id)value forKey:(NSString *)key;
- (void)addEntriesFromDictionary:(NSDictionary *)dictionary;
@end
