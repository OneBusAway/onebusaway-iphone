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

#import "OBAArrivalEntryTableViewCell.h"

@interface OBAArrivalEntryTableViewCell (Private)

- (void) cancelTimer;

@end


@implementation OBAArrivalEntryTableViewCell

@synthesize routeLabel = _routeLabel;
@synthesize labelsView = _labelsView;
@synthesize destinationLabel = _destinationLabel;
@synthesize statusLabel = _statusLabel;
@synthesize minutesLabel = _minutesLabel;
@synthesize minutesSubLabel = _minutesSubLabel;
@synthesize unreadAlertImage = _unreadAlertImage;
@synthesize alertImage = _alertImage;

+ (OBAArrivalEntryTableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView {
	
	static NSString *cellId = @"OBAArrivalEntryTableViewCell";
	
	// Try to retrieve from the table view a now-unused cell with the given identifier
	OBAArrivalEntryTableViewCell *cell = (OBAArrivalEntryTableViewCell *) [tableView dequeueReusableCellWithIdentifier:cellId];
	
	// If no cell is available, create a new one using the given identifier
	if (cell == nil) {
		NSArray * nib = [[NSBundle mainBundle] loadNibNamed:cellId owner:self options:nil];
		cell = [nib objectAtIndex:0];
	}
	
	return cell;
}

- (void)dealloc {
	[self cancelTimer];
	[_routeLabel release];
	[_destinationLabel release];
	[_statusLabel release];
	[_minutesLabel release];
	[_minutesSubLabel release];
	[_alertImage release];
    [super dealloc];
}

- (OBAArrivalEntryTableViewCellAlertStyle) alertStyle {
	return _alertStyle;
}

- (void) setAlertStyle:(OBAArrivalEntryTableViewCellAlertStyle)alertStyle {
	
	if( _alertStyle == alertStyle )
		return;
	
	_alertStyle = alertStyle;

	if( _alertStyle == OBAArrivalEntryTableViewCellAlertStyleNone ) {
		[self cancelTimer];
		_unreadAlertImage.hidden = TRUE;
		_alertImage.hidden = TRUE;		
		_minutesLabel.hidden = FALSE;
	}
	else {

		_minutesLabel.alpha = 1.0;
		_unreadAlertImage.alpha = 0.0;
		_alertImage.alpha = 0.0;
		_unreadAlertImage.hidden = FALSE;
		_alertImage.hidden = FALSE;

		if( _transitionTimer == nil ) {
			_transitionTimer = [[NSTimer scheduledTimerWithTimeInterval:1.2 target:self selector:@selector(timerFired:) userInfo:nil repeats:TRUE] retain];
			
		}
	}
}

- (void)timerFired:(NSTimer*)theTimer {
	[UIView beginAnimations:nil context:nil]; {
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		[UIView setAnimationDuration:0.5];
		UIImageView * activeImage = _alertStyle == OBAArrivalEntryTableViewCellAlertStyleActive ? _unreadAlertImage : _alertImage;
		if (_minutesLabel.alpha == 0.0) {
			_minutesLabel.alpha = 1.0;
			activeImage.alpha = 0.0;
		}
		else {
			_minutesLabel.alpha = 0.0;
			activeImage.alpha = 1.0;
		}
	}[UIView commitAnimations];
}

@end

@implementation OBAArrivalEntryTableViewCell (Private)

- (void) cancelTimer {
	if ( _transitionTimer ) {
		[_transitionTimer invalidate];
		[_transitionTimer release];
		_transitionTimer = nil;
	}	
}

@end

