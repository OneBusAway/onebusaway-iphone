//
//  ApptentiveSurveyViewModel.m
//  CVSurvey
//
//  Created by Frank Schmitt on 2/23/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyViewModel.h"
#import "ApptentiveSurvey.h"
#import "ApptentiveSurveyQuestion.h"
#import "ApptentiveSurveyAnswer.h"

#import "Apptentive_Private.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveSurveyResponse.h"
#import "ApptentiveSurveyResponseTask.h"
#import "ApptentiveTaskQueue.h"
#import "ApptentiveData.h"

NSString *const ApptentiveInteractionSurveyEventLabelQuestionResponse = @"question_response";
NSString *const ApptentiveInteractionSurveyEventLabelSubmit = @"submit";
NSString *const ApptentiveInteractionSurveyEventLabelCancel = @"cancel";


@interface ApptentiveSurveyViewModel ()

@property (copy, nonatomic) NSString *currentMultilineText;
@property (strong, nonatomic) NSMutableSet *selectedIndexPaths;
@property (strong, nonatomic) NSMutableDictionary *textAtIndexPath;
@property (strong, nonatomic) NSMutableIndexSet *invalidQuestionIndexes;
@property (strong, nonatomic) NSMutableSet *invalidAnswerIndexPaths;

@end


@implementation ApptentiveSurveyViewModel

- (instancetype)initWithInteraction:(ApptentiveInteraction *)interaction {
	self = [super init];
	if (self) {
		_interaction = interaction;

		@try {
			_survey = [[ApptentiveSurvey alloc] initWithJSON:interaction.configuration];
		} @catch (NSException *exception) {
			ApptentiveLogError(@"Unable to parse survey.");
			return nil;
		}

		_selectedIndexPaths = [NSMutableSet set];
		_textAtIndexPath = [NSMutableDictionary dictionary];
	}
	return self;
}

- (id<ApptentiveStyle>)styleSheet {
	return [Apptentive sharedConnection].styleSheet;
}

- (NSString *)title {
	return self.survey.name;
}

- (NSString *)greeting {
	return self.survey.surveyDescription;
}

- (NSString *)submitButtonText {
	return self.survey.submitText;
}

- (BOOL)showThankYou {
	return self.survey.showSuccessMessage;
}

- (NSString *)thankYouText {
	return self.survey.successMessage;
}

- (NSString *)missingRequiredItemText {
	return self.survey.validationErrorText;
}

- (NSInteger)numberOfQuestionsInSurvey {
	return self.survey.questions.count;
}

- (NSInteger)numberOfAnswersForQuestionAtIndex:(NSInteger)index {
	if ([self typeOfQuestionAtIndex:index] == ATSurveyQuestionTypeSingleLine || [self typeOfQuestionAtIndex:index] == ATSurveyQuestionTypeMultipleLine) {
		return 1;
	} else if ([self typeOfQuestionAtIndex:index] == ATSurveyQuestionTypeRange) {
		ApptentiveSurveyQuestion *question = [self questionAtIndex:index];

		return 1 + question.maximumValue - question.minimumValue;
	} else {
		return [self questionAtIndex:index].answers.count;
	}
}

- (NSString *)textOfQuestionAtIndex:(NSInteger)index {
	return [self questionAtIndex:index].value;
}

- (NSAttributedString *)instructionTextOfQuestionAtIndex:(NSInteger)index {
	NSMutableArray *parts = [NSMutableArray array];
	NSInteger redCharacterCount = 0;

	if ([self questionAtIndex:index].required) {
		[parts addObject:self.survey.requiredText ?: ApptentiveLocalizedString(@"required", nil)];
		redCharacterCount = self.survey.requiredText.length;
	}

	if ([self questionAtIndex:index].instructions) {
		[parts addObject:[self questionAtIndex:index].instructions];
	}

	if (parts.count > 0) {
		NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:[parts componentsJoinedByString:@" – "]];

		if (redCharacterCount > 0) {
			[result addAttributes:@{ NSForegroundColorAttributeName: [self.styleSheet colorForStyle:ApptentiveColorFailure] } range:NSMakeRange(0, redCharacterCount)];
		}
		[result addAttributes:@{ NSForegroundColorAttributeName: [self.styleSheet colorForStyle:ApptentiveTextStyleSurveyInstructions] } range:NSMakeRange(redCharacterCount, result.length - redCharacterCount)];

		return result;
	} else {
		return nil;
	}
}

