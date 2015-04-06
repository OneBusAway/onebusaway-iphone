//
//  OBAModelObjectWK.h
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/10/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OBAModelObjectWK : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSArray *)dictionaryRepresentationKeys;
- (NSDictionary *)dictionaryRepresentation;

@end
