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


typedef enum {
	OBAArrivalEntryTableViewCellAlertStyleNone,
	OBAArrivalEntryTableViewCellAlertStyleInactive,
	OBAArrivalEntryTableViewCellAlertStyleActive
}
OBAArrivalEntryTableViewCellAlertStyle;

@interface OBAArrivalEntryTableViewCell : UITableViewCell {
	UILabel * _routeLabel;
	UIView * _labelsView;
	UILabel * _destinationLabel;
	UILabel * _statusLabel;
	UILabel * _minutesLabel;
	UILabel * _minutesSubLabel;
	UIImageView * _unreadAlertImage;
	UIImageView * _alertImage;
	OBAArrivalEntryTableViewCellAlertStyle _alertStyle;
	NSTimer * _transitionTimer;
}

@property (nonatomic, retain) IBOutlet UILabel * routeLabel;
@property (nonatomic, retain) IBOutlet UIView * labelsView;
@property (nonatomic, retain) IBOutlet UILabel * destinationLabel;
@property (nonatomic, retain) IBOutlet UILabel * statusLabel;
@property (nonatomic, retain) IBOutlet UILabel * minutesLabel;
@property (nonatomic, retain) IBOutlet UILabel * minutesSubLabel;
@property (nonatomic, retain) IBOutlet UIImageView * unreadAlertImage;
@property (nonatomic, retain) IBOutlet UIImageView * alertImage;

@property (nonatomic) OBAArrivalEntryTableViewCellAlertStyle alertStyle;

+ (OBAArrivalEntryTableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView;

@end
