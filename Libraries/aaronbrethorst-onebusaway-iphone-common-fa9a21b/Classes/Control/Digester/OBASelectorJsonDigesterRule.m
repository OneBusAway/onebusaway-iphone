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

#import "OBASelectorJsonDigesterRule.h"
#import "OBALogger.h"

@interface OBASelectorJsonDigesterRule (Internal)

- (void) handleRuleTarget:(OBAJsonDigesterRuleTarget)ruleTarget context:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value;

@end


@implementation OBASelectorJsonDigesterRule

- (id) initWithTarget:(id<NSObject>)target selector:(SEL)selector ruleTarget:(OBAJsonDigesterRuleTarget)ruleTarget {
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

@end

@implementation OBASelectorJsonDigesterRule (Internal)

- (void) handleRuleTarget:(OBAJsonDigesterRuleTarget)ruleTarget context:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {
	
	if( _ruleTarget != ruleTarget )
		return;
	
	NSMethodSignature * methodSig = [_target methodSignatureForSelector:_selector];
	
	if( ! methodSig ) {
		OBALogSevere(@"selector not found for target object in OBASelectorJSONDigesterRule");
		return;
	}
	
	NSInvocation * invoker = [NSInvocation invocationWithMethodSignature:methodSig];
	[invoker setTarget:_target];
	[invoker setSelector:_selector];
	[invoker setArgument:&context atIndex:2];
	[invoker setArgument:&name atIndex:3];
	[invoker setArgument:&value atIndex:4];
	
	[invoker invoke];
}

@end