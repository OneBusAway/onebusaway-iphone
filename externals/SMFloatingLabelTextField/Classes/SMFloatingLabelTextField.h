//
//  SMFloatingLabelTextField.h
//  Pods
//
//  Created by Michał Moskała on 30.06.2016.
//
//

#import <UIKit/UIKit.h>

@interface SMFloatingLabelTextField : UITextField
@property (nonatomic, strong, nonnull) IBInspectable UIColor *floatingLabelActiveColor;
@property (nonatomic, strong, nonnull) IBInspectable UIColor *floatingLabelPassiveColor;
@property (nonatomic, assign) IBInspectable CGFloat floatingLabelLeadingOffset;
@property (nonatomic, strong, nonnull) UIFont *floatingLabelFont;
@end
