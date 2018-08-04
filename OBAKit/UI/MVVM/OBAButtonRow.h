//
//  OBAButtonRow.h
//  OBAKit
//
//  Created by Aaron Brethorst on 8/4/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

@import UIKit;
#import <OBAKit/OBABaseRow.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAButtonRow : OBABaseRow
@property(nonatomic,copy) UIColor *buttonColor;
@property(nonatomic,copy) NSString *title;
- (instancetype)initWithTitle:(NSString*)title action:(nullable OBARowAction)action;
@end

NS_ASSUME_NONNULL_END
