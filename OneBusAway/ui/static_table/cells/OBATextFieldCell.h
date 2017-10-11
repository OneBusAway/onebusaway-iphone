//
//  OBATextFieldCell.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/24/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import UIKit;
@import OBAKit;

@interface OBATextFieldCell : UITableViewCell<OBATableCell>
@property(nonatomic,strong,readonly) UITextField *textField;
@end
