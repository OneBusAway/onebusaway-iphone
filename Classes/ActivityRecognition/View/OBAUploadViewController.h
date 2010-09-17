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

#import "OBAApplicationContext.h"
#import "OBANavigationTargetAware.h"
#import "OBAUploadManager.h"

@interface OBAUploadViewController : UIViewController <OBANavigationTargetAware> {

	OBAUploadManager * _uploadManager;
	
	UILabel * _tracesOnDiskLabel;
	UILabel * _tracesOnServerLabel;
	UILabel * _tracesToUploadLabel;
}

@property (nonatomic,retain) IBOutlet UILabel * tracesOnDiskLabel;
@property (nonatomic,retain) IBOutlet UILabel * tracesOnServerLabel;
@property (nonatomic,retain) IBOutlet UILabel * tracesToUploadLabel;

-(id) initWithApplicationContext:(OBAApplicationContext*)appContext;

-(IBAction)onUploadButton:(id)source;

@end