- (NSAttributedString *)placeholderTextOfAnswerAtIndexPath:(NSIndexPath *)indexPath {
	NSString *placeholder;
	ApptentiveSurveyQuestion *question = [self questionAtIndex:indexPath.section];

	if (question.type == ATSurveyQuestionTypeSingleLine || question.type == ATSurveyQuestionTypeMultipleLine) {
		placeholder = [self questionAtIndex:indexPath.section].placeholder ?: @"";
	} else {
		placeholder = [self answerAtIndexPath:indexPath].placeholder ?: @"";
	}

	return [[NSAttributedString alloc] initWithString:placeholder attributes:@{NSForegroundColorAttributeName: [self.styleSheet colorForStyle:ApptentiveColorTextInputPlaceholder]}];
}

- (NSString *)textOfChoiceAtIndexPath:(NSIndexPath *)indexPath {
	return [self answerAtIndexPath:indexPath].value;
}

- (NSString *)textOfAnswerAtIndexPath:(NSIndexPath *)indexPath {
	return self.textAtIndexPath[indexPath];
}

- (BOOL)answerIsSelectedAtIndexPath:(NSIndexPath *)indexPath {
	return [self.selectedIndexPaths containsObject:indexPath];
}

- (ATSurveyQuestionType)typeOfQuestionAtIndex:(NSInteger)index {
	return [self questionAtIndex:index].type;
}

- (ApptentiveSurveyAnswerType)typeOfAnswerAtIndexPath:(NSIndexPath *)indexPath {
	return [self answerAtIndexPath:indexPath].type;
}

- (NSString *)minimumLabelForQuestionAtIndex:(NSInteger)index {
	return [self questionAtIndex:index].minimumLabel;
}

- (NSString *)maximumLabelForQuestionAtIndex:(NSInteger)index {
	return [self questionAtIndex:index].maximumLabel;
}

- (BOOL)answerIsValidForQuestionAtIndex:(NSInteger)index {
	return ![self.invalidQuestionIndexes containsIndex:index];
}

- (BOOL)answerIsValidAtIndexPath:(NSIndexPath *)indexPath {
	return ![self.invalidAnswerIndexPaths containsObject:indexPath];
}

- (NSIndexPath *)indexPathForTextFieldTag:(NSInteger)tag {
	return [NSIndexPath indexPathForItem:tag & 0xFFFF inSection:tag >> 16];
}

- (NSInteger)textFieldTagForIndexPath:(NSIndexPath *)indexPath {
	return (indexPath.section << 16) | (indexPath.item & 0xFFFF);
}

#pragma mark - Mutation

- (void)setText:(NSString *)text forAnswerAtIndexPath:(NSIndexPath *)indexPath {
	[self.textAtIndexPath setObject:text forKey:indexPath];

	if (self.invalidQuestionIndexes) {
		[self validate:NO];
	}
}

- (void)commitChangeAtIndexPath:(NSIndexPath *)indexPath {
	[self answerChangedAtIndexPath:indexPath];
}

- (void)selectAnswerAtIndexPath:(NSIndexPath *)indexPath {
	if ([self.selectedIndexPaths containsObject:indexPath])
		return;

	[self.selectedIndexPaths addObject:indexPath];

	if ([self typeOfQuestionAtIndex:indexPath.section] == ATSurveyQuestionTypeSingleSelect || [self typeOfQuestionAtIndex:indexPath.section] == ATSurveyQuestionTypeRange) {
		for (NSInteger answerIndex = 0; answerIndex < [self numberOfAnswersForQuestionAtIndex:indexPath.section]; answerIndex++) {
			if (answerIndex != indexPath.item) {
				NSIndexPath *deselectIndexPath = [NSIndexPath indexPathForItem:answerIndex inSection:indexPath.section];
				if ([self.selectedIndexPaths containsObject:deselectIndexPath]) {
					[self.selectedIndexPaths removeObject:deselectIndexPath];
					[self.delegate viewModel:self didDeselectAnswerAtIndexPath:deselectIndexPath];
				}
			}
		}
	}

	[self answerChangedAtIndexPath:indexPath];

	if (self.invalidQuestionIndexes) {
		[self validate:NO];
	}
}

- (void)deselectAnswerAtIndexPath:(NSIndexPath *)indexPath {
	[self.selectedIndexPaths removeObject:indexPath];

	[self answerChangedAtIndexPath:indexPath];

	if (self.invalidQuestionIndexes) {
		[self validate:NO];
	}
}

