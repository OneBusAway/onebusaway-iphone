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


@interface OBAProgressIndicatorView (Private)

- (void) updateFromSource;

@end


@implementation OBAProgressIndicatorView

@synthesize label = _label;
@synthesize progressLabel = _progressLabel;
@synthesize activityIndicator = _activityIndicator;
@synthesize progressView = _progressView;

+ (id) viewFromNibWithSource:(NSObject<OBAProgressIndicatorSource>*)source {
	NSArray * nib1 = [[NSBundle mainBundle] loadNibNamed:@"OBAProgressIndicatorView" owner:source options:nil];
	OBAProgressIndicatorView * view = [[nib1 objectAtIndex:0] retain];
	[view setSource:source];
	return view;
}

- (void)dealloc {
	[self setSource:nil];
	[_label release];
	[_progressLabel release];
	[_activityIndicator release];
	[_progressView release];
    [super dealloc];
}

- (NSObject<OBAProgressIndicatorSource>*) source {
	return _source;
}

- (void) setSource:(NSObject<OBAProgressIndicatorSource>*)source {
	
	if( _source) {
		_source.delegate = nil;
		[_source release];
	}
	
	_source = [source retain];

	if( _source) {
		_source.delegate = self;
		[self updateFromSource];
	}
}

#pragma mark Key-Value Observation

- (void) progressUpdated {
	[self updateFromSource];
}

@end

@implementation OBAProgressIndicatorView (Private)

- (void) updateFromSource {

	if( _source ) {
		
		BOOL hasProgress = _source.inProgress;
		NSString * message = _source.message;
		BOOL hasMessage = (message != nil) && ([message length] > 0);

		if( hasProgress && hasMessage )
			_progressLabel.text = message;
		
		if( ! hasProgress && hasMessage )
			_label.text = message;
		
		if( hasProgress && hasMessage )
			[_activityIndicator startAnimating];
		else
			[_activityIndicator stopAnimating];
		
		_label.hidden = ! (!hasProgress && hasMessage);
		_progressLabel.hidden = ! (hasProgress  && hasMessage);
		_activityIndicator.hidden = ! (hasProgress && hasMessage);
		_progressView.hidden = ! (hasProgress && ! hasMessage);
	}
	else {
		[_activityIndicator stopAnimating];
		_label.hidden = TRUE;
		_progressLabel.hidden = TRUE;
		_progressView.hidden = TRUE;
	}
}

@end

