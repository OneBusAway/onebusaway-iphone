//
//  OBAPlaceholderView.h
//  OBAKit
//
//  Created by Aaron Brethorst on 1/3/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface OBAPlaceholderView : UIView
/**
 Create a placeholder view with the specified number of lines.

 @param numberOfLines This can either be 2 or 3.
 @return A placeholder view instance.
 */
- (instancetype)initWithNumberOfLines:(NSUInteger)numberOfLines NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