- (void)submit {
	ApptentiveSurveyResponse *response = (ApptentiveSurveyResponse *)[ApptentiveData newEntityNamed:@"ATSurveyResponse"];

	[response setup];
	response.pendingState = [NSNumber numberWithInt:ATPendingSurveyResponseStateSending];
	response.surveyID = self.interaction.identifier;
	[response updateClientCreationTime];
	[response setAnswers:self.answers];
	[ApptentiveData save];

	NSString *pendingSurveyResponseID = [response pendingSurveyResponseID];
	double delayInSeconds = 1.5;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
		ApptentiveSurveyResponseTask *task = [[ApptentiveSurveyResponseTask alloc] init];
		task.pendingSurveyResponseID = pendingSurveyResponseID;
		[[ApptentiveTaskQueue sharedTaskQueue] addTask:task];
	});
}

#pragma mark - Validation & Output

- (BOOL)validate:(BOOL)isSubmit {
	NSIndexSet *previousInvalidQuestionIndexes = self.invalidQuestionIndexes;
	NSSet *previousInvalidAnswerIndexPaths = [self.invalidAnswerIndexPaths copy];

	self.invalidQuestionIndexes = [NSMutableIndexSet indexSet];
	self.invalidAnswerIndexPaths = [NSMutableSet set];

	[self.survey.questions enumerateObjectsUsingBlock:^(ApptentiveSurveyQuestion *_Nonnull question, NSUInteger questionIndex, BOOL *_Nonnull questionsStop) {
		switch (question.type) {
			case ATSurveyQuestionTypeSingleLine:
			case ATSurveyQuestionTypeMultipleLine: {
				NSIndexPath *answerIndexPath = [NSIndexPath indexPathForItem:0 inSection:questionIndex];
				if (question.required && ![self textFieldHasTextAtIndexPath:answerIndexPath]) {
					[self.invalidQuestionIndexes addIndex:questionIndex];
					[self.invalidAnswerIndexPaths addObject:answerIndexPath];
				}
				break;
			}
			case ATSurveyQuestionTypeSingleSelect:
			case ATSurveyQuestionTypeMultipleSelect: {
				NSInteger __block numberOfSelections = 0;

				[question.answers enumerateObjectsUsingBlock:^(ApptentiveSurveyAnswer * _Nonnull answer, NSUInteger answerIndex, BOOL * _Nonnull answersStop) {
					NSIndexPath *answerIndexPath = [NSIndexPath indexPathForItem:answerIndex inSection:questionIndex];

					if ([self.selectedIndexPaths containsObject:answerIndexPath]) {
						numberOfSelections ++;

						if (question.required && answer.type == ApptentiveSurveyAnswerTypeOther && ![self textFieldHasTextAtIndexPath:answerIndexPath]) {
							[self.invalidAnswerIndexPaths addObject:answerIndexPath];
							[self.invalidQuestionIndexes addIndex:questionIndex];
						}
					}
				}];

				BOOL numberOfSelectionsOutOfRange = numberOfSelections	> question.maximumSelectedCount || numberOfSelections < question.minimumSelectedCount;
				if ((question.required || numberOfSelections != 0) && numberOfSelectionsOutOfRange) {
					[self.invalidQuestionIndexes addIndex:questionIndex];
				}

				break;
			}
			case ATSurveyQuestionTypeRange:
				if (question.required) {
					if ([self selectedIndexPathsForQuestionAtIndex:questionIndex].count == 0) {
						[self.invalidQuestionIndexes addIndex:questionIndex];
					}
				}

				break;
		}
	}];

	// Unless the submit button was tapped, only allow answers to go from red to green
	if (!isSubmit) {
		NSMutableIndexSet *redToGreenQuestionIndexes = [self.invalidQuestionIndexes mutableCopy];
		[self.invalidQuestionIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *_Nonnull stop) {
			if (![previousInvalidQuestionIndexes containsIndex:idx]) {
				[redToGreenQuestionIndexes removeIndex:idx];
			}
		}];

		self.invalidQuestionIndexes = redToGreenQuestionIndexes;

		NSMutableSet *redToGreenAnswerIndexPaths = [self.invalidAnswerIndexPaths mutableCopy];
		[self.invalidAnswerIndexPaths enumerateObjectsUsingBlock:^(id _Nonnull obj, BOOL *_Nonnull stop) {
			if (![previousInvalidAnswerIndexPaths containsObject:obj]) {
				[redToGreenAnswerIndexPaths removeObject:obj];
			}
		}];

		self.invalidAnswerIndexPaths = redToGreenAnswerIndexPaths;
	}

	if (![self.invalidQuestionIndexes isEqualToIndexSet:previousInvalidQuestionIndexes]) {
		[self.delegate viewModelValidationChanged:self isValid:self.invalidQuestionIndexes.count == 0];
	}

	return self.invalidQuestionIndexes.count == 0;
}

