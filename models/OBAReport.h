//
//  OBAReport.h
//  org.onebusaway.iphone
//
//  Created by Pho Diep on 3/21/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OBAReport : NSObject

@property (strong, nonatomic) NSString *reportId;
@property (strong, nonatomic) NSDate *timestamp;
@property (strong, nonatomic) NSString *tripId;
@property (nonatomic) NSInteger reportType;
@property (nonatomic) BOOL fullBus;


@end
