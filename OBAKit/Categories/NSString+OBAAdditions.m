//
//  NSString+OBAAdditions.m
//  OBAKit
//
//  Created by Aaron Brethorst on 9/23/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

#import <OBAKit/NSString+OBAAdditions.h>
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (OBAAdditions)

// From: https://stackoverflow.com/a/7571583
- (NSString*)oba_SHA1 {
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];

    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);

    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];

    for (NSUInteger i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }

    return [NSString stringWithString:output];
}

- (CGFloat)oba_heightWithConstrainedWidth:(CGFloat)width font:(UIFont*)font {
    CGSize constraintSize = CGSizeMake(width, FLT_MAX);
    CGRect boundingBox = [self boundingRectWithSize:constraintSize options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName: font} context:nil];

    return boundingBox.size.height;
}

@end
