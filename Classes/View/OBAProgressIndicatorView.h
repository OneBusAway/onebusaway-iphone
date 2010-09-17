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

//#import <UIKit/UIKit.h>
#import "OBAProgressIndicatorSource.h"

@interface OBAProgressIndicatorView : UIView <OBAProgressIndicatorDelegate> {
	UILabel * _label;
	UILabel * _progressLabel;
	UIActivityIndicatorView * _activityIndicator;
	UIProgressView * _progressView;
	NSObject<OBAProgressIndicatorSource> * _source;
}

@property (nonatomic,retain) NSObject<OBAProgressIndicatorSource> * source;

@property (nonatomic,retain) IBOutlet UILabel * label;
@property (nonatomic,retain) IBOutlet UILabel * progressLabel;
@property (nonatomic,retain) IBOutlet UIActivityIndicatorView * activityIndicator;
@property (nonatomic,retain) IBOutlet UIProgressView * progressView;

+ (id) viewFromNibWithSource:(NSObject<OBAProgressIndicatorSource>*)source;

@end
