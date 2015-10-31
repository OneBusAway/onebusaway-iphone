//
//  UITableViewCell+oba_Additions.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/11/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OBAServiceAlertsModel;

NS_ASSUME_NONNULL_BEGIN

@interface UITableViewCell (oba_Additions)
+ (UITableViewCell*)getOrCreateCellForTableView:(UITableView*)tableView cellId:(NSString*)cellId;
+ (UITableViewCell*)getOrCreateCellForTableView:(UITableView*)tableView;
+ (UITableViewCell*)getOrCreateCellForTableView:(UITableView*)tableView style:(UITableViewCellStyle)style;
+ (UITableViewCell*)getOrCreateCellForTableView:(UITableView*)tableView style:(UITableViewCellStyle)style cellId:(NSString*)cellId;
+ (UITableViewCell*)getOrCreateCellForTableView:(UITableView*)tableView fromResource:(NSString*)resourceName;

// TODO - move these somewhere, ANYWHERE, but here.
+ (UITableViewCell*) tableViewCellForUnreadServiceAlerts:(OBAServiceAlertsModel*)serviceAlerts tableView:(UITableView*)tableView;
+ (UITableViewCell*) tableViewCellForServiceAlerts:(OBAServiceAlertsModel*)serviceAlerts tableView:(UITableView*)tableView;
@end

NS_ASSUME_NONNULL_END