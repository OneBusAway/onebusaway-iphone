//
//  ApptentiveStyleSheet.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 3/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveStyleSheet.h"
#import "Apptentive.h"

NSString *const ApptentiveTextStyleHeaderTitle = @"com.apptentive.header.title";
NSString *const ApptentiveTextStyleHeaderMessage = @"com.apptentive.header.message";
NSString *const ApptentiveTextStyleMessageDate = @"com.apptentive.message.date";
NSString *const ApptentiveTextStyleMessageSender = @"com.apptentive.message.sender";
NSString *const ApptentiveTextStyleMessageStatus = @"com.apptentive.message.status";
NSString *const ApptentiveTextStyleMessageCenterStatus = @"com.apptentive.messageCenter.status";
NSString *const ApptentiveTextStyleSurveyInstructions = @"com.apptentive.survey.question.instructions";
NSString *const ApptentiveTextStyleDoneButton = @"com.apptentive.doneButton";
NSString *const ApptentiveTextStyleButton = @"com.apptentive.button";
NSString *const ApptentiveTextStyleSubmitButton = @"com.apptentive.submitButton";
NSString *const ApptentiveTextStyleTextInput = @"com.apptentive.textInput";

NSString *const ApptentiveColorHeaderBackground = @"com.apptentive.color.header.background";
NSString *const ApptentiveColorFooterBackground = @"com.apptentive.color.footer.background";
NSString *const ApptentiveColorFailure = @"com.apptentive.color.failure";
NSString *const ApptentiveColorSeparator = @"com.apptentive.color.separator";
NSString *const ApptentiveColorBackground = @"com.apptentive.color.cellBackground";
NSString *const ApptentiveColorCollectionBackground = @"com.apptentive.color.collectionBackground";
NSString *const ApptentiveColorTextInputBackground = @"com.apptentive.color.textInputBackground";
NSString *const ApptentiveColorTextInputPlaceholder = @"com.apptentive.color.textInputPlaceholder";
NSString *const ApptentiveColorMessageBackground = @"com.apptentive.color.messageBackground";
NSString *const ApptentiveColorReplyBackground = @"com.apptentive.color.replyBackground";
NSString *const ApptentiveColorContextBackground = @"com.apptentive.color.contextBackground";


@interface ApptentiveStyleSheet ()

@property (strong, nonatomic) NSMutableDictionary *fontDescriptorOverrides;
@property (strong, nonatomic) NSMutableDictionary *colorOverrides;

@property (strong, nonatomic) NSMutableDictionary *fontTable;
@property (nonatomic) BOOL didInheritColors;

+ (NSArray *)UIKitTextStyles;
+ (NSArray *)apptentiveTextStyles;
+ (NSArray *)apptentiveColorStyles;

+ (NSNumber *)sizeForTextStyle:(NSString *)textStyle;
+ (NSInteger)weightForTextStyle:(NSString *)textStyle;

+ (NSString *)defaultFontFamilyName;
- (UIFontDescriptor *)fontDescriptorForStyle:(NSString *)textStyle;
- (NSString *)faceAttributeForWeight:(NSInteger)weight;

@end


@implementation ApptentiveStyleSheet

// TODO: Adjust for content size category?
+ (NSInteger)weightForTextStyle:(NSString *)textStyle {
	static NSDictionary<NSString *, NSNumber *> *faceForStyle;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		faceForStyle = @{
						 ApptentiveTextStyleHeaderTitle: @300,
						 ApptentiveTextStyleHeaderMessage: @400,
						 ApptentiveTextStyleMessageDate: @700,
						 ApptentiveTextStyleMessageSender: @700,
						 ApptentiveTextStyleMessageStatus: @700,
						 ApptentiveTextStyleMessageCenterStatus: @700,
						 ApptentiveTextStyleSurveyInstructions: @400,
						 ApptentiveTextStyleButton: @400,
						 ApptentiveTextStyleDoneButton: @700,
						 ApptentiveTextStyleSubmitButton: @500,
						 ApptentiveTextStyleTextInput: @400
						 };
	});
	return faceForStyle[textStyle].integerValue;
}

