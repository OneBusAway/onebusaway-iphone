//
//  ApptentivePersonInfo.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const ATCurrentPersonPreferenceKey;


@interface ApptentivePersonInfo : NSObject <NSCoding>
@property (readonly, nonatomic) NSString *apptentiveID;
@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *emailAddress;

@property (readonly, nonatomic) NSDictionary *dictionaryRepresentation;

+ (ApptentivePersonInfo *)currentPerson;

/** If json is nil will not create a new person and will return nil. */
+ (ApptentivePersonInfo *)newPersonFromJSON:(NSDictionary *)json;

- (NSDictionary *)apiJSON;

@end
