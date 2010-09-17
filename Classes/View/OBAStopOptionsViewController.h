//
//  OBAStopOptionsViewController.h
//  org.onebusaway.iphone
//
//  Created by Brian Ferris on 8/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "OBAApplicationContext.h"
#import "OBAStopV2.h"

@interface OBAStopOptionsViewController : UITableViewController {
	OBAApplicationContext * _appContext;
	OBAStopV2 * _stop;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext stop:(OBAStopV2*)stop;

@end
