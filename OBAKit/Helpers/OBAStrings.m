//
//  OBAStrings.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/25/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAStrings.h>
#import <OBAKit/OBAMacros.h>

@implementation OBAStrings

+ (NSString*)cancel {
    return OBALocalized(@"msg_cancel", @"Typically used on alerts and other modal actions. A 'cancel' button.");
}

+ (NSString*)delete {
    return OBALocalized(@"msg_delete", @"Typically used on alerts and other modal actions. A 'delete' button.");
}

+ (NSString*)dismiss {
    return OBALocalized(@"msg_dismiss", @"Used on alerts. iOS tends to use 'Dismiss' instead of 'OK' on alerts that the user isn't actually agreeing to.");
}

+ (NSString*)edit {
    return OBALocalized(@"msg_edit", @"As in 'edit object'.");
}

+ (NSString*)error {
    return OBALocalized(@"msg_error", @"The text 'Error'");
}

+ (NSString*)ok {
    return OBALocalized(@"msg_ok", @"Standard 'OK' button text.");
}

+ (NSString*)save {
    return OBALocalized(@"msg_save", @"Standard 'Save' button text.");
}

+ (NSString*)scheduledDepartureExplanation {
    return OBALocalized(@"msg_scheduled_explanatory", @"The explanatory text displayed when a non-realtime trip is displayed on-screen.");
}

+ (nullable NSAttributedString*)attributedStringWithPrependedImage:(UIImage*)image string:(NSString*)string {
    return [self attributedStringWithPrependedImage:image string:string color:nil];
}

+ (NSAttributedString*)attributedStringWithPrependedImage:(UIImage*)image string:(NSString*)string color:(nullable UIColor*)color {
    OBAGuard(image && string) else {
        return nil;
    }

    color = color ?: [UIColor whiteColor];

    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.bounds = CGRectMake(0, 0, 12, 16);
    attachment.image = image;

    NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
    [mutableAttributedString appendAttributedString:attachmentString];
    [mutableAttributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:0] range:NSMakeRange(0, mutableAttributedString.length)]; // Put font size 0 to prevent offset
    [mutableAttributedString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, mutableAttributedString.length)];
    [mutableAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];

    [mutableAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:string]];
    return mutableAttributedString;
}

@end
