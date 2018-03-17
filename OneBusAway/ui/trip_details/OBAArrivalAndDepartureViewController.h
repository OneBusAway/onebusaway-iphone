//
//  OBAArrivalAndDepartureViewController.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/18/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import OBAKit;

@interface OBAArrivalAndDepartureViewController : OBAStaticTableViewController
@property(nonatomic,strong) OBAModelDAO *modelDAO;
@property(nonatomic,strong) PromisedModelService *modelService;

- (instancetype)initWithArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture;
- (instancetype)initWithTripInstance:(OBATripInstanceRef *)tripInstance;

// Implementation weirdness explanation: NSObject implements -copy, not NSCopying :(
- (instancetype)initWithArrivalAndDepartureConvertible:(NSObject<OBAArrivalAndDepartureConvertible,NSCopying>*)convertible;

@end
