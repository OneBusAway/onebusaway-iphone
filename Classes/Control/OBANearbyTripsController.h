//
//  OBANearbyTripsController.h
//  org.onebusaway.iphone
//
//  Created by Brian Ferris on 10/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "OBAApplicationContext.h"
#import "OBAJsonDataSource.h"


@protocol OBANearbyTripsControllerDelegate <NSObject>

- (void) handleNearbyTripsControllerUpdate:(NSArray*)results;

@optional

- (void) handleNearbyTripsControllerError:(NSError*)error;

@end


@interface OBANearbyTripsController : NSObject<OBADataSourceDelegate> {
	OBAApplicationContext * _appContext;
	OBAJsonDataSource * _jsonDataSource;
	NSTimer * _timer;
	id<OBANearbyTripsControllerDelegate> _delegate;
}

@property (nonatomic,retain) id<OBANearbyTripsControllerDelegate> delegate;

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext;

- (void) start;
- (void) stop;

@end