- (NSDictionary *)answers {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];

	[self.survey.questions enumerateObjectsUsingBlock:^(ApptentiveSurveyQuestion *_Nonnull question, NSUInteger questionIndex, BOOL *_Nonnull stop) {
		NSMutableArray *responses = [NSMutableArray array];
		switch (question.type) {
			case ATSurveyQuestionTypeSingleLine:
			case ATSurveyQuestionTypeMultipleLine: {
				NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:questionIndex];

				if ([self textFieldHasTextAtIndexPath:indexPath]) {
					[responses addObject:@{ @"value": [self trimmedTextAtIndexPath:indexPath] }];
				}
				break;
			}
			case ATSurveyQuestionTypeSingleSelect: {
				NSArray *selections = [self selectedIndexPathsForQuestionAtIndex:questionIndex];

				if (selections.count == 1) {
					[responses addObject:[self responseDictionaryForAnswerAtIndexPath:selections.firstObject]];
				}
				break;
			}
			case ATSurveyQuestionTypeMultipleSelect:
				for (NSIndexPath *indexPath in [self selectedIndexPathsForQuestionAtIndex:questionIndex]) {
					[responses addObject:[self responseDictionaryForAnswerAtIndexPath:indexPath]];
				}

				break;
			case ATSurveyQuestionTypeRange: {
				NSArray<NSIndexPath *> *selections = [self selectedIndexPathsForQuestionAtIndex:questionIndex];

				if (selections.count == 1) {
					[responses addObject:@{ @"value": @(selections.firstObject.item + question.minimumValue) }];
				}
				break;
			}

		}

		if (responses.count > 0) {
			result[question.identifier] = responses;
		}
	}];

	return result;
}

#pragma mark - Metrics

- (void)answerChangedAtIndexPath:(NSIndexPath *)indexPath {
	ApptentiveSurveyQuestion *question = [self questionAtIndex:indexPath.section];

	[self.interaction engage:ApptentiveInteractionSurveyEventLabelQuestionResponse fromViewController:nil userInfo:@{ @"id": question.identifier ?: [NSNull null] }];
}

- (void)didCancel:(UIViewController *)presentingViewController {
	[self.interaction engage:ApptentiveInteractionSurveyEventLabelCancel fromViewController:presentingViewController];
}

- (void)didSubmit:(UIViewController *)presentingViewController {
	[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveSurveySentNotification object:@{ApptentiveSurveyIDKey: self.interaction.identifier}];
	[self.interaction engage:ApptentiveInteractionSurveyEventLabelSubmit fromViewController:presentingViewController];
}

#pragma mark - Private

- (ApptentiveSurveyQuestion *)questionAtIndex:(NSInteger)index {
	return [self.survey.questions objectAtIndex:index];
}

- (ApptentiveSurveyAnswer *)answerAtIndexPath:(NSIndexPath *)indexPath {
	NSArray *answers = [self questionAtIndex:indexPath.section].answers;

	return answers.count > (NSUInteger)indexPath.row ? answers[indexPath.row] : nil;
}

- (NSArray<NSIndexPath *> *)selectedIndexPathsForQuestionAtIndex:(NSInteger)index {
	NSMutableArray *result = [NSMutableArray array];

	for (NSIndexPath *indexPath in self.selectedIndexPaths) {
		if (indexPath.section != index) {
			continue;
		} else {
			[result addObject:indexPath];
		}
	}

	return result;
}

- (NSDictionary *)responseDictionaryForAnswerAtIndexPath:(NSIndexPath *)indexPath {
	ApptentiveSurveyAnswer *answer = [self answerAtIndexPath:indexPath];
	NSMutableDictionary *response;
	NSString *answerIdentifier = answer.identifier;

	if (answerIdentifier != nil) {
		response = [NSMutableDictionary dictionaryWithObject:answerIdentifier forKey:@"id"];

		if (answer.type == ApptentiveSurveyAnswerTypeOther) {
			response[@"value"] = [self trimmedTextAtIndexPath:indexPath] ?: @"";
		}
	}

	return response;
}

- (NSString *)trimmedTextAtIndexPath:(NSIndexPath *)indexPath {
	return [self.textAtIndexPath[indexPath] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (BOOL)textFieldHasTextAtIndexPath:(NSIndexPath *)indexPath {
	return [self trimmedTextAtIndexPath:indexPath].length > 0;
}

@end
