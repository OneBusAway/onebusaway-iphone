//
//  OBAClassicDepartureCell.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import UIKit;
#import <OBAKit/OBATableCell.h>

@class OBAClassicDepartureView;

@interface OBAClassicDepartureCell : UITableViewCell<OBATableCell>
@property(nonatomic,strong,readonly) OBAClassicDepartureView *departureView;
@end
