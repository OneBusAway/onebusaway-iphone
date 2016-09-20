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

#import <OBAKit/OBASetNextOBAJsonDigesterRule.h>

@implementation OBASetNextOBAJsonDigesterRule

- (id) initWithSelector:(SEL)selector {
    self = [super init];
    if( self ) {
        _selector = selector;
        _onlyIfNotNull = YES;
    }
    return self;
}

- (void) end:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {
    
    if( _onlyIfNotNull && (value == nil || value == ((id)kCFNull)) )
        return;
    
    id a = [context peek:0];
    id<NSObject> b = [context peek:1];
    
    if (context.verbose) {
        NSLog(@"setNext");
    }

    if (a && b && [b respondsToSelector:_selector]) {
// note: I think that silencing warnings like this is gross.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [b performSelector:_selector withObject:a];
#pragma clang diagnostic pop
    }
    else if (context.verbose) {
        NSLog(@"setNext selector not supported");
    }
}

@end
