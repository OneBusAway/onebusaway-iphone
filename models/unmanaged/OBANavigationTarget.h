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

//#import <Foundation/Foundation.h>
#import "OBACommon.h"


@interface OBANavigationTarget : NSObject <NSCoding> {
	OBANavigationTargetType _target;
	NSMutableDictionary * _parameters;
}

@property (nonatomic,readonly) OBANavigationTargetType target;
@property (nonatomic,readonly) NSDictionary * parameters;

- (id) initWithTarget:(OBANavigationTargetType)target;
- (id) initWithTarget:(OBANavigationTargetType)target parameters:(NSDictionary*)parameters;
- (id) initWithCoder:(NSCoder*)coder;

+ (id) target:(OBANavigationTargetType)target;
+ (id) target:(OBANavigationTargetType)target parameters:(NSDictionary*)parameters;

- (id) parameterForKey:(id)key;
- (void) setParameter:(id)value forKey:(id)key;

@end
