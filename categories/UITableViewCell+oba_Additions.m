//
//  UITableViewCell+oba_Additions.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/11/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "UITableViewCell+oba_Additions.h"
#import "OBAServiceAlertsModel.h"

@implementation UITableViewCell (oba_Additions)

+ (UITableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView cellId:(NSString*)cellId {

    // Try to retrieve from the table view a now-unused cell with the given identifier
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];

    // If no cell is available, create a new one using the given identifier
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }

    return cell;
}

+ (UITableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView {
    static NSString *cellId = @"DefaultIdentifier";
    return [self getOrCreateCellForTableView:tableView cellId:cellId];
}

+ (UITableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView style:(UITableViewCellStyle)style {
    NSString * cellId = [NSString stringWithFormat:@"DefaultIdentifier-%@",@(style)];
    return [self getOrCreateCellForTableView:tableView style:style cellId:cellId];
}

+ (UITableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView style:(UITableViewCellStyle)style cellId:(NSString*)cellId {

    // Try to retrieve from the table view a now-unused cell with the given identifier
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];

    // If no cell is available, create a new one using the given identifier
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:cellId];

    return cell;
}

+ (UITableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView fromResource:(NSString*)resourceName {

    UITableViewCell * cell = (UITableViewCell*) [tableView dequeueReusableCellWithIdentifier:resourceName];

    if (cell == nil) {
        NSArray * nib = [[NSBundle mainBundle] loadNibNamed:resourceName owner:self options:nil];
        cell = nib[0];
    }

    return cell;
}

+ (UITableViewCell*) tableViewCellForUnreadServiceAlerts:(OBAServiceAlertsModel*)serviceAlerts tableView:(UITableView*)tableView {

    static NSString *cellId = @"UnreadServiceAlertsCell";

    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:cellId];
    cell.textLabel.text = [NSString stringWithFormat:@"Service alerts: %lu unread",(unsigned long)serviceAlerts.unreadCount];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    NSString * maxSeverity = serviceAlerts.unreadMaxSeverity;

    if( maxSeverity && [maxSeverity isEqualToString:@"noImpact"] )
        cell.imageView.image = [UIImage imageNamed:@"Alert-Info"];
    else
        cell.imageView.image = [UIImage imageNamed:@"Alert"];

    return cell;
}

+ (UITableViewCell*) tableViewCellForServiceAlerts:(OBAServiceAlertsModel*)serviceAlerts tableView:(UITableView*)tableView {

    static NSString *cellId = @"ServiceAlertsCell";
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:cellId];
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    if (serviceAlerts.totalCount == 0) {
        cell.textLabel.text = @"Service Alerts";
    }
    else {
        cell.textLabel.text = [NSString stringWithFormat:@"Service Alerts: %lu total", (unsigned long)serviceAlerts.totalCount];
    }

    if (serviceAlerts.totalCount == 0) {
        cell.imageView.image = nil;
    }
    else if ( serviceAlerts.unreadCount > 0 ) {
        NSString *imageName = [serviceAlerts.unreadMaxSeverity isEqual:@"noImpact"] ? @"Alert-Info" : @"Alert";
        cell.imageView.image = [UIImage imageNamed:imageName];
    }
    else {
        NSString *imageName = [serviceAlerts.maxSeverity isEqual:@"noImpact"] ? @"Alert-Info-Grayscale" : @"AlertGrayscale";
        cell.imageView.image = [UIImage imageNamed:imageName];
    }

    return cell;
}


@end
