//
//  OBAStopOptionsViewController.h
//  org.onebusaway.iphone
//
//  Created by Brian Ferris on 8/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "OBAApplicationContext.h"
#import "OBAStop.h"

@interface OBAStopOptionsViewController : UITableViewController {
	OBAApplicationContext * _appContext;
	OBAStop * _stop;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext stop:(OBAStop*)stop;

@end
