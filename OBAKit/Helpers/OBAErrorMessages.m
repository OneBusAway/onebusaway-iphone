//
//  OBAErrorMessages.m
//  OBAKit
//
//  Created by Aaron Brethorst on 11/5/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAErrorMessages.h>
#import <OBAKit/OBAMacros.h>

@implementation OBAErrorMessages

+ (NSError*)buildErrorForBadData:(nullable id)badData {
    NSDictionary *userInfo = nil;

    if (badData == NSNull.null) {
        userInfo = @{@"issue": @"Data == NSNull.null"};
    }
    else if (!badData) {
        userInfo = @{@"issue": @"Data == nil"};
    }
    else if ([badData respondsToSelector:@selector(description)]) {
        userInfo = @{@"data": [badData description]};
    }
    else {
        userInfo = @{@"issue": @"I have no idea what's going on. It isn't nil or NSNull, and it doesn't respond to -description."};
    }

    return [[NSError alloc] initWithDomain:OBAErrorDomain code:OBAErrorCodeBadData userInfo:userInfo];
}

+ (NSError*)errorFromHttpResponse:(NSHTTPURLResponse*)httpResponse {
    if (httpResponse.statusCode >= 500) {
        return OBAErrorMessages.serverError;
    }
    else if (httpResponse.statusCode == 404) {
        if ([httpResponse.URL.path containsString:@"trip-for-vehicle"]) {
            return OBAErrorMessages.vehicleNotFoundError;
        }
        else {
            return OBAErrorMessages.stopNotFoundError;
        }
    }
    else if (httpResponse.statusCode >= 300 && httpResponse.statusCode <= 399) {
        return [OBAErrorMessages connectionError:httpResponse];
    }

    return nil;
}

+ (NSError*)unknownErrorFromResponse:(NSHTTPURLResponse*)httpResponse {
    NSError *error = [self errorFromHttpResponse:httpResponse];

    if (error) {
        return error;
    }

    NSString *message = [NSString stringWithFormat:@"Unknown error from server response: %@", httpResponse.URL];
    return [NSError errorWithDomain:OBAErrorDomain code:OBAErrorCodeBadData userInfo:@{NSLocalizedDescriptionKey: message}];
}

+ (NSError*)serverError {
    return [NSError errorWithDomain:NSURLErrorDomain code:500 userInfo:@{NSLocalizedDescriptionKey: OBALocalized(@"error_messages.server_error", @"code == 500")}];
}

+ (NSError*)stopNotFoundError {
    return [NSError errorWithDomain:NSURLErrorDomain code:404 userInfo:@{NSLocalizedDescriptionKey: OBALocalized(@"mgs_stop_not_found", @"code == 404")}];
}

+ (NSError*)vehicleNotFoundError {
    return [NSError errorWithDomain:OBAErrorDomain code:404 userInfo:@{NSLocalizedDescriptionKey: OBALocalized(@"error_messages.vehicle_not_found", @"Search for Vehicle ID produced no results.")}];
}

+ (NSError*)connectionError:(NSHTTPURLResponse*)response {
    NSString *message = OBALocalized(@"msg_error_connecting", @"code != 404");
    return [NSError errorWithDomain:NSURLErrorDomain code:response.statusCode userInfo:@{NSLocalizedDescriptionKey: message}];
}

+ (NSError*)cannotRegisterAlarm {
    return [NSError errorWithDomain:OBAErrorDomain code:OBAErrorCodeMissingMethodParameters userInfo:@{NSLocalizedDescriptionKey: OBALocalized(@"model_service.cant_register_alarm_missing_parameters", @"An error displayed to the user when their alarm can't be created.")}];
}

@end
