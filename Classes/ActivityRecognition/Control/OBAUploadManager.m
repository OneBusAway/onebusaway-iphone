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

#import "OBACommon.h"
#import "OBAUploadManager.h"
#import "OBAActivityLogger.h"
#import "OBAProgressIndicatorImpl.h"


@interface OBAUploadManager(InternalMethods)
- (void) updateServerStatus;
- (void) handleServerStatus:(NSDictionary*)dict;
- (void) uploadNextTrace;
@end



@implementation OBAUploadManager

@synthesize jsonDataSource = _jsonDataSource;

@synthesize tracesOnDisk = _tracesOnDisk;
@synthesize tracesOnServer = _tracesOnServer;
@synthesize tracesToUpload = _tracesToUpload;

@synthesize progress = _progress;

-(id) init {
	if( self = [super init]) {
		_traceIds = [[NSMutableDictionary alloc] init];
		_traceIdsOnServer = [[NSMutableSet alloc] init];
		_uploading = NO;
		_progress = [[OBAProgressIndicatorImpl alloc] init];
	}
	return self;
}

-(void) dealloc {
	[_jsonDataSource release];
	
	[_traceIds release];
	[_traceIdsOnServer release];
	
	[_tracesOnDisk release];
	[_tracesOnServer release];
	[_tracesToUpload release];
	
	[_progress release];
	
	[super dealloc];
}

-(void) start {
	
	OBAActivityLogger * logger = [OBAActivityLogger getLogger];
	[logger stop];
	
	NSArray * paths = [logger getLogFilePaths];
	
	[_traceIds removeAllObjects];	
	
	float totalFileSize = 0;		
	UIDevice * device = [UIDevice currentDevice];
	NSFileManager * fileManager = [NSFileManager defaultManager];
	
	for( NSString * path in paths ) {
		
		NSArray * components = [path componentsSeparatedByString:@"/"];		
		NSUInteger n = [components count];
		
		if( n >= 2 ) {
			
			NSString * traceId = [NSString stringWithFormat:@"%@-%@-%@",device.uniqueIdentifier,[components objectAtIndex:n-2],[components objectAtIndex:n-1]];
			[_traceIds setObject:path forKey:traceId];
			
			NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:path error:NULL];
			if( fileAttributes ) {
				NSNumber *fileSize = [fileAttributes objectForKey:NSFileSize];
				if( fileSize )
					totalFileSize += [fileSize floatValue];
			}
		}
	}
	
	NSString * label = @"bytes";
	
	if( totalFileSize >= 1024) {
		totalFileSize /= 1024;
		label = @"KB";
	}
	
	if( totalFileSize >= 1024) {
		totalFileSize /= 1024;
		label = @"MB";
	}
	
	self.tracesOnDisk = [NSString stringWithFormat:@"%d - %0.1f %@",[_traceIds count],totalFileSize,label]; 
	
	[self updateServerStatus];
}

-(void) stop {
	OBAActivityLogger * logger = [OBAActivityLogger getLogger];
	[logger start];
}

- (void)connectionDidFinishLoading:(id<OBADataSourceConnection>)connection withObject:(id) obj context:(id)context{
	
	if( [@"upload" isEqual:context] ) {
		[self uploadNextTrace];
	}
	else if( [@"checkServer" isEqual:context] ) {
		[self handleServerStatus:obj];
	}
}

- (void)connection:(id<OBADataSourceConnection>)connection withProgress:(float)progress {
	[_progress setInProgress:TRUE progress:progress];
}

- (void)connectionDidFail:(id<OBADataSourceConnection>)connection withError:(NSError *)error context:(id)context{
	NSLog(@"connection error: %@",[error localizedDescription]);
	[_progress setMessage:@"Error connecting" inProgress:FALSE progress:0];
}

-(void) startUploading {
	_uploading = YES;
	[self uploadNextTrace];
}

-(void) stopUploading {
	
}

@end

@implementation OBAUploadManager(InternalMethods)

-(void) updateServerStatus {
	[_progress setMessage:@"Connecting..." inProgress:TRUE progress:0];
	[_jsonDataSource requestWithPath:@"/api/datacollection/existing-data.json" withDelegate:self context:@"checkServer"];
}


- (void) handleServerStatus:(NSDictionary*)dict {
	NSNumber * code = [dict objectForKey:@"code"];
	if( code && [code intValue] == 200) {
		NSArray * data = [dict objectForKey:@"data"];
		NSUInteger onServer = 0;
		[_traceIdsOnServer removeAllObjects];
		for( NSString * traceId in data ) {
			if( [_traceIds objectForKey:traceId] ) {
				onServer++;
				[_traceIdsOnServer addObject:traceId];
			}
		}
		
		self.tracesOnServer = [NSString stringWithFormat:@"%d",onServer];
		self.tracesToUpload = [NSString stringWithFormat:@"%d",[_traceIds count]-onServer];
		
		NSString * message = [NSString stringWithFormat:@"Updated: %@", [OBACommon getTimeAsString]];
		[_progress setMessage:message inProgress:FALSE progress:0];
	}
	
}

-(void) uploadNextTrace {
	if( [_traceIds count] > 0 ) {
		
		self.tracesOnServer = [NSString stringWithFormat:@"%d",[_traceIdsOnServer count]];
		
		NSArray * keys = [_traceIds allKeys];
		for( NSString * traceId in keys ) {
			if( [_traceIdsOnServer containsObject:traceId] )
				continue;
			[_traceIdsOnServer addObject:traceId];
			
			NSString * url = [NSString stringWithFormat:@"/api/datacollection/upload-data/%@/update",traceId];
			NSString * filePath = [_traceIds objectForKey:traceId];
			
			[_progress setMessage:@"Uploading..." inProgress:TRUE progress:0];
			[_jsonDataSource requestWithPath:url withArgs:nil withFileUpload:filePath withDelegate:self context:@"upload"];
			return;
		}
	}
	_uploading = NO;
	[self updateServerStatus];
}

@end
