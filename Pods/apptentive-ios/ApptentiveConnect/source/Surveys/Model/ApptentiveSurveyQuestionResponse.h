//
//  ApptentiveSurveyQuestionResponse.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 4/22/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ApptentiveSurveyQuestionResponse : NSObject <NSCoding>
@property (copy, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSObject<NSCoding> *response;

@end
