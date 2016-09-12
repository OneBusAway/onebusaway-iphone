//
//  ApptentiveInteractionInvocation.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 12/10/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionInvocation.h"

#import "ApptentiveEngagementBackend.h"
#import "ApptentiveInteractionUsageData.h"
#import "ApptentiveUtilities.h"


@implementation ApptentiveInteractionInvocation

+ (void)load {
	[NSKeyedUnarchiver setClass:self forClassName:@"ATInteractionInvocation"];
}

+ (ApptentiveInteractionInvocation *)invocationWithJSONDictionary:(NSDictionary *)jsonDictionary {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	invocation.interactionID = jsonDictionary[@"interaction_id"];
	invocation.priority = [jsonDictionary[@"priority"] integerValue];
	invocation.criteria = jsonDictionary[@"criteria"];

	return invocation;
}

+ (NSArray *)invocationsWithJSONArray:(NSArray *)jsonArray {
	NSMutableArray *invocations = [NSMutableArray array];

	for (NSObject *invocationObject in jsonArray) {
		ApptentiveInteractionInvocation *invocation = nil;

		// Handle arrays of both Invocation and NSDictionary
		if ([invocationObject isKindOfClass:[ApptentiveInteractionInvocation class]]) {
			invocation = (ApptentiveInteractionInvocation *)invocationObject;
		} else if ([invocationObject isKindOfClass:[NSDictionary class]]) {
			invocation = [ApptentiveInteractionInvocation invocationWithJSONDictionary:(NSDictionary *)invocationObject];
		}

		if (invocation) {
			[invocations addObject:invocation];
		}
	}

	return invocations;
}

- (NSString *)description {
	NSDictionary *description = @{ @"interaction_id": self.interactionID ?: [NSNull null],
		@"priority": [NSNumber numberWithInteger:self.priority] ?: [NSNull null],
		@"criteria": self.criteria ?: [NSNull null] };

	return [description description];
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		self.interactionID = [coder decodeObjectForKey:@"interactionID"];
		self.priority = [coder decodeIntegerForKey:@"priority"];
		self.criteria = [coder decodeObjectForKey:@"criteria"];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.interactionID forKey:@"interactionID"];
	[coder encodeInteger:self.priority forKey:@"priority"];
	[coder encodeObject:self.criteria forKey:@"criteria"];
}

- (id)copyWithZone:(NSZone *)zone {
	ApptentiveInteractionInvocation *copy = [[ApptentiveInteractionInvocation alloc] init];

	if (copy) {
		copy.interactionID = self.interactionID;
		copy.priority = self.priority;
		copy.criteria = self.criteria;
	}

	return copy;
}

- (BOOL)isValid {
	return [self criteriaAreMet];
}

- (BOOL)criteriaAreMet {
	return [self criteriaAreMetForUsageData:[ApptentiveInteractionUsageData usageData]];
}

- (BOOL)criteriaAreMetForUsageData:(ApptentiveInteractionUsageData *)usageData {
	BOOL criteriaAreMet = NO;

	if (!self.criteria) {
		// Interactions without a criteria object should evaluate to FALSE.
		criteriaAreMet = NO;
	} else if (self.criteria && self.criteria.count == 0) {
		// Interactions with no keys in the criteria dictionary should evaluate to TRUE.
		criteriaAreMet = YES;
	} else {
		@try {
			NSPredicate *predicate = [self criteriaPredicate];
			if (predicate) {
				NSDictionary *predicateEvaluationDictionary = [usageData predicateEvaluationDictionary];
				if (predicateEvaluationDictionary) {
					criteriaAreMet = [predicate evaluateWithObject:predicateEvaluationDictionary];
					if (!criteriaAreMet) {
						ApptentiveLogInfo(@"Interaction %@ predicate failed evaluation.", self.interactionID);
					}
				} else {
					ApptentiveLogError(@"Could not create predicate evaluation data.");
					criteriaAreMet = NO;
				}
			} else {
				ApptentiveLogError(@"Could not create a valid criteria predicate for the Interaction criteria: %@", self.criteria);
				criteriaAreMet = NO;
			}
		}
		@catch (NSException *exception) {
			ApptentiveLogError(@"Exception while processing criteria.");
			criteriaAreMet = NO;
		}
	}

	return criteriaAreMet;
}

