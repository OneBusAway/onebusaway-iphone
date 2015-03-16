//
//  OBAFrequencyV2.h
//  org.onebusaway.iphone
//
//  Created by Brian Ferris on 11/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface OBAFrequencyV2 : NSObject

@property (nonatomic) long long startTime;
@property (nonatomic) long long endTime;
@property (nonatomic) int headway;

@end
