//
//  OBARegionalAlert.m
//  OBAKit
//
//  Created by Aaron Brethorst on 3/16/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

#import <OBAKit/OBARegionalAlert.h>

@implementation OBARegionalAlert

- (instancetype)init {
    self = [super init];

    if (self) {
        _unread = YES;
    }
    return self;
}

#pragma mark - MTLJSONSerializing

- (void)setNilValueForKey:(NSString *)key {
    /*
        `unread` isn't actually part of the JSON bolus that gets sent from the
        server. And so originally I wasn't including it in +JSONKeyPathsByPropertyKey.
        Because of that, it wasn't being persisted out when I wrote models out in the
        manager. Now that I've added it, i've also created setNilValueForKey so as
        to override the nil -> falsy conversion that would happen with it.
    */
    if ([key isEqual:@"unread"]) {
        self.unread = YES;
    }
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"unread": @"unread",
             @"identifier": @"id",
             @"title": @"title",
             @"feedName": @"alert_feed_name",
             @"priority": @"priority",
             @"summary": @"summary",
             @"URL": @"url",
             @"alertFeedID": @"alert_feed_id",
             @"publishedAt": @"published_at",
             @"externalID": @"external_id"
             };
}

#pragma mark - Transformers

+ (NSValueTransformer *)publishedAtJSONTransformer {

    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    });

    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *dateString, BOOL *success, NSError *__autoreleasing *error) {
        return [dateFormatter dateFromString:dateString];
    } reverseBlock:^id(NSDate *date, BOOL *success, NSError *__autoreleasing *error) {
        return [dateFormatter stringFromDate:date];
    }];
}

@end