- (NSPredicate *)criteriaPredicate {
	NSPredicate *criteriaPredicate = [ApptentiveInteractionInvocation compoundPredicateWithCriteria:self.criteria];

	return criteriaPredicate;
}

+ (NSCompoundPredicate *)compoundPredicateWithCriteria:(NSDictionary *)criteria {
	NSMutableArray *subPredicates = [NSMutableArray array];

	for (NSString *key in criteria) {
		NSObject *parameter = [criteria objectForKey:key];
		if ([parameter isKindOfClass:[NSString class]]) {
			parameter = [(NSString *)parameter stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		}

		NSMutableArray *trimmedKeyParts = [NSMutableArray array];
		for (NSString *part in [key componentsSeparatedByString:@"/"]) {
			NSString *trimmedPart = [part stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			[trimmedKeyParts addObject:[ApptentiveUtilities stringByEscapingForPredicate:trimmedPart]];
		}
		NSString *trimmedKey = [trimmedKeyParts componentsJoinedByString:@"/"];

		NSPredicate *predicate = nil;

		BOOL parameterIsArray = [parameter isKindOfClass:[NSArray class]];
		BOOL parameterIsDictionary = [parameter isKindOfClass:[NSDictionary class]];
		BOOL parameterIsComplexType = parameterIsDictionary && [((NSDictionary *)parameter).allKeys containsObject:@"_type"];
		BOOL parameterIsPrimitiveType = [parameter isKindOfClass:[NSString class]] || [parameter isKindOfClass:[NSNumber class]] || [parameter isKindOfClass:[NSNull class]];

		if (parameterIsPrimitiveType || parameterIsComplexType) {
			predicate = [self compoundPredicateForKeyPath:trimmedKey operatorsAndValues:@{ @"==": parameter }];
		} else if (parameterIsArray) {
			BOOL hasError = NO;
			NSCompoundPredicateType predicateType = [self compoundPredicateTypeFromString:trimmedKey hasError:&hasError];
			if (!hasError) {
				predicate = [self compoundPredicateWithType:predicateType criteriaArray:(NSArray *)parameter];
			}
		} else if (parameterIsDictionary) {
			NSDictionary *dictionaryValue = (NSDictionary *)parameter;
			if ([dictionaryValue.allKeys.firstObject isEqualToString:@"$not"]) {
				NSString *notKey = dictionaryValue.allKeys.firstObject;
				BOOL hasError;
				NSCompoundPredicateType predicateType = [self compoundPredicateTypeFromString:notKey hasError:&hasError];
				if (!hasError) {
					predicate = [self compoundPredicateWithType:predicateType criteriaArray:@[@{trimmedKey: dictionaryValue[notKey]}]];
				}
			} else if ([trimmedKey isEqualToString:@"$not"]) {
				// Work around "Common Law Feature" where $not expressions are incorrect
				BOOL hasError = NO;
				NSCompoundPredicateType predicateType = [self compoundPredicateTypeFromString:trimmedKey hasError:&hasError];
				if (!hasError) {
					predicate = [self compoundPredicateWithType:predicateType criteriaArray:@[parameter]];
				}
			} else {
				predicate = [self compoundPredicateForKeyPath:trimmedKey operatorsAndValues:(NSDictionary *)parameter];
			}
		}

		if (predicate) {
			[subPredicates addObject:predicate];
		} else {
			return nil;
		}
	}

	NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];

	return compoundPredicate;
}

+ (NSCompoundPredicate *)compoundPredicateWithType:(NSCompoundPredicateType)type criteriaArray:(NSArray *)criteriaArray {
	NSMutableArray *subPredicates = [NSMutableArray array];

	for (NSDictionary *criteria in criteriaArray) {
		NSPredicate *predicate = [self compoundPredicateWithCriteria:criteria];
		if (predicate) {
			[subPredicates addObject:predicate];
		} else {
			return nil;
		}
	}

	NSCompoundPredicate *compoundPredicate = [[NSCompoundPredicate alloc] initWithType:type subpredicates:subPredicates];

	return compoundPredicate;
}

+ (NSCompoundPredicate *)compoundPredicateForKeyPath:(NSString *)keyPath operatorsAndValues:(NSDictionary *)operatorsAndValues {
	NSMutableArray *subPredicates = [NSMutableArray array];

	for (NSString *operatorString in operatorsAndValues) {
		NSObject *parameter = operatorsAndValues[operatorString];
		if ([parameter isKindOfClass:[NSString class]]) {
			parameter = [(NSString *)parameter stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		}

		NSPredicate *predicate = nil;

		BOOL parameterIsDictionary = [parameter isKindOfClass:[NSDictionary class]];
		BOOL parameterIsPrimitiveType = [parameter isKindOfClass:[NSString class]] || [parameter isKindOfClass:[NSNumber class]] || [parameter isKindOfClass:[NSNull class]];

		if ([operatorString isEqualToString:@"$exists"]) {
			if ([parameter isEqual:@YES] || [parameter isEqual:@NO]) {
				NSString *predicateFormatString = [[@"(%K " stringByAppendingString:([(NSNumber *)parameter boolValue] ? @"!=" : @"==")] stringByAppendingString:@" nil)"];
				predicate = [NSPredicate predicateWithFormat:predicateFormatString, keyPath];
			} else {
				predicate = [NSPredicate predicateWithValue:NO];
			}
		} else if ([operatorString isEqualToString:@"$before"] || [operatorString isEqualToString:@"$after"]) {
			predicate = [NSPredicate predicateWithBlock:^BOOL(id _Nonnull evaluatedObject, NSDictionary<NSString *, id> *_Nullable bindings) {
				NSDictionary *complexValue = [evaluatedObject valueForKeyPath:keyPath];

				// $before and $after work with datetimes only.
				if ([complexValue[@"_type"] isEqualToString:@"datetime"]) {
					NSNumber *fieldValue = (NSNumber *)[complexValue valueForKey:@"sec"];
					NSNumber *parameterNumber = (NSNumber *)parameter;

					if (fieldValue && parameterNumber) {
						NSTimeInterval fieldSeconds = fieldValue.doubleValue;
						NSTimeInterval parameterSeconds = parameterNumber.doubleValue + [[NSDate date] timeIntervalSince1970];
						if ([operatorString isEqualToString:@"$before"]) {
							return fieldSeconds < parameterSeconds;
						} else {
							return fieldSeconds > parameterSeconds;
						}
					}
				}

				return NO;
			}];
		} else if (parameterIsPrimitiveType) {
			BOOL hasError;
			NSPredicateOperatorType operatorType = [self predicateOperatorTypeFromString:operatorString hasError:&hasError];
						if (!hasError && [self operator:operatorType isValidForParameter:parameter]) {
							predicate = [self predicateWithLeftKeyPath:keyPath rightValue:parameter operatorType:operatorType];
						} else {
							predicate = [NSPredicate predicateWithValue:NO];
						}
		} else if (parameterIsDictionary) {
			predicate = [NSCompoundPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
				BOOL hasError;
				NSPredicateOperatorType operatorType = [self predicateOperatorTypeFromString:operatorString hasError:&hasError];
				if (!hasError && [self operator:operatorType isValidForParameter:parameter]) {
					NSPredicate *localPredicate = [self predicateWithLeftKeyPath:keyPath forObject:evaluatedObject rightComplexObject:(NSDictionary *)parameter operatorType:operatorType];
					
					return [localPredicate evaluateWithObject:nil];
				} else {
					return NO;
				}
			}];
		}

		if (predicate) {
			[subPredicates addObject:predicate];
		} else {
			return nil;
		}
	}

	NSCompoundPredicate *compoundPredicate = [[NSCompoundPredicate alloc] initWithType:NSAndPredicateType subpredicates:subPredicates];

	return compoundPredicate;
}

+ (NSPredicate *)predicateWithLeftKeyPath:(NSString *)leftKeyPath rightValue:(nullable id)rightValue operatorType:(NSPredicateOperatorType)operatorType {
	[ApptentiveInteractionUsageData keyPathWasSeen:leftKeyPath];

	NSExpression *leftExpression = [NSExpression expressionForKeyPath:leftKeyPath];
	NSExpression *rightExpression = [NSExpression expressionForConstantValue:rightValue];

	return [self predicateWithLeftExpression:leftExpression rightExpression:rightExpression operatorType:operatorType];
}

+ (NSPredicate *)predicateWithLeftKeyPath:(NSString *)keyPath forObject:(NSDictionary *)context rightComplexObject:(NSDictionary *)rightComplexObject operatorType:(NSPredicateOperatorType)operatorType {
	NSDictionary *leftComplexObject = [context valueForKeyPath:keyPath];
	NSString *type = leftComplexObject[@"_type"];
	NSString *rightType = rightComplexObject[@"_type"];
	if (![type isEqualToString:rightType]) {
		ApptentiveLogError(@"Criteria Complex Type objects must be of the same type!");
		return nil;
	}

	NSObject *leftValue;
	NSObject *rightValue;

	if ([type isEqualToString:@"version"]) {
		NSString *leftVersion = leftComplexObject[@"version"];
		NSString *rightVersion = rightComplexObject[@"version"];

		NSComparisonResult result = [ApptentiveUtilities compareVersionString:leftVersion toVersionString:rightVersion];

		switch (result) {
			case NSOrderedAscending:
				leftValue = @0;
				rightValue = @1;
				break;
			case NSOrderedDescending:
				leftValue = @1;
				rightValue = @0;
				break;
			case NSOrderedSame:
				leftValue = @1;
				rightValue = @1;
				break;
		}
	} else if ([type isEqualToString:@"datetime"]) {
		leftValue = leftComplexObject[@"sec"];
		rightValue = rightComplexObject[@"sec"];
	}

	NSPredicate *predicate = [self predicateWithLeftValue:leftValue rightValue:rightValue operatorType:operatorType];

	return predicate;
}

+ (NSPredicate *)predicateWithLeftValue:(nullable id)leftValue rightValue:(nullable id)rightValue operatorType:(NSPredicateOperatorType)operatorType {
	NSExpression *leftExpression = [NSExpression expressionForConstantValue:leftValue];
	NSExpression *rightExpression = [NSExpression expressionForConstantValue:rightValue];

	return [self predicateWithLeftExpression:leftExpression rightExpression:rightExpression operatorType:operatorType];
}

+ (NSPredicate *)predicateWithLeftExpression:(NSExpression *)leftExpression rightExpression:(NSExpression *)rightExpression operatorType:(NSPredicateOperatorType)operatorType {
	NSComparisonPredicateOptions options;
	Class comparisonClass;
	switch (operatorType) {
		case NSContainsPredicateOperatorType:
		case NSBeginsWithPredicateOperatorType:
		case NSEndsWithPredicateOperatorType:
			options = NSCaseInsensitivePredicateOption;
			comparisonClass = [NSString class];
			break;
		case NSGreaterThanOrEqualToPredicateOperatorType:
		case NSGreaterThanPredicateOperatorType:
		case NSLessThanPredicateOperatorType:
		case NSLessThanOrEqualToPredicateOperatorType:
			comparisonClass = [NSNumber class];
		// fall through
		default:
			options = 0;
			break;
	}

	NSComparisonPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:leftExpression
																		  rightExpression:rightExpression
																				 modifier:NSDirectPredicateModifier
																					 type:operatorType
																				  options:options];
	if (comparisonClass) {
		NSExpression *nilExpression = [NSExpression expressionForConstantValue:nil];
		NSPredicate *notNilPredicate = [NSComparisonPredicate predicateWithLeftExpression:leftExpression rightExpression:nilExpression modifier:NSDirectPredicateModifier type:NSNotEqualToPredicateOperatorType options:0];
		NSExpression *classExpression = [NSExpression expressionForConstantValue:comparisonClass];
		NSComparisonPredicate *typePredicate = [NSComparisonPredicate predicateWithLeftExpression:leftExpression rightExpression:classExpression customSelector:@selector(isKindOfClass:)];
		return [[NSCompoundPredicate alloc] initWithType:NSAndPredicateType subpredicates:@[notNilPredicate, typePredicate, predicate]];
	} else {
		return predicate;
	}
}

