/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OBALockViewController.h"

static const int kKeyLength = 4;
static const double kKeyTimeout = 3.0;

@interface OBALockViewController(Private)

-(void) refreshButtons;
-(UIButton*) getButtonForIndex:(int)index;

@end


@implementation OBALockViewController

@synthesize button0 = _button0;
@synthesize button1 = _button1;
@synthesize button2 = _button2;
@synthesize button3 = _button3;
@synthesize button4 = _button4;
@synthesize button5 = _button5;
@synthesize button6 = _button6;
@synthesize button7 = _button7;
@synthesize button8 = _button8;
@synthesize button9 = _button9;

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext {
    if (self = [super initWithNibName:@"OBALockView" bundle:nil]) {
		self.hidesBottomBarWhenPushed = TRUE;
		self.navigationItem.title = @"Lock Screen";
		self.navigationItem.hidesBackButton = TRUE;
		_appContext = [appContext retain];
    }
    return self;
}


- (void)dealloc {
	[_appContext release];
	[_key release];
	[_timer release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
	
	[_appContext.activityListeners annotationWithLabel:@"lockOn"];
	
	UIApplication * application = [UIApplication sharedApplication];
	application.idleTimerDisabled = TRUE;
	
	NSMutableArray * key = [[NSMutableArray alloc] initWithCapacity:kKeyLength];
	
	for( int i=0; i<kKeyLength;i++) {

		while(TRUE) {
			
			int keyDigit = arc4random() % 10;

			// No sequential duplicates
			if( i > 0 ) { 				
				NSNumber * prev = [key objectAtIndex:i-1];
				if( [prev intValue] == keyDigit )
					continue;
			}
			
			NSNumber * n = [NSNumber numberWithInt: keyDigit];
			[key addObject:n];
			break;
		}
	}
	_key = key;
	_keyIndex = 0;
	
	[self refreshButtons];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	
	UIApplication * application = [UIApplication sharedApplication];
	application.idleTimerDisabled = FALSE;
}



- (void) timerFireMethod:(NSTimer*)theTimer {
	@synchronized(self) {
		_keyIndex = 0;
		[self refreshButtons];
	}
}

-(IBAction) onButtonClick:(id)source {
	
	@synchronized(self) {
		UIButton * button = source;
		int index = [button.titleLabel.text intValue];
		
		NSNumber * target = [_key objectAtIndex:_keyIndex];
		
		if( _timer ) {
			[_timer invalidate];
			[_timer release];
			_timer = nil;
		}
		
		if( [target intValue] == index ) {
			_keyIndex++;
			if( _keyIndex == [_key count] ) {
				[_appContext.activityListeners annotationWithLabel:@"lockOff"];
				[self.navigationController popViewControllerAnimated:TRUE];
				return;
			}
			[self refreshButtons];
		}
		else {
			_keyIndex = 0;
			[self refreshButtons];
		}
	}
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget*) navigationTarget {
	return [OBANavigationTarget target:OBANavigationTargetTypeActivityLock];
}

@end

@implementation OBALockViewController(Private)

-(void) refreshButtons {
	
	int highlightedButton = -1;
	
	if( _keyIndex < [_key count] ) {
		NSNumber * num = [_key objectAtIndex:_keyIndex];
		highlightedButton = [num intValue];
	}
	
	for( int i=0; i<10; i++) {
		UIButton * button = [self getButtonForIndex:i];
		UIColor * color = (i == highlightedButton ) ? [UIColor greenColor] : [UIColor blackColor];
		button.titleLabel.textColor = color;
	}
	
	if( _timer ) {
		[_timer invalidate];
		[_timer release];
	}
	
	_timer = [NSTimer scheduledTimerWithTimeInterval:kKeyTimeout target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:FALSE];
	[_timer retain];
}

-(UIButton*) getButtonForIndex:(int)index {
	switch (index) {
		case 0:
			return _button0;
		case 1:
			return _button1;
		case 2:
			return _button2;
		case 3:
			return _button3;
		case 4:
			return _button4;
		case 5:
			return _button5;
		case 6:
			return _button6;
		case 7:
			return _button7;
		case 8:
			return _button8;
		case 9:
			return _button9;
		default:
			return nil;
	}
	
	return nil;
}


@end
