//
//  OBALabelAndSwitchTableViewCell.m
//  org.onebusaway.iphone
//
//  Created by Brian Ferris on 8/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "OBALabelAndSwitchTableViewCell.h"


@implementation OBALabelAndSwitchTableViewCell

+ (OBALabelAndSwitchTableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView {
    
    static NSString *cellId = @"OBALabelAndSwitchTableViewCell";
    
    // Try to retrieve from the table view a now-unused cell with the given identifier
    OBALabelAndSwitchTableViewCell *cell = (OBALabelAndSwitchTableViewCell *) [tableView dequeueReusableCellWithIdentifier:cellId];
    
    // If no cell is available, create a new one using the given identifier
    if (cell == nil) {
        NSArray * nib = [[NSBundle mainBundle] loadNibNamed:cellId owner:self options:nil];
        cell = nib[0];
        cell.label.textAlignment = UITextAlignmentLeft;
        cell.accessoryType = UITableViewCellAccessoryNone;                    
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return cell;
}


@end
