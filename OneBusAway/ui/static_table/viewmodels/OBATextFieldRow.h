//
//  OBATextFieldRow.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/24/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBABaseRow.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBATextFieldRow : OBABaseRow
@property(nonatomic,copy,nullable) NSString *labelText;
@property(nonatomic,copy,nullable) NSString *textFieldText;
@property(nonatomic,assign) UIKeyboardType keyboardType;
@property(nonatomic,assign) UITextAutocapitalizationType autocapitalizationType;
@property(nonatomic,assign) UITextAutocorrectionType autocorrectionType;
@property(nonatomic,assign) UIReturnKeyType returnKeyType;

- (instancetype)initWithLabelText:(nullable NSString*)labelText textFieldText:(nullable NSString*)textFieldText;
@end

NS_ASSUME_NONNULL_END
