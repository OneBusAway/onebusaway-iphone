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
@end

NS_ASSUME_NONNULL_END
