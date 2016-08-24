//
//  OBAUIBuilder.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/12/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAUIBuilder.h"

@implementation OBAUIBuilder

+ (UILabel*)label {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.numberOfLines = 1;
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.8f;
    return label;
}

+ (OBATableFooterLabelView*)footerLabelWithText:(NSString*)text tableView:(UITableView*)tableView {
    OBATableFooterLabelView *footerLabel = [[OBATableFooterLabelView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), 100)];
    footerLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    footerLabel.label.text = text;
    [footerLabel resizeToFitText];
    return footerLabel;
}

@end
