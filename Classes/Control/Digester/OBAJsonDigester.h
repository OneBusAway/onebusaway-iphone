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

@property (nonatomic,retain) NSError * error;

@end

@protocol OBAJsonDigesterRule

@optional

- (void) begin:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value;
- (void) end:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value;

@end


@interface OBAJsonDigester : NSObject {
	NSMutableDictionary * _rulesByPrefix;
}

- (void) addRule:(id<OBAJsonDigesterRule>)rule forPrefix:(NSString*)prefix;
- (void) parse:(id)jsonRoot withRoot:(id)rootObject;
- (void) parse:(id)jsonRoot withRoot:(id)rootObject parameters:(NSDictionary*)parameters;

- (void) addObjectCreateRule:(Class)objectClass forPrefix:(NSString*)prefix;
- (void) addSetPropertyRule:(NSString*)property forPrefix:(NSString*)prefix;
- (void) addSetNext:(SEL)selector forPrefix:(NSString*)prefix;

-(NSString*) extendPrefix:(NSString*)prefix withValue:(NSString*)value;

@end
