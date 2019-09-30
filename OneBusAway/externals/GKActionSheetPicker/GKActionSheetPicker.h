//
//  GKActionSheetPicker.h
//  
//
//  Created by GK on 15.09.10..
//
//

#import <UIKit/UIKit.h>
#import "GKActionSheetPickerItem.h"

typedef void(^GKActionSheetPickerSelectCallback)(id selected);
typedef void(^GKActionSheetPickerCancelCallback)(void);

typedef NS_ENUM(NSUInteger, GKActionSheetPickerDismissType) {
    GKActionSheetPickerDismissTypeNone,
    GKActionSheetPickerDismissTypeCancel,
    GKActionSheetPickerDismissTypeSelect
};


@class GKActionSheetPicker;

@protocol GKActionSheetPickerDelegate <NSObject>

@optional
/**
 Called when the user either clicks the positive button or `dismissType` is `GKActionSheetPickerDismissTypeSelect` and taps outside the picker.
 
 @param picker The Picker the user interacted with
 @param value The selected value. @see selection
 */
- (void)actionSheetPicker:(GKActionSheetPicker *)picker didSelectValue:(id)value;

/**
 Called when the user changed the picker view's value
 
 @param picker The Picker the user interacted with
 @param value The selected value. @see selection
 */
- (void)actionSheetPicker:(GKActionSheetPicker *)picker didChangeValue:(id)value;

/**
 Called when the user either clicks the negative button or `dismissType` is `GKActionSheetPickerDismissTypeCancel` and taps outside the picker.
 
 @param picker The Picker the user interacted with
 */
- (void)actionSheetPickerDidCancel:(GKActionSheetPicker *)picker;

@end


@interface GKActionSheetPicker : NSObject

#pragma mark - Callbacks

//! The block to be called when user presses the positive button or taps outside the picker and `dismissType` is `GKActionSheetPickerDismissTypeSelect`.
@property (nonatomic, strong) GKActionSheetPickerSelectCallback selectCallback;

//! The block to be called when user presses the negative button or taps outside the picker and `dismissType` is `GKActionSheetPickerDismissTypeCancel`.
@property (nonatomic, strong) GKActionSheetPickerCancelCallback cancelCallback;

#pragma mark - Action sheet picker buttons

//! Label on the positive button. Default: OK
@property (nonatomic, strong) NSString *selectButtonTitle;

//! Label on the negative button. Default: Cancel
@property (nonatomic, strong) NSString *cancelButtonTitle;

//! Display the negative button on the left or not. Default is `YES`
@property (nonatomic) BOOL cancelButtonEnabled;

//! Color of the buttons
@property (nonatomic, strong) UIColor *tintColor;

#pragma mark - Settings

//! Control what happens when the user taps outside the picker. Default: `GKActionSheetPickerDismissTypeNone`
@property (nonatomic) GKActionSheetPickerDismissType dismissType;

//! Color of the overlay layer above the picker. Default: transparent black.
@property (nonatomic, strong) UIColor *overlayLayerColor;

//! The title of the picker which will be displayed in the center, between the buttons
@property (nonatomic, strong) NSString *title;

#pragma mark - Control

//! Array of selected values for each row respectively. Values are either `value` properties of `GKActionSheetPickerItem` objects or strings.
@property (nonatomic, readonly) NSArray *selections;

//! The value of the selected item. If `GKActionSheetPickerItem` were given, it returns it's `value`, otherwise the string itself.
@property (nonatomic, readonly) id selection;

//! Returns `YES`, if the picker is currently presented.
@property (nonatomic, readonly) BOOL isOpen;

//! Inner date picker object, which you can access to set it's locale, timeZone, and other properties
@property (nonatomic, readonly) UIDatePicker *datePicker;

//! Picker's delegate object
@property (nonatomic, strong) id<GKActionSheetPickerDelegate> delegate;

#pragma mark - String Picker