+ (NSNumber *)sizeForTextStyle:(NSString *)textStyle {
	static NSDictionary<NSString *, NSDictionary<NSString *, NSNumber *> *> *sizeForCategoryForStyle;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sizeForCategoryForStyle = @{
									ApptentiveTextStyleHeaderTitle: @{
											UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @28,
											UIContentSizeCategoryAccessibilityExtraExtraLarge: @28,
											UIContentSizeCategoryAccessibilityExtraLarge: @27,
											UIContentSizeCategoryAccessibilityLarge: @27,
											UIContentSizeCategoryAccessibilityMedium: @26,
											UIContentSizeCategoryExtraExtraExtraLarge: @26,
											UIContentSizeCategoryExtraExtraLarge: @25,
											UIContentSizeCategoryExtraLarge: @24,
											UIContentSizeCategoryLarge: @23,
											UIContentSizeCategoryMedium: @22,
											UIContentSizeCategorySmall: @21,
											UIContentSizeCategoryExtraSmall: @20
											},
									ApptentiveTextStyleHeaderMessage:  @{
											UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @22,
											UIContentSizeCategoryAccessibilityExtraExtraLarge: @21,
											UIContentSizeCategoryAccessibilityExtraLarge: @20,
											UIContentSizeCategoryAccessibilityLarge: @20,
											UIContentSizeCategoryAccessibilityMedium: @19,
											UIContentSizeCategoryExtraExtraExtraLarge: @19,
											UIContentSizeCategoryExtraExtraLarge: @18,
											UIContentSizeCategoryExtraLarge: @17,
											UIContentSizeCategoryLarge: @16,
											UIContentSizeCategoryMedium: @15,
											UIContentSizeCategorySmall: @14,
											UIContentSizeCategoryExtraSmall: @13
											},
									ApptentiveTextStyleMessageDate: @{
											UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @21,
											UIContentSizeCategoryAccessibilityExtraExtraLarge: @20,
											UIContentSizeCategoryAccessibilityExtraLarge: @19,
											UIContentSizeCategoryAccessibilityLarge: @19,
											UIContentSizeCategoryAccessibilityMedium: @18,
											UIContentSizeCategoryExtraExtraExtraLarge: @18,
											UIContentSizeCategoryExtraExtraLarge: @17,
											UIContentSizeCategoryExtraLarge: @16,
											UIContentSizeCategoryLarge: @15,
											UIContentSizeCategoryMedium: @14,
											UIContentSizeCategorySmall: @13,
											UIContentSizeCategoryExtraSmall: @12
											},
									ApptentiveTextStyleMessageSender: @{
											UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @21,
											UIContentSizeCategoryAccessibilityExtraExtraLarge: @20,
											UIContentSizeCategoryAccessibilityExtraLarge: @19,
											UIContentSizeCategoryAccessibilityLarge: @19,
											UIContentSizeCategoryAccessibilityMedium: @18,
											UIContentSizeCategoryExtraExtraExtraLarge: @18,
											UIContentSizeCategoryExtraExtraLarge: @17,
											UIContentSizeCategoryExtraLarge: @16,
											UIContentSizeCategoryLarge: @15,
											UIContentSizeCategoryMedium: @14,
											UIContentSizeCategorySmall: @13,
											UIContentSizeCategoryExtraSmall: @12
											},
									ApptentiveTextStyleMessageStatus: @{
											UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @18,
											UIContentSizeCategoryAccessibilityExtraExtraLarge: @17,
											UIContentSizeCategoryAccessibilityExtraLarge: @16,
											UIContentSizeCategoryAccessibilityLarge: @16,
											UIContentSizeCategoryAccessibilityMedium: @15,
											UIContentSizeCategoryExtraExtraExtraLarge: @15,
											UIContentSizeCategoryExtraExtraLarge: @14,
											UIContentSizeCategoryExtraLarge: @14,
											UIContentSizeCategoryLarge: @13,
											UIContentSizeCategoryMedium: @12,
											UIContentSizeCategorySmall: @12,
											UIContentSizeCategoryExtraSmall: @11
											},
									ApptentiveTextStyleMessageCenterStatus: @{
											UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @18,
											UIContentSizeCategoryAccessibilityExtraExtraLarge: @17,
											UIContentSizeCategoryAccessibilityExtraLarge: @16,
											UIContentSizeCategoryAccessibilityLarge: @16,
											UIContentSizeCategoryAccessibilityMedium: @15,
											UIContentSizeCategoryExtraExtraExtraLarge: @15,
											UIContentSizeCategoryExtraExtraLarge: @14,
											UIContentSizeCategoryExtraLarge: @14,
											UIContentSizeCategoryLarge: @13,
											UIContentSizeCategoryMedium: @12,
											UIContentSizeCategorySmall: @12,
											UIContentSizeCategoryExtraSmall: @11
											},
									ApptentiveTextStyleSurveyInstructions: @{
											UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @18,
											UIContentSizeCategoryAccessibilityExtraExtraLarge: @17,
											UIContentSizeCategoryAccessibilityExtraLarge: @16,
											UIContentSizeCategoryAccessibilityLarge: @16,
											UIContentSizeCategoryAccessibilityMedium: @15,
											UIContentSizeCategoryExtraExtraExtraLarge: @15,
											UIContentSizeCategoryExtraExtraLarge: @14,
											UIContentSizeCategoryExtraLarge: @14,
											UIContentSizeCategoryLarge: @13,
											UIContentSizeCategoryMedium: @12,
											UIContentSizeCategorySmall: @12,
											UIContentSizeCategoryExtraSmall: @11
											},
									ApptentiveTextStyleButton: @{
											UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @22,
											UIContentSizeCategoryAccessibilityExtraExtraLarge: @21,
											UIContentSizeCategoryAccessibilityExtraLarge: @20,
											UIContentSizeCategoryAccessibilityLarge: @20,
											UIContentSizeCategoryAccessibilityMedium: @19,
											UIContentSizeCategoryExtraExtraExtraLarge: @19,
											UIContentSizeCategoryExtraExtraLarge: @18,
											UIContentSizeCategoryExtraLarge: @17,
											UIContentSizeCategoryLarge: @16,
											UIContentSizeCategoryMedium: @15,
											UIContentSizeCategorySmall: @14,
											UIContentSizeCategoryExtraSmall: @13
											},
									ApptentiveTextStyleDoneButton: @{
											UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @22,
											UIContentSizeCategoryAccessibilityExtraExtraLarge: @21,
											UIContentSizeCategoryAccessibilityExtraLarge: @20,
											UIContentSizeCategoryAccessibilityLarge: @20,
											UIContentSizeCategoryAccessibilityMedium: @19,
											UIContentSizeCategoryExtraExtraExtraLarge: @19,
											UIContentSizeCategoryExtraExtraLarge: @18,
											UIContentSizeCategoryExtraLarge: @17,
											UIContentSizeCategoryLarge: @16,
											UIContentSizeCategoryMedium: @15,
											UIContentSizeCategorySmall: @14,
											UIContentSizeCategoryExtraSmall: @13
											},
									ApptentiveTextStyleSubmitButton: @{
											UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @26,
											UIContentSizeCategoryAccessibilityExtraExtraLarge: @26,
											UIContentSizeCategoryAccessibilityExtraLarge: @25,
											UIContentSizeCategoryAccessibilityLarge: @25,
											UIContentSizeCategoryAccessibilityMedium: @24,
											UIContentSizeCategoryExtraExtraExtraLarge: @24,
											UIContentSizeCategoryExtraExtraLarge: @23,
											UIContentSizeCategoryExtraLarge: @22,
											UIContentSizeCategoryLarge: @22,
											UIContentSizeCategoryMedium: @20,
											UIContentSizeCategorySmall: @19,
											UIContentSizeCategoryExtraSmall: @18
											},
									ApptentiveTextStyleTextInput: @{
											UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @21,
											UIContentSizeCategoryAccessibilityExtraExtraLarge: @20,
											UIContentSizeCategoryAccessibilityExtraLarge: @19,
											UIContentSizeCategoryAccessibilityLarge: @19,
											UIContentSizeCategoryAccessibilityMedium: @18,
											UIContentSizeCategoryExtraExtraExtraLarge: @18,
											UIContentSizeCategoryExtraExtraLarge: @17,
											UIContentSizeCategoryExtraLarge: @16,
											UIContentSizeCategoryLarge: @15,
											UIContentSizeCategoryMedium: @14,
											UIContentSizeCategorySmall: @13,
											UIContentSizeCategoryExtraSmall: @12
											},
									};
	});
	return sizeForCategoryForStyle[textStyle][[UIApplication sharedApplication].preferredContentSizeCategory];
}

