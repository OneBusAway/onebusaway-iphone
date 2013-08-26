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

#import "OBAJsonDigester.h"
#import "OBACreateObjectJsonDigesterRule.h"
#import "OBACallMethodJsonDigesterRule.h"
#import "OBASetPropertyJsonDigesterRule.h"
#import "OBASetNextOBAJsonDigesterRule.h"
#import "OBASelectorJsonDigesterRule.h"
#import "OBALogger.h"


#pragma mark OBAJsonDigesterContextImpl Interface

@interface OBAJsonDigesterContextImpl : NSObject<OBAJsonDigesterContext>
{
    NSMutableArray * _stack;
    NSMutableDictionary * _parameters;
    NSError * _error;
    BOOL _verbose;
}

- (id) initWithVerbose:(BOOL)verbose;

@end


#pragma mark OBAJsonDigester Private Interface

@interface OBAJsonDigester (Private)

-(void) recursivelyParse:(OBAJsonDigesterContextImpl*)context jsonValue:(id)value prefix:(NSString*)prefix name:(NSString*)name;

@end


#pragma mark OBAJsonDigester Implementation

@implementation OBAJsonDigester

- (id) init {
    self = [super init];
    if( self ) {
        _rulesByPrefix = [[NSMutableDictionary alloc] init];
        _verbose = NO;
    }
    return self;
}


- (void) addRule:(id<OBAJsonDigesterRule>)rule forPrefix:(NSString*)prefix {
    NSMutableArray * rules = _rulesByPrefix[prefix];
    if( ! rules ) {
        rules = [NSMutableArray array];
        _rulesByPrefix[prefix] = rules;
    }
    [rules addObject:rule];
}

- (void) addObjectCreateRule:(Class)objectClass forPrefix:(NSString*)prefix {
    OBACreateObjectJsonDigesterRule * rule = [[OBACreateObjectJsonDigesterRule alloc] initWithObjectClass:objectClass];
    [self addRule:rule forPrefix:prefix];
}

- (void) addCallMethodRule:(SEL)selector forPrefix:(NSString*)prefix {
    OBACallMethodJsonDigesterRule * rule = [[OBACallMethodJsonDigesterRule alloc] initWithSelector:selector];
    [self addRule:rule forPrefix:prefix];
}

- (void) addSetPropertyRule:(NSString*)property forPrefix:(NSString*)prefix {
    OBASetPropertyJsonDigesterRule * rule = [[OBASetPropertyJsonDigesterRule alloc] initWithPropertyName:property];
    [self addRule:rule forPrefix:prefix];
}

- (void) addSetOptionalPropertyRule:(NSString*)property forPrefix:(NSString*)prefix {
    OBASetPropertyJsonDigesterRule * rule = [[OBASetPropertyJsonDigesterRule alloc] initWithPropertyName:property];
    rule.optional = YES;
    [self addRule:rule forPrefix:prefix];
}


- (void) addSetPropertyIfNeededRule:(NSString*)property forPrefix:(NSString*)prefix {
    OBASetPropertyJsonDigesterRule * rule = [[OBASetPropertyJsonDigesterRule alloc] initWithPropertyName:property onlyIfNeeded:YES];
    [self addRule:rule forPrefix:prefix];
    
}

- (void) addSetNext:(SEL)selector forPrefix:(NSString*)prefix {
    OBASetNextOBAJsonDigesterRule * rule = [[OBASetNextOBAJsonDigesterRule alloc] initWithSelector:selector];
    [self addRule:rule forPrefix:prefix];
}

- (void) addTarget:(NSObject*)target selector:(SEL)selector forRuleTarget:(OBAJsonDigesterRuleTarget)ruleTarget prefix:(NSString*)prefix {
    OBASelectorJsonDigesterRule * rule = [[OBASelectorJsonDigesterRule alloc] initWithTarget:target selector:selector ruleTarget:ruleTarget];
    [self addRule:rule forPrefix:prefix];
}

- (BOOL) parse:(id)jsonRoot withRoot:(id)rootObject error:(NSError**)error {
    return [self parse:jsonRoot withRoot:rootObject parameters:@{} error:error];
}

