//
//  OBAWeatherForecast.m
//  OBAKit
//
//  Created by Aaron Brethorst on 5/20/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAWeatherForecast.h>

@implementation OBAWeatherForecast

#pragma mark - Mantle

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"latitude": @"latitude",
             @"longitude": @"longitude",
             @"regionIdentifier": @"region_identifier",
             @"regionName": @"region_name",
             @"forecastRetrievedAt": @"retrieved_at",
             @"currentSummary": @"currently.summary",
             @"currentSummaryIconName": @"currently.icon",
             @"currentPrecipProbability": @"currently.precipProbability",
             @"currentTemperature": @"currently.temperature"
             };
}

+ (NSDateFormatter *)dateFormatter {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    return dateFormatter;
}

+ (NSValueTransformer *)forecastRetrievedAtJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *dateString, BOOL *success, NSError *__autoreleasing *error) {
        return [self.dateFormatter dateFromString:dateString];
    } reverseBlock:^id(NSDate *date, BOOL *success, NSError *__autoreleasing *error) {
        return [self.dateFormatter stringFromDate:date];
    }];
}

#pragma mark - IGListDiffable

- (nonnull id<NSObject>)diffIdentifier {
    return self;
}

/**
 Returns whether the receiver and a given object are equal.

 @param object The object to be compared to the receiver.

 @return `YES` if the receiver and object are equal, otherwise `NO`.
 */
- (BOOL)isEqualToDiffableObject:(nullable id<IGListDiffable,NSObject>)object {
    if (![object isKindOfClass:OBAWeatherForecast.class]) {
        return NO;
    }

    OBAWeatherForecast *other = (OBAWeatherForecast *)object;
    return [self.forecastRetrievedAt isEqual:other.forecastRetrievedAt];
}

@end
