/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OBACreateObjectJsonDigesterRule.h"
#import "OBALogger.h"

@interface OBACreateObjectJsonDigesterRule ()
- (BOOL)shouldDigestValue:(id)value;
@end

@implementation OBACreateObjectJsonDigesterRule

- (id) initWithObjectClass:(Class)objectClass {
    if( self = [super init] ) {
        _objectClass = objectClass;
        _onlyIfNotNull = YES;
    }
    return self;
}

#pragma mark OBAJsonDigesterRule Methods

- (void) begin:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {
    if([self shouldDigestValue:value]) {
        id obj = [[_objectClass alloc] init];
        [context pushValue:obj];
        if( context.verbose )
            OBALogDebug(@"Creating object: class=%@",[_objectClass description]);
    }
}

- (void) end:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {
    if([self shouldDigestValue:value]) {
        [context popValue];
    }
}

- (BOOL)shouldDigestValue:(id)value {
    BOOL valueIsNull = (!value || CFEqual((__bridge CFTypeRef)(value), kCFNull));
    return !(_onlyIfNotNull && valueIsNull);
}



@end
