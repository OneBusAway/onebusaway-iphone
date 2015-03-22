//
//  OBAReport.h
//  org.onebusaway.iphone
//
//  Created by Pho Diep on 3/21/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OBAReport : NSObject

@property (strong, nonatomic, readonly) NSDate *timestamp;
@property (strong, nonatomic, readonly) NSString *tripId;

@end
