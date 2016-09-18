#import <OBAKit/OBAArrivalAndDepartureInstanceRef.h>
#import <OBAKit/NSObject+OBADescription.h>

@implementation OBAArrivalAndDepartureInstanceRef

- (instancetype)initWithTripInstance:(OBATripInstanceRef*)tripInstance stopId:(NSString*)stopId stopSequence:(NSInteger)stopSequence {
    self = [super init];

    if (self) {
        _tripInstance = tripInstance;
        _stopId = stopId;
        _stopSequence = stopSequence;
    }
    return self;
}

- (BOOL)isEqual:(OBAArrivalAndDepartureInstanceRef*)instanceRef {

    if (self == instanceRef) {
        return YES;
    }

    if (![instanceRef isKindOfClass:self.class]) {
        return NO;
    }

    if (![self.tripInstance isEqual:instanceRef.tripInstance]) {
        return NO;
    }

    if (![self.stopId isEqual:instanceRef.stopId]) {
        return NO;
    }

    if (self.stopSequence != instanceRef.stopSequence) {
        return NO;
    }

    return YES;
}

- (NSString*)description {
    return [self oba_description:@[@"tripInstance", @"stopId", @"stopSequence"]];
}

@end
