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

@interface OBADataSourceConfig ()
@property(strong,readwrite) NSString* url;
@property(strong,readwrite) NSString* args;
@end

@implementation OBADataSourceConfig

- (id) initWithUrl:(NSString*)url args:(NSString*)args {
	self = [super init];
    
    if (self) {
		self.url = url;
		self.args = args;
	}
	return self;
}

- (NSURL*)constructURL:(NSString*)path withArgs:(NSString*)args includeArgs:(BOOL)includeArgs {
	NSMutableString *constructedURL = [NSMutableString string];
    
	if (self.url) {
		[constructedURL appendString:self.url];
    }
    
	[constructedURL appendString:path];
	
	if (includeArgs && (args || self.args) ) {
		[constructedURL appendString:@"?"];
		if ( _args ) {
            [constructedURL appendString:_args];
        }
			
		if (args) {
			if (self.args) {
                [constructedURL appendString:@"&"];
            }
				
			[constructedURL appendString:args];
		}
	}
	
	NSLog(@"url=%@",constructedURL);
	
	return [NSURL URLWithString:constructedURL];
}

@end
