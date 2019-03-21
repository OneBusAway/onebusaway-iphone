//
//  UIImage+OBAAdditions.h
//  OBAKit
//
//  Created by Aaron Brethorst on 12/27/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (OBAAdditions)

// adapted from https://stackoverflow.com/a/8858464

- (UIImage *)oba_imageScaledToSize:(CGSize)size;

- (UIImage *)oba_imageScaledToFitSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
