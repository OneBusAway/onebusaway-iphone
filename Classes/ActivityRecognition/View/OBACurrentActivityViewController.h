//
//  OBACurrentActivityViewController.h
//  org.onebusaway.iphone
//
//  Created by Brian Ferris on 10/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "OBAApplicationContext.h"

@interface OBACurrentActivityViewController : UITableViewController <OBAActivityListener> {
	OBAApplicationContext * _appContext;
	NSArray * _nearbyTrips;
}

-(id) initWithApplicationContext:(OBAApplicationContext*)appContext;

@end
