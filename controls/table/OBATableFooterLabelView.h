//
//  OBATableFooterLabelView.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OBATableFooterLabelView : UIView
@property(nonatomic,strong,readonly) UILabel *label;
- (void)resizeToFitText;
@end
