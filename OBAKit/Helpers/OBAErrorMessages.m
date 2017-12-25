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

+ (NSError*)errorFromHttpResponse:(NSHTTPURLResponse*)httpResponse {
    if (httpResponse.statusCode == 404) {
        return OBAErrorMessages.stopNotFoundError;
    }
    else if (httpResponse.statusCode >= 300 && httpResponse.statusCode <= 399) {
        return [OBAErrorMessages connectionError:httpResponse];
    }

    return nil;
}

+ (NSError*)stopNotFoundError {
    return [NSError errorWithDomain:NSURLErrorDomain code:404 userInfo:@{NSLocalizedDescriptionKey: OBALocalized(@"mgs_stop_not_found", @"code == 404")}];
}

+ (NSError*)connectionError:(NSHTTPURLResponse*)response {
    NSString *message = OBALocalized(@"msg_error_connecting", @"code != 404");
    return [NSError errorWithDomain:NSURLErrorDomain code:response.statusCode userInfo:@{NSLocalizedDescriptionKey: message}];
}

+ (NSError*)cannotRegisterAlarm {
    return [NSError errorWithDomain:OBAErrorDomain code:OABErrorCodeMissingMethodParameters userInfo:@{NSLocalizedDescriptionKey: OBALocalized(@"model_service.cant_register_alarm_missing_parameters", @"An error displayed to the user when their alarm can't be created.")}];
}

@end
