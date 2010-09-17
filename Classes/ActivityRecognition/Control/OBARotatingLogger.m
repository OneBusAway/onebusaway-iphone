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

#import "OBARotatingLogger.h"


@implementation OBARotatingLogger

@synthesize path = _path;

-(id) initWithDirectory:(NSString*)path withMaxFileSize:(NSUInteger)maxFileSize {
	if( self = [super init] ) {
		
		_path = [path retain];
		_maxFileSize = maxFileSize;
		
		_currentOutputStream = nil;
		_currentOutputSize = 0;
		
		[self ensureParentDirectoryExists];		
	}
	return self;
}

-(void) dealloc {
	[_currentOutputStream release];
	[super dealloc];
}

-(NSArray*) individualTracePaths {
	NSFileManager * manager = [NSFileManager defaultManager];
	NSMutableArray * paths = [NSMutableArray arrayWithCapacity:0];
	for( NSString * trace in [manager contentsOfDirectoryAtPath:_path error:NULL] )
		[paths addObject:[NSString stringWithFormat:@"%@/%@",_path,trace]];
	return paths;
}

-(void) open {

}

-(void) close {
	[_currentOutputStream close];
	[_currentOutputStream release];
	_currentOutputStream = nil;
}

-(void) write:(NSString*)stringData {
	
	[self ensureCurrentOutput];
	
	if( _currentOutputStream ) {

		NSData * data = [[stringData dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] retain];
		NSUInteger remaining = [data length];
		
		while( remaining > 0 ) {
			NSRange range = NSMakeRange([data length] - remaining, remaining);
			NSData * sub = [data subdataWithRange:range];
			NSInteger rc = [_currentOutputStream write:[sub bytes] maxLength:[sub length]];
			if( rc < 0 )
				break;
			remaining -= rc;
		}
		
		_currentOutputSize += [data length] - remaining;
		[data release];
	}
}
			
-(BOOL) ensureParentDirectoryExists {
	
	NSFileManager * manager = [NSFileManager defaultManager];
	BOOL isDirectory;
	
	if( [manager fileExistsAtPath:_path isDirectory:&isDirectory] ) {
		if( isDirectory )
			return TRUE;
		NSLog(@"Target directory already exists as file, will attempt to delete file and create directory: %@",_path);
		
		NSError * error;
		if( ! [manager removeItemAtPath:_path error:&error] ) {
			NSLog(@"Error deleting file: %@ - %@",_path,[error localizedDescription]);
			return FALSE;
		}
	}

	if( [manager createDirectoryAtPath:_path withIntermediateDirectories:FALSE attributes:nil error:NULL] )
		return TRUE;
		
	NSLog(@"Error creating directory: %@",_path);
	return FALSE;
}

-(BOOL) ensureCurrentOutput {
	
	if( ! _currentOutputStream || _currentOutputSize >= _maxFileSize ) {
		
		[_currentOutputStream close];
		[_currentOutputStream release];
		_currentOutputStream = nil;
		
		NSDate * date = [NSDate date];
		NSString * currentPath = [NSString stringWithFormat:@"%@/%f.data",_path,[date timeIntervalSince1970]];
		
		_currentOutputStream = [[NSOutputStream alloc] initToFileAtPath:currentPath append:YES];
		_currentOutputSize = 0;

		[_currentOutputStream open];
	}
	
	return TRUE;
}

@end
