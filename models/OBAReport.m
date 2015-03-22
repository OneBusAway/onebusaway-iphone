//
//  OBAReport.m
//  org.onebusaway.iphone
//
//  Created by Pho Diep on 3/21/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAReport.h"

@interface NSObject ()

@property (strong, nonatomic) NSDate *timestamp;
@property (strong, nonatomic) NSString *tripId;

@end

@implementation OBAReport

- (instancetype)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {
        self.timestamp = json[@"timestamp"];
        self.timestamp = json[@"tripId"];
        
    }
    return self;
}

-(NSDate *)timestamp {
    return self.timestamp;
}

-(NSString *)tripId {
    return self.tripId;
}

@end
