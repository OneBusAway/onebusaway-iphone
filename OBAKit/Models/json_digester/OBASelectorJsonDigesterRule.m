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

#import <OBAKit/OBASelectorJsonDigesterRule.h>
#import <OBAKit/OBALogging.h>

@interface OBASelectorJsonDigesterRule()

@property (nonatomic, weak) NSObject * target;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, assign) OBAJsonDigesterRuleTarget ruleTarget;

@end


@implementation OBASelectorJsonDigesterRule

- (instancetype) initWithTarget:(id<NSObject>)target selector:(SEL)selector ruleTarget:(OBAJsonDigesterRuleTarget)ruleTarget {
    if( self = [super init] ) {
        _target = target;
        _selector = selector;
        _ruleTarget = ruleTarget;
    }
    return self;
}

- (void) begin:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {
    [self handleRuleTarget:OBAJsonDigesterRuleTargetBegin context:context name:name value:value];
}

- (void) end:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {
    [self handleRuleTarget:OBAJsonDigesterRuleTargetEnd context:context name:name value:value];
}

- (void) handleRuleTarget:(OBAJsonDigesterRuleTarget)ruleTarget context:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {
    
    if( self.ruleTarget != ruleTarget )
        return;

    id target = self.target;
    NSMethodSignature * methodSig = [target methodSignatureForSelector:self.selector];
    
    if(!methodSig) {
        DDLogError(@"selector not found for target object in OBASelectorJSONDigesterRule");
        return;
    }
    
    NSInvocation * invoker = [NSInvocation invocationWithMethodSignature:methodSig];
    [invoker setTarget:target];
    [invoker setSelector:self.selector];
    [invoker setArgument:&context atIndex:2];
    [invoker setArgument:&name atIndex:3];
    [invoker setArgument:&value atIndex:4];
    
    [invoker invoke];
}

@end
