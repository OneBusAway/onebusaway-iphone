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

#import "OBASetNextOBAJsonDigesterRule.h"
#import "OBALogger.h"


@implementation OBASetNextOBAJsonDigesterRule

@synthesize onlyIfNotNull = _onlyIfNotNull;

- (id) initWithSelector:(SEL)selector {
	if( self = [super init] ) {
		_selector = selector;
		_onlyIfNotNull = TRUE;
	}
	return self;
}

- (void) end:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {
	
	if( _onlyIfNotNull && (value == nil || value == kCFNull) )
		return;
	
	id a = [context peek:0];
	id<NSObject> b = [context peek:1];
	
	if(context.verbose)	   
		OBALogDebug(@"setNext");
	
	if( a && b && [b respondsToSelector:_selector])
		[b performSelector:_selector withObject:a];
	else if( context.verbose )
		OBALogDebug(@"setNext selector not supported");
}

@end
