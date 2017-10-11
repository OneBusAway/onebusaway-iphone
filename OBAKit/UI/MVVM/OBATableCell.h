//
//  OBATableCell.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/21/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import UIKit;
#import <OBAKit/OBABaseRow.h>

@protocol OBATableCell <NSObject>
@property(nonatomic,copy) OBABaseRow *tableRow;
@end
