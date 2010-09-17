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

//#import <UIKit/UIKit.h>
#import "OBAApplicationContext.h"
#import "OBANavigationTargetAware.h"


@interface OBALockViewController : UIViewController <OBANavigationTargetAware> {
	
	OBAApplicationContext * _appContext;
	
	NSArray * _key;
	int _keyIndex;
	
	NSTimer * _timer;
	
	UIButton * _button0;
	UIButton * _button1;
	UIButton * _button2;
	UIButton * _button3;
	UIButton * _button4;
	UIButton * _button5;
	UIButton * _button6;
	UIButton * _button7;
	UIButton * _button8;
	UIButton * _button9;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext;

@property (nonatomic,retain) IBOutlet UIButton * button0;
@property (nonatomic,retain) IBOutlet UIButton * button1;
@property (nonatomic,retain) IBOutlet UIButton * button2;
@property (nonatomic,retain) IBOutlet UIButton * button3;
@property (nonatomic,retain) IBOutlet UIButton * button4;
@property (nonatomic,retain) IBOutlet UIButton * button5;
@property (nonatomic,retain) IBOutlet UIButton * button6;
@property (nonatomic,retain) IBOutlet UIButton * button7;
@property (nonatomic,retain) IBOutlet UIButton * button8;
@property (nonatomic,retain) IBOutlet UIButton * button9;

-(IBAction) onButtonClick:(id)source;

@end