+ (NSArray *)UIKitTextStyles {
	static NSArray *_UIKitTextStyles;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		if ([[NSProcessInfo processInfo] respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)] && [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){ 9, 0, 0}]) {
		_UIKitTextStyles = @[
							 UIFontTextStyleBody,
							 UIFontTextStyleCallout,
							 UIFontTextStyleCaption1,
							 UIFontTextStyleCaption2,
							 UIFontTextStyleFootnote,
							 UIFontTextStyleHeadline,
							 UIFontTextStyleSubheadline,
							 UIFontTextStyleTitle1,
							 UIFontTextStyleTitle2,
							 UIFontTextStyleTitle3,
							 ];
		} else {
			_UIKitTextStyles = @[
								 UIFontTextStyleBody,
								 UIFontTextStyleCaption1,
								 UIFontTextStyleCaption2,
								 UIFontTextStyleFootnote,
								 UIFontTextStyleHeadline,
								 UIFontTextStyleSubheadline,
								 ];
		}
	});
	return _UIKitTextStyles;
}

+ (NSArray *)apptentiveTextStyles {
	static NSArray *_apptentiveStyleNames;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_apptentiveStyleNames = @[
								  ApptentiveTextStyleHeaderTitle,
								  ApptentiveTextStyleHeaderMessage,
								  ApptentiveTextStyleMessageDate,
								  ApptentiveTextStyleMessageSender,
								  ApptentiveTextStyleMessageStatus,
								  ApptentiveTextStyleDoneButton,
								  ApptentiveTextStyleButton,
								  ApptentiveTextStyleSubmitButton
								  ];
	});
	return _apptentiveStyleNames;
}

