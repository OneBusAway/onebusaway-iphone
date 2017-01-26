//
//  NSCoder+OBAAdditions.m
//  OBAKit
//
//  Created by Aaron Brethorst on 1/13/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

#import <OBAKit/NSCoder+OBAAdditions.h>
#import <OBAKit/OBAMacros.h>

@implementation NSCoder (OBAAdditions)

#pragma mark - Decode

- (NSInteger)oba_decodeInteger:(SEL)selector {
    return [self decodeIntegerForKey:NSStringFromSelector(selector)];
}

- (id)oba_decodeObject:(SEL)selector {
    return [self decodeObjectForKey:NSStringFromSelector(selector)];
}

- (double)oba_decodeDouble:(SEL)selector {
    return [self decodeDoubleForKey:NSStringFromSelector(selector)];
}

- (int64_t)oba_decodeInt64:(SEL)selector {
    return [self decodeInt64ForKey:NSStringFromSelector(selector)];
}

- (BOOL)oba_decodeBool:(SEL)selector {
    return [self decodeBoolForKey:NSStringFromSelector(selector)];
}

#pragma mark - Encode

- (void)oba_encodePropertyOnObject:(id)obj withSelector:(SEL)selector {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self oba_encodeObject:[obj performSelector:selector] forSelector:selector];
#pragma clang diagnostic pop
}

- (void)oba_encodeInteger:(NSInteger)integer forSelector:(SEL)selector {
    [self encodeInteger:integer forKey:NSStringFromSelector(selector)];
}

- (void)oba_encodeDouble:(double)value forSelector:(SEL)selector {
    [self encodeDouble:value forKey:NSStringFromSelector(selector)];
}

- (void)oba_encodeObject:(id)value forSelector:(SEL)selector {
    [self encodeObject:value forKey:NSStringFromSelector(selector)];
}

- (void)oba_encodeInt64:(int64_t)value forSelector:(SEL)selector {
    [self encodeInt64:value forKey:NSStringFromSelector(selector)];
}

- (void)oba_encodeBool:(BOOL)value forSelector:(SEL)selector {
    [self encodeBool:value forKey:NSStringFromSelector(selector)];
}

#pragma mark - Other

- (BOOL)oba_containsValue:(SEL)selector {
    return [self containsValueForKey:NSStringFromSelector(selector)];
}

@end
