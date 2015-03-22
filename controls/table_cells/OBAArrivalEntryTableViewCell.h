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

#import "MCSwipeTableViewCell.h"
#import "OBAProblemReport.h"

typedef NS_ENUM(NSInteger, OBAArrivalEntryTableViewCellAlertStyle) {
    OBAArrivalEntryTableViewCellAlertStyleNone,
    OBAArrivalEntryTableViewCellAlertStyleInactive,
    OBAArrivalEntryTableViewCellAlertStyleActive
};

@interface OBAArrivalEntryTableViewCell : MCSwipeTableViewCell {
    OBAArrivalEntryTableViewCellAlertStyle _alertStyle;
    NSTimer * _transitionTimer;
}

@property (nonatomic, strong) IBOutlet UILabel * routeLabel;
@property (nonatomic, strong) IBOutlet UIView * labelsView;
@property (nonatomic, strong) IBOutlet UILabel * destinationLabel;
@property (nonatomic, strong) IBOutlet UILabel * statusLabel;
@property (nonatomic, strong) IBOutlet UILabel * minutesLabel;
@property (nonatomic, strong) IBOutlet UILabel * minutesSubLabel;
@property (nonatomic, strong) IBOutlet UIImageView * unreadAlertImage;
@property (nonatomic, strong) IBOutlet UIImageView * alertImage;
@property (nonatomic, strong) IBOutlet UILabel * alertLabel;
@property (nonatomic, strong) IBOutlet UILabel * alertTextLabel;
@property (nonatomic, strong) IBOutlet UIImageView * alertRedImage;

@property (nonatomic, assign) OBAProblemReportType problemReportType;
@property (nonatomic, assign) NSInteger numberOfReports;

@property (nonatomic) OBAArrivalEntryTableViewCellAlertStyle alertStyle;

+ (OBAArrivalEntryTableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView;

@end
