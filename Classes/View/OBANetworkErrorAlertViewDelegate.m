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

#import "OBANetworkErrorAlertViewDelegate.h"


@implementation OBANetworkErrorAlertViewDelegate

- (id) initWithContext:(OBAApplicationContext*)context {
	if( self = [super init] ) {
		_context = [context retain];
	}
	return self;
}

- (void) dealloc {
	[_context release];
	[super dealloc];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if( buttonIndex == 0 )
		[_context navigateToTarget:[OBANavigationTarget target:OBANavigationTargetTypeContactUs]];
}

@end
