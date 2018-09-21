//
//  NSString+OBAAdditions.h
//  OBAKit
//
//  Created by Aaron Brethorst on 9/23/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

@import Foundation;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface NSString (OBAAdditions)
@property(nonatomic,copy,readonly,nullable) NSString *oba_SHA1;

- (CGFloat)oba_heightWithConstrainedWidth:(CGFloat)width font:(UIFont*)font;

@end

NS_ASSUME_NONNULL_END
