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

#import "OBADataSourceConfig.h"


@implementation OBADataSourceConfig

@synthesize url = _url;
@synthesize args = _args;

- (id) initWithUrl:(NSString*)url args:(NSString*)args {
	if( self = [super init] ) {
		_url = [url retain];
		_args = [args retain];
	}
	return self;
}

- (void) dealloc {
	[_url release];
	[_args  release];
	[super dealloc];
}

-(NSURL*) constructURL:(NSString*)path withArgs:(NSString*)args includeArgs:(BOOL)includeArgs {
	
	NSMutableString *url = [NSMutableString string];
	if( _url )
		[url appendString: _url];
	[url appendString:path];
	
	if( includeArgs && (args || _args) ) {
		[url appendString:@"?"];
		if( _args )
			[url appendString:_args];
		if( args ) {
			if( _args )
				[url appendString:@"&"];
			[url appendString:args];
		}
	}
	
	NSLog(@"url=%@",url);
	
	return [NSURL URLWithString:url];
}

@end
