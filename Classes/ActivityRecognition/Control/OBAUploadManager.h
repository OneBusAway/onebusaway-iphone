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

#import "OBAJsonDataSource.h"
#import "OBAPredictedArrivalsSource.h"
#import "OBADataSource.h"


@class OBAProgressIndicatorImpl;

@interface OBAUploadManager : NSObject<OBADataSourceDelegate> {
	
	OBAJsonDataSource * _jsonDataSource;
	
	NSString * _tracesOnDisk;
	NSString * _tracesOnServer;
	NSString * _tracesToUpload;

	NSMutableDictionary * _traceIds;
	NSMutableSet * _traceIdsOnServer;
	BOOL _uploading;
}

@property (nonatomic,retain) OBAJsonDataSource * jsonDataSource;

@property (nonatomic,retain) NSString * tracesOnDisk;
@property (nonatomic,retain) NSString * tracesOnServer;
@property (nonatomic,retain) NSString * tracesToUpload;

-(void) start;
-(void) stop;

-(void) startUploading;
-(void) stopUploading;

@end
