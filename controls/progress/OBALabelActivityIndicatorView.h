//
//  OBALabelActivityIndicatorView.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/20/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OBALabelActivityIndicatorView : UIView
@property(nonatomic,strong,readonly) UILabel *textLabel;

- (void)startAnimating;
- (void)stopAnimating;
- (void)prepareForReuse;
@end