- (BOOL)parse:(id)jsonRoot withRoot:(id)rootObject parameters:(NSDictionary*)parameters error:(NSError**)error {
    
    OBAJsonDigesterContextImpl * context = [[OBAJsonDigesterContextImpl alloc] initWithVerbose:_verbose];
    
    for (id key in parameters) {
        [context setParamter:parameters[key] forKey:key];
    }
    
    if (rootObject) {
        [context pushValue:rootObject];
    }
    
    [self recursivelyParse:context jsonValue:jsonRoot prefix:@"" name:@"/"];
    
    NSError * err = context.error;
    
    if (err && error) {
        (*error) = err;
    }
    return (err != nil);
}

-(NSString*) extendPrefix:(NSString*)prefix withValue:(NSString*)value {
    if( [prefix length] == 0)
        return value;
    if( [value length] == 0)
        return prefix;
    if( [prefix characterAtIndex:([prefix length]-1)] == '/' )
        return [NSString stringWithFormat:@"%@%@",prefix,value];
    else
        return [NSString stringWithFormat:@"%@/%@",prefix,value];
}

@end


#pragma mark OBAJsonDigester (Private) Implementation

@implementation OBAJsonDigester (Private)

-(void) recursivelyParse:(OBAJsonDigesterContextImpl*)context jsonValue:(id)value prefix:(NSString*)prefix name:(NSString*)name {
    
    NSString * fullName = [self extendPrefix:prefix withValue:name];
    
    if( _verbose )
        OBALogDebug(@"path=%@",fullName);
    
    NSArray * rules = _rulesByPrefix[fullName];
    
    if( rules ) {
        for( id<OBAJsonDigesterRule,NSObject> rule in rules) {
            if( [rule respondsToSelector:@selector(begin:name:value:)] ) {
                [rule begin:context name:name value:value];
                if( context.error )
                    return;
            }
        }    
    }
    
    if([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary * dictionary = (NSDictionary*) value;
        for( id key in dictionary ) {
            if( ! [key isKindOfClass:[NSString class]] )
                continue;
            NSString * keyString = (NSString*)key;
            id nextValue = dictionary[key];
            [self recursivelyParse:context jsonValue:nextValue prefix:fullName name:keyString];
            if( context.error )
                return;
        }
    }
    else if([value isKindOfClass:[NSArray class]]) {
        NSArray * array = (NSArray*) value;
        for( id nextValue in array ) {
            [self recursivelyParse:context jsonValue:nextValue prefix:fullName name:@"[]"];
            if( context.error )
                return;
        }
    }
    else {
        
    }
    
    if( rules ) {
        for( NSInteger i = [rules count]-1; i>=0; i--) {
            id<OBAJsonDigesterRule,NSObject> rule = rules[i];
            if( [rule respondsToSelector:@selector(end:name:value:)] ) {
                [rule end:context name:name value:value];
                if( context.error )
                    return;
            }
        }    
    }        
}

@end


#pragma mark OBAJsonDigesterContextImpl Implementation

@implementation OBAJsonDigesterContextImpl

@synthesize error = _error;

- (id) initWithVerbose:(BOOL)verbose {
    self = [super init];
    if( self ) {
        _stack = [[NSMutableArray alloc] init];
        _parameters = [[NSMutableDictionary alloc] init];
        _verbose = verbose;
    }
    return self;
}


-(void) pushValue:(id)value {
    [_stack addObject:value];
}

-(id) peek:(NSUInteger)index {
    NSInteger objIndex = [_stack count] - 1 - index;
    if (objIndex < 0 || objIndex > [_stack count]) {
        NSLog(@"OBAJsonDigesterContextImpl: peek - index out of bounds: %d => %d", index, objIndex);
        return nil;
    }
    return _stack[objIndex];
}

-(void) popValue {
    [_stack removeLastObject];
}

- (id) getParameterForKey:(id)key {
    return _parameters[key];
}

- (void) setParamter:(id)value forKey:(id)key {
    _parameters[key] = value;
}

- (BOOL) verbose {
    return _verbose;
}

@end

