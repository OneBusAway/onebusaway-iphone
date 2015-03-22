//
//  OBAReport.h
//  org.onebusaway.iphone
//
//  Created by Vania Kurniawati on 3/21/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OBAReport : NSObject

@property (nonatomic, strong) NSString *reportID; //unique ID from the API?
@property (nonatomic, strong) NSString *status; //whether bus is full
@property (nonatomic, strong) NSString *busID;
@property (nonatomic, strong) CLLocation *userLocation;
@property (nonatomic, strong) NSString *tripID;
@property (nonatomic, strong) NSString *user;

- (void)initWithName:(NSString*) user; //creates a new report with the input user

- (void)validateReport:(NSString*) reportID;

@end
