//
//  NSDictionary+Apptentive.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/8/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDictionary (Apptentive)
/*! Doesn't return NSNull objects. */
- (id)at_safeObjectForKey:(id)aKey;
@end
