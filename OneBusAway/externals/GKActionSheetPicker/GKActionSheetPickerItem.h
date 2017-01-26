//
//  GKActionSheetPickerItem.h
//  
//
//  Created by GK on 15.09.10..
//
//

#import <Foundation/Foundation.h>

@interface GKActionSheetPickerItem : NSObject

//! The text to display on the picker
@property (nonatomic, strong) NSString *title;

//! The value which will be given back
@property (nonatomic, strong) id value;

/**
 Create a new `GKActionSheetPickerItem`.
 
 @param title The text to display on the UI
 @param value Any object. You will be returned this item, when the picker closes.
 
 @return New GKActionSheetPickerItem
 */
+ (instancetype)pickerItemWithTitle:(NSString *)title value:(id)value;

@end
