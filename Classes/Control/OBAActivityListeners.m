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

#import "OBAActivityListeners.h"


@interface OBAActivityListeners (Private)

- (void) fireListenerEvent:(SEL)aSelector withObject:(id)object1;

@end


@implementation OBAActivityListeners

- (id) init {
	if( self = [super init]) {
		_listeners = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc {
	[_listeners release];
	[super dealloc];
}

- (void) addListener:(NSObject<OBAActivityListener,NSObject>*)listener {
	@synchronized(self) {
		[_listeners addObject:listener];
	}
}

- (void) removeListener:(NSObject<OBAActivityListener,NSObject>*)listener {
	@synchronized(self) {
		[_listeners removeObject:listener];
	}
}

#pragma mark OBAActivityListener Methods

- (void) bookmarkClicked:(OBABookmarkV2*)bookmark {
	[self fireListenerEvent:@selector(bookmarkClicked:) withObject:bookmark];
}

- (void) placemark:(OBAPlacemark*)placemark {
	[self fireListenerEvent:@selector(placemark:) withObject:placemark];
}

- (void) viewedArrivalsAndDeparturesForStop:(OBAStopV2*)stop {
	[self fireListenerEvent:@selector(viewedArrivalsAndDeparturesForStop:) withObject:stop];
}

- (void) annotationWithLabel:(NSString*)label {
	[self fireListenerEvent:@selector(annotationWithLabel:) withObject:label];
}

- (void) nearbyTrips:(NSArray*)nearbyTrips {
	[self fireListenerEvent:@selector(nearbyTrips:) withObject:nearbyTrips];
}

	
@end

@implementation OBAActivityListeners (Private)

- (void) fireListenerEvent:(SEL)aSelector withObject:(id)object1 {
	@synchronized(self) {
		for( id<OBAActivityListener,NSObject> listener in _listeners ) {
			if( [listener respondsToSelector:aSelector] )
				[listener performSelector:aSelector withObject:object1];
		}
	}	
}

@end

