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

#import <Foundation/Foundation.h>


@protocol OBAJsonDigesterContext

-(void) pushValue:(id)value;
-(id) peek:(NSUInteger)index;
-(void) popValue;

- (id) getParameterForKey:(id)key;
- (void) setParamter:(id)value forKey:(id)key;

@property (nonatomic,strong) NSError * error;
@property (nonatomic,readonly) BOOL verbose;

@end

@protocol OBAJsonDigesterRule

@optional

- (void) begin:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value;
- (void) end:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value;

@end


typedef enum {
    OBAJsonDigesterRuleTargetBegin,
    OBAJsonDigesterRuleTargetEnd
} OBAJsonDigesterRuleTarget;


@interface OBAJsonDigester : NSObject {
    NSMutableDictionary * _rulesByPrefix;
}

- (BOOL) parse:(id)jsonRoot withRoot:(id)rootObject error:(NSError**)error;
- (BOOL) parse:(id)jsonRoot withRoot:(id)rootObject parameters:(NSDictionary*)parameters error:(NSError**)error;

- (void) addRule:(id<OBAJsonDigesterRule>)rule forPrefix:(NSString*)prefix;
- (void) addObjectCreateRule:(Class)objectClass forPrefix:(NSString*)prefix;
- (void) addCallMethodRule:(SEL)selector forPrefix:(NSString*)prefix;
- (void) addSetPropertyRule:(NSString*)property forPrefix:(NSString*)prefix;
- (void) addSetOptionalPropertyRule:(NSString*)property forPrefix:(NSString*)prefix;
- (void) addSetPropertyIfNeededRule:(NSString*)property forPrefix:(NSString*)prefix;
- (void) addSetNext:(SEL)selector forPrefix:(NSString*)prefix;
- (void) addTarget:(NSObject*)target selector:(SEL)selector forRuleTarget:(OBAJsonDigesterRuleTarget)ruleTarget prefix:(NSString*)prefix;

-(NSString*) extendPrefix:(NSString*)prefix withValue:(NSString*)value;

@property (nonatomic) BOOL verbose;

@end
