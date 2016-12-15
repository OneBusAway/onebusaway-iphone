//
//  OBAValue1ContentsView.h
//  OBAKit
//
//  Created by Aaron Brethorst on 12/14/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import UIKit;

/**
 This class mimics the appearance of the contents of the
 Value1 type of UITableViewCell. In other words, you can
 embed this into a table cell and it'll look like a Value1
 cell.

 | [ image view ] [ title label ] ------ [detail label] |
 */

NS_ASSUME_NONNULL_BEGIN

@interface OBAValue1ContentsView : UIView
@property(nonatomic,strong,readonly) UIImageView *imageView;
@property(nonatomic,strong,readonly) UILabel *textLabel;
@property(nonatomic,strong,readonly) UILabel *detailTextLabel;

- (void)prepareForReuse;
@end

NS_ASSUME_NONNULL_END