/**
 Create a new `GKActionSheetPicker` instance with string mode. Please note, that many of the parameters are not included in this initializer function, you have to set them on the created object manually.
 
 @param items Array of NSStrings or `GKActionSheetPickerItem` objects to display.
 @param selectCallback The block to be called when user presses the positive button or taps outside the picker and `dismissType` is `GKActionSheetPickerDismissTypeSelect`.
 @param cancelCallback The block to be called when user presses the negative button or taps outside the picker and `dismissType` is `GKActionSheetPickerDismissTypeCancel`.
 
 @return A new `GKActionSheetPicker` object
 */
+ (instancetype)stringPickerWithItems:(NSArray *)items selectCallback:(GKActionSheetPickerSelectCallback)selectCallback cancelCallback:(GKActionSheetPickerCancelCallback)cancelCallback;

/**
 Create a new `GKActionSheetPicker` instance with string mode. Please note, that many of the parameters are not included in this initializer function, you have to set them on the created object manually.
 
 @param items Array of NSStrings or `GKActionSheetPickerItem` objects to display.
 
 @return A new `GKActionSheetPicker` object
 */
+ (instancetype)stringPickerWithItems:(NSArray *)items;

#pragma mark - Multi-column String Picker

/**
 Create a new `GKActionSheetPicker` instance with string mode. Please note, that many of the parameters are not included in this initializer function, you have to set them on the created object manually.
 
 @param components Array of values to display in each column. Each array should contain either NSStrings or `GKActionSheetPickerItem` objects.
 @param selectCallback The block to be called when user presses the positive button or taps outside the picker and `dismissType` is `GKActionSheetPickerDismissTypeSelect`.
 @param cancelCallback The block to be called when user presses the negative button or taps outside the picker and `dismissType` is `GKActionSheetPickerDismissTypeCancel`.
 
 @return A new `GKActionSheetPicker` object
 */
+ (instancetype)multiColumnStringPickerWithComponents:(NSArray *)components selectCallback:(GKActionSheetPickerSelectCallback)selectCallback cancelCallback:(GKActionSheetPickerCancelCallback)cancelCallback;

/**
 Create a new `GKActionSheetPicker` instance with string mode. Please note, that many of the parameters are not included in this initializer function, you have to set them on the created object manually.
 
 @param components Array of values to display in each column. Each array should contain either NSStrings or `GKActionSheetPickerItem` objects.
 
 @return A new `GKActionSheetPicker` object
 */
+ (instancetype)multiColumnStringPickerWithComponents:(NSArray *)components;

#pragma mark - Date Picker

/**
 Creates a new `GKActionSheetPicker` instance with date mode. Please note, that many of the parameters are not included in this initializer function, you have to set them on the created object manually.
 
 @param datePickerMode See https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIDatePicker_Class/#//apple_ref/occ/instp/UIDatePicker/datePickerMode
 @param minimumDate See https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIDatePicker_Class/#//apple_ref/occ/instp/UIDatePicker/minimumDate
 @param maximumDate See https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIDatePicker_Class/#//apple_ref/occ/instp/UIDatePicker/maximumDate
 @param minuteInterval See https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIDatePicker_Class/#//apple_ref/occ/instp/UIDatePicker/minuteInterval
 @param selectCallback The block to be called when user presses the positive button or taps outside the picker and `dismissType` is `GKActionSheetPickerDismissTypeSelect`.
 @param cancelCallback The block to be called when user presses the negative button or taps outside the picker and `dismissType` is `GKActionSheetPickerDismissTypeCancel`.
 
 @return A new `GKActionSheetPicker` object
 */
+ (instancetype)datePickerWithMode:(UIDatePickerMode)datePickerMode from:(NSDate *)minimumDate to:(NSDate *)maximumDate interval:(NSInteger)minuteInterval selectCallback:(GKActionSheetPickerSelectCallback)selectCallback cancelCallback:(GKActionSheetPickerCancelCallback)cancelCallback;