+ (NSArray *)apptentiveColorStyles {
	static NSArray *_apptentiveColorStyles;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_apptentiveColorStyles = @[
								   ApptentiveColorHeaderBackground,
								   ApptentiveColorFooterBackground,
								   ApptentiveColorFailure
								   ];
	});
	return _apptentiveColorStyles;
}

+ (NSString *)defaultFontFamilyName {
	return [UIFont systemFontOfSize:[UIFont systemFontSize]].familyName;
}

+ (instancetype)styleSheet {
	static ApptentiveStyleSheet *_styleSheet;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_styleSheet = [[ApptentiveStyleSheet alloc] init];
	});
	return _styleSheet;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		_fontFamily = [[self class] defaultFontFamilyName];
		_lightFaceAttribute = @"Light";
		_regularFaceAttribute = @"Regular";
		_mediumFaceAttribute = @"Medium";
		_boldFaceAttribute = @"Bold";

		_sizeAdjustment = 1.0;

		_secondaryColor = [UIColor colorWithRed:142.0 / 255.0 green:142.0 / 255.0 blue:147.0 / 255.0 alpha:1.0];
		_failureColor = [UIColor colorWithRed:218.0 / 255.0 green:53.0 / 255.0 blue:71.0 / 255.0 alpha:1.0];

		_fontDescriptorOverrides = [NSMutableDictionary dictionary];
		_colorOverrides = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIColor *)appearanceColorForClass:(Class)klass property:(SEL)propertySelector default:(UIColor *)defaultColor {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	UIColor *whenContainedInColor = [[klass appearanceWhenContainedIn:[ApptentiveNavigationController class], nil] performSelector:propertySelector];
	if (whenContainedInColor) {
		return whenContainedInColor;
	}

	whenContainedInColor = [[klass appearance] performSelector:propertySelector];
	if (whenContainedInColor) {
		return whenContainedInColor;
	}
#pragma clang diagnostic pop

	return defaultColor;
}

- (void)inheritDefaultColors {
	_primaryColor = self.primaryColor ?: [self appearanceColorForClass:[UILabel class] property:@selector(textColor) default:[UIColor blackColor]];
	_separatorColor = self.separatorColor ?: [self appearanceColorForClass:[UITableView class] property:@selector(separatorColor) default:[UIColor colorWithRed:199.0 / 255.0 green:200.0 / 255.0 blue:204.0 / 255.0 alpha:1.0]];
	_backgroundColor = self.backgroundColor ?: [self appearanceColorForClass:[UITableViewCell class] property:@selector(backgroundColor) default:[UIColor whiteColor]];
	_collectionBackgroundColor = self.collectionBackgroundColor ?: [self appearanceColorForClass:[UITableView class] property:@selector(backgroundColor) default:[UIColor groupTableViewBackgroundColor]];
	_placeholderColor = self.placeholderColor ?: [UIColor colorWithRed:0 green:0 blue:25.0 / 255.0 alpha:56.0 / 255.0];
}

- (void)setFontDescriptor:(UIFontDescriptor *)fontDescriptor forStyle:(NSString *)textStyle {
	[self.fontDescriptorOverrides setObject:fontDescriptor forKey:textStyle];
}

