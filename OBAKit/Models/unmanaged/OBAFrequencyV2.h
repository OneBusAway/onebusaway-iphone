//
//  OBAFrequencyV2.h
//  org.onebusaway.iphone
//
//  Created by Brian Ferris on 11/13/10.
//  Copyright 2010 OneBusAway. All rights reserved.
//

@import Foundation;
NS_ASSUME_NONNULL_BEGIN

@interface OBAFrequencyV2 : NSObject

@property (nonatomic) long long startTime;
@property (nonatomic) long long endTime;
@property (nonatomic) int headway;

@end

NS_ASSUME_NONNULL_END