+ (NSCompoundPredicateType)compoundPredicateTypeFromString:(NSString *)predicateTypeString hasError:(nonnull BOOL *)hasError {
	*hasError = NO;
	if ([predicateTypeString isEqualToString:@"$and"]) {
		return NSAndPredicateType;
	} else if ([predicateTypeString isEqualToString:@"$or"]) {
		return NSOrPredicateType;
	} else if ([predicateTypeString isEqualToString:@"$not"]) {
		return NSNotPredicateType;
	} else {
		ApptentiveLogError(@"Expected `$and`, `$or`, or `$not` skey; instead saw key: %@", predicateTypeString);
		*hasError = YES;
		return NSAndPredicateType;
	}
}

+ (NSPredicateOperatorType)predicateOperatorTypeFromString:(NSString *)operatorString hasError:(nonnull BOOL *)hasError {
	*hasError = NO;
	if ([operatorString isEqualToString:@"$eq"] || [operatorString isEqualToString:@"=="]) {
		return NSEqualToPredicateOperatorType;
	} else if ([operatorString isEqualToString:@"$gt"] || [operatorString isEqualToString:@">"]) {
		return NSGreaterThanPredicateOperatorType;
	} else if ([operatorString isEqualToString:@"$gte"] || [operatorString isEqualToString:@">="]) {
		return NSGreaterThanOrEqualToPredicateOperatorType;
	} else if ([operatorString isEqualToString:@"$lt"] || [operatorString isEqualToString:@"<"]) {
		return NSLessThanPredicateOperatorType;
	} else if ([operatorString isEqualToString:@"$lte"] || [operatorString isEqualToString:@"<="]) {
		return NSLessThanOrEqualToPredicateOperatorType;
	} else if ([operatorString isEqualToString:@"$ne"] || [operatorString isEqualToString:@"!="]) {
		return NSNotEqualToPredicateOperatorType;
	} else if ([operatorString isEqualToString:@"$contains"] || [operatorString isEqualToString:@"CONTAINS[c]"]) {
		return NSContainsPredicateOperatorType;
	} else if ([operatorString isEqualToString:@"$starts_with"] || [operatorString isEqualToString:@"BEGINSWITH[c]"]) {
		return NSBeginsWithPredicateOperatorType;
	} else if ([operatorString isEqualToString:@"$ends_with"] || [operatorString isEqualToString:@"ENDSWITH[c]"]) {
		return NSEndsWithPredicateOperatorType;
	} else {
		ApptentiveLogError(@"Unrecognized comparison operator symbol: %@", operatorString);
		*hasError = YES;
		return NSCustomSelectorPredicateOperatorType;
	}
}

+ (BOOL) operator:(NSPredicateOperatorType) operator isValidForParameter:(NSObject *)parameter {
	BOOL isString = [parameter isKindOfClass:[NSString class]];

	switch (operator) {
		case NSEqualToPredicateOperatorType:
		case NSNotEqualToPredicateOperatorType:
		case NSLessThanOrEqualToPredicateOperatorType:
		case NSGreaterThanOrEqualToPredicateOperatorType:
		case NSGreaterThanPredicateOperatorType:
		case NSLessThanPredicateOperatorType:
			return YES;
		case NSBeginsWithPredicateOperatorType:
		case NSEndsWithPredicateOperatorType:
		case NSContainsPredicateOperatorType:
			return isString;
		default:
			ApptentiveLogError(@"Unrecognized predicate operator type: %uld", (unsigned long)operator);
			return NO;
	}
}

@end
