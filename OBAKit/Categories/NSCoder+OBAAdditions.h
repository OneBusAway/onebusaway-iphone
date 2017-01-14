//
//  NSCoder+OBAAdditions.h
//  OBAKit
//
//  Created by Aaron Brethorst on 1/13/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

@import Foundation;

@interface NSCoder (OBAAdditions)

- (NSInteger)oba_decodeInteger:(SEL)selector;
- (id)oba_decodeObject:(SEL)selector;
- (double)oba_decodeDouble:(SEL)selector;
- (int64_t)oba_decodeInt64:(SEL)selector;
- (BOOL)oba_decodeBool:(SEL)selector;

- (void)oba_encodeInteger:(NSInteger)value forSelector:(SEL)selector;
- (void)oba_encodeInt64:(int64_t)value forSelector:(SEL)selector;
- (void)oba_encodeDouble:(double)value forSelector:(SEL)selector;
- (void)oba_encodeObject:(id)value forSelector:(SEL)selector;
- (void)oba_encodeBool:(BOOL)value forSelector:(SEL)selector;

- (void)oba_encodePropertyOnObject:(id)obj withSelector:(SEL)selector;

- (BOOL)oba_containsValue:(SEL)selector;
@end