- (UIFontDescriptor *)fontDescriptorForStyle:(NSString *)textStyle {
	if (self.fontDescriptorOverrides[textStyle]) {
		return self.fontDescriptorOverrides[textStyle];
	}

	NSString *face;
	NSNumber *size;

	if ([[[self class] UIKitTextStyles] containsObject:textStyle]) {
		// fontDescriptorWithFamily doesn't properly override the font family for the system font :(
		UIFontDescriptor *modelFontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];
		face = [self faceAttributeForFontDescriptor:modelFontDescriptor];
		size = [modelFontDescriptor objectForKey:UIFontDescriptorSizeAttribute];
	} else {
		face = [self faceAttributeForWeight:[[self class] weightForTextStyle:textStyle]];
		size = [[self class] sizeForTextStyle:textStyle];
	}

	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	attributes[UIFontDescriptorFamilyAttribute] = self.fontFamily;
	attributes[UIFontDescriptorSizeAttribute] = @(size.doubleValue * self.sizeAdjustment);

	if (face) {
		attributes[UIFontDescriptorFaceAttribute] = face;
	}

	return [UIFontDescriptor fontDescriptorWithFontAttributes:attributes];
	;
}

- (NSString *_Nullable)faceAttributeForFontDescriptor:(UIFontDescriptor *)fontDescriptor {
	NSString *faceAttribute = [fontDescriptor objectForKey:UIFontDescriptorFaceAttribute];

	if ([faceAttribute isEqualToString:@"Light"]) {
		return self.lightFaceAttribute;
	} else if ([faceAttribute isEqualToString:@"Medium"]) {
		return self.mediumFaceAttribute;
	} else if ([faceAttribute isEqualToString:@"Bold"]) {
		return self.boldFaceAttribute;
	} else {
		return self.regularFaceAttribute;
	}
}

- (NSString *)faceAttributeForWeight:(NSInteger)weight {
	switch (weight) {
		case 300:
			return self.lightFaceAttribute;
		case 400:
		default:
			return self.regularFaceAttribute;
		case 500:
			return self.mediumFaceAttribute;
		case 700:
			return self.boldFaceAttribute;
	}
}

- (UIFont *)fontForStyle:(NSString *)textStyle {
	return [UIFont fontWithDescriptor:[self fontDescriptorForStyle:textStyle] size:0.0];
}

- (void)setColor:(UIColor *)color forStyle:(NSString *)style {
	[self.colorOverrides setObject:color forKey:style];
}

- (UIColor *)interpolateAtPoint:(CGFloat)interpolation between:(UIColor *)color1 and:(UIColor *)color2 {
	CGFloat red1, green1, blue1, alpha1;
	[color1 getRed:&red1 green:&green1 blue:&blue1 alpha:&alpha1];

	CGFloat red2, green2, blue2, alpha2;
	[color2 getRed:&red2 green:&green2 blue:&blue2 alpha:&alpha2];

	CGFloat inverse = 1.0 - interpolation;

	return [UIColor colorWithRed:red1 * interpolation + red2 * inverse green:green1 * interpolation + green2 * inverse blue:blue1 * interpolation + blue2 * inverse alpha:alpha1 * interpolation + alpha2 * inverse];
}

- (UIColor *)colorForStyle:(NSString *)style {
	if (!self.didInheritColors) {
		[self inheritDefaultColors];
		self.didInheritColors = YES;
	}

	UIColor *result = self.colorOverrides[style];

	if (result) {
		return result;
	}

	if ([style isEqualToString:ApptentiveColorFailure]) {
		return self.failureColor;
	} else if ([style isEqualToString:ApptentiveColorSeparator]) {
		return self.separatorColor;
	} else if ([style isEqualToString:ApptentiveColorCollectionBackground]) {
		return self.collectionBackgroundColor;
	} else if ([@[ApptentiveColorHeaderBackground, ApptentiveColorBackground, ApptentiveColorTextInputBackground, ApptentiveColorMessageBackground] containsObject:style]) {
		return self.backgroundColor;
	} else if ([style isEqualToString:ApptentiveColorFooterBackground]) {
		return [self.backgroundColor colorWithAlphaComponent:0.5];
	} else if ([style isEqualToString:ApptentiveColorReplyBackground] || [style isEqualToString:ApptentiveColorContextBackground]) {
		return [self interpolateAtPoint:0.968 between:self.backgroundColor and:self.primaryColor];
	} else if ([style isEqualToString:ApptentiveColorTextInputPlaceholder]) {
		return self.placeholderColor;
	} else if ([@[ApptentiveTextStyleHeaderMessage, ApptentiveTextStyleMessageDate, ApptentiveTextStyleMessageStatus, ApptentiveTextStyleMessageCenterStatus, ApptentiveTextStyleSurveyInstructions] containsObject:style]) {
		return self.secondaryColor;
	} else {
		return self.primaryColor;
	}

	return result;
}

@end
