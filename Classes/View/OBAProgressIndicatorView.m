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

#import "OBAProgressIndicatorView.h"


@implementation OBAProgressIndicatorView

@synthesize label = _label;
@synthesize progressLabel = _progressLabel;
@synthesize activityIndicator = _activityIndicator;
@synthesize progressView = _progressView;

+ (id) viewFromNib {
	NSArray * nib1 = [[NSBundle mainBundle] loadNibNamed:@"OBAProgressIndicatorView" owner:nil options:nil];
	OBAProgressIndicatorView * view = [[[nib1 objectAtIndex:0] retain] autorelease];
	return view;
}

- (void)dealloc {
	[_label release];
	[_progressLabel release];
	[_activityIndicator release];
	[_progressView release];
    [super dealloc];
}

- (void) setMessage:(NSString*)message inProgress:(BOOL)inProgress progress:(float)progress {

	BOOL hasMessage = (message != nil) && ([message length] > 0);
	
	if( inProgress && hasMessage )
		_progressLabel.text = message;
	
	if( ! inProgress && hasMessage )
		_label.text = message;
	
	if( inProgress && hasMessage )
		[_activityIndicator startAnimating];
	else
		[_activityIndicator stopAnimating];
	
	_progressView.progress = progress;
	
	_label.hidden = ! (!inProgress && hasMessage);
	_progressLabel.hidden = ! (inProgress  && hasMessage);
	_activityIndicator.hidden = ! (inProgress && hasMessage);
	_progressView.hidden = ! (inProgress && ! hasMessage);
}

- (void) setInProgress:(BOOL)inProgress progress:(float)progress {
	[self setMessage:nil inProgress:inProgress progress:progress];
}

@end