/**
 Creates a new `GKActionSheetPicker` instance with date mode. Please note, that many of the parameters are not included in this initializer function, you have to set them on the created object manually.
 
 @param datePickerMode See https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIDatePicker_Class/#//apple_ref/occ/instp/UIDatePicker/datePickerMode
 @param minimumDate See https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIDatePicker_Class/#//apple_ref/occ/instp/UIDatePicker/minimumDate
 @param maximumDate See https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIDatePicker_Class/#//apple_ref/occ/instp/UIDatePicker/maximumDate
 @param minuteInterval See https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIDatePicker_Class/#//apple_ref/occ/instp/UIDatePicker/minuteInterval
 
 @return A new `GKActionSheetPicker` object
 */
+ (instancetype)datePickerWithMode:(UIDatePickerMode)datePickerMode from:(NSDate *)minimumDate to:(NSDate *)maximumDate interval:(NSInteger)minuteInterval;

#pragma mark - Country Picker

/**
 Creates a new `GKActionSheetPicker` instance in country mode. Please note, that many of the parameters are not included in this initializer function, you have to set them on the created object manually.
 
 @param selectCallback The block to be called when user presses the positive button or taps outside the picker and `dismissType` is `GKActionSheetPickerDismissTypeSelect`.
 @param cancelCallback The block to be called when user presses the negative button or taps outside the picker and `dismissType` is `GKActionSheetPickerDismissTypeCancel`.
 
 @return A new `GKActionSheetPicker` object
 */
+ (instancetype)countryPickerWithCallback:(GKActionSheetPickerSelectCallback)selectCallback cancelCallback:(GKActionSheetPickerCancelCallback)cancelCallback;

/**
 Creates a new `GKActionSheetPicker` instance in country mode. Please note, that many of the parameters are not included in this initializer function, you have to set them on the created object manually.
  
 @return A new `GKActionSheetPicker` object
 */
+ (instancetype)countryPicker;

#pragma mark - Selecting values

/**
 Select a value in a multi column string picker.
 
 @param value The `value` or the string to be selected
 @param component The number of the component

 r@note Call this after -presentPickerOnView:
 */
- (void)selectValue:(id)value inComponent:(NSUInteger)component;

/**
 Select multiple values at once in a multi column string picker
 
 @param values Array of values, where values must be `value` or string

 @note Call this after -presentPickerOnView:
 */
- (void)selectValues:(NSArray *)values;

/**
 Select a valu in a string picker.
 
 @param value The `value` or the string to be selected
 
 @note Call this after -presentPickerOnView:
 */
- (void)selectValue:(id)value;

/**
 Select an item by its position in a multi column string picker.
 
 @param index The row to be selected in the given component
 @param component The number of the component

 @note Call this after -presentPickerOnView:
 */
- (void)selectIndex:(NSUInteger)index inComponent:(NSUInteger)component;

/**
 Select an item by its position in a string picker.
 
 @param index The row to be selected

 @note Call this after -presentPickerOnView:
 */
- (void)selectIndex:(NSUInteger)index;

/**
 Select a date on the date picker.
 
 @param date A valid date which can be set on the picker

 @note Call this after -presentPickerOnView:
 */
- (void)selectDate:(NSDate *)date;

/**
 Select a country on the country picker by giving it's ISO3166-1-Alpha-2 2-letter country code
 
 @param countryName English name of the country
 
 @note Call this after -presentPickerOnView:
 */
- (void)selectCountryByName:(NSString *)countryName;

/**
 Select a country on the country picker by giving it's english name
 
 @param countryCode ISO3166-1-Alpha-2 2-letter country code
 
 @note Call this after -presentPickerOnView:
 */
- (void)selectCountryByCountryCode:(NSString *)countryCode;

#pragma mark - Control functions

/**
 Open the picker.
 
 @param view The view to add the picker as a subview to.

 @note Call this after -presentPickerOnView:
 */
- (void)presentPickerOnView:(UIView *)view;

/**
 Close the picker. Does nothing when it is not open.
 */
- (void)dismissPickerView;

@end
