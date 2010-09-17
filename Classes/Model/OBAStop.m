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

#import "OBAStop.h"

#import "OBARoute.h"
#import "OBAStopAccessEvent.h"
#import "OBAStopPreferences.h"
#import "OBABookmark.h"

@implementation OBAStop 

@dynamic latitude;
@dynamic name;
@dynamic code;
@dynamic direction;
@dynamic stopId;
@dynamic longitude;
@dynamic routes;
@dynamic accessEvents;
@dynamic preferences;
@dynamic bookmarks;

- (double) lat {
	return [self.latitude doubleValue];
}

- (double) lon {
	return [self.longitude doubleValue];
}

- (NSString*) routeNamesAsString {
	
	NSMutableString * label = [NSMutableString string];
	BOOL first = TRUE;
	
	NSMutableArray * sRoutes = [NSMutableArray array];
	
	for( OBARoute * route in self.routes )
		[sRoutes addObject:route];
	
	[sRoutes sortUsingSelector:@selector(compareUsingName:)];
	
	for( OBARoute * route in sRoutes ) {
		
		if( first )
			first = FALSE;
		else
			[label  appendString:@", "];
		[label appendString:[route safeShortName]];
	}
	return label;
	
}

- (NSComparisonResult) compareUsingName:(OBAStop*)aStop {
	return [self.name compare:aStop.name options:NSNumericSearch];
}

# pragma mark MKAnnotation

- (NSString*) title {
	return self.name;
}

- (NSString*) subtitle {
	return [NSString stringWithFormat:@"Routes: %@",[self routeNamesAsString]];
}

- (CLLocationCoordinate2D) coordinate {
	CLLocationCoordinate2D c = {self.lat,self.lon};
	return c;
}

@end
