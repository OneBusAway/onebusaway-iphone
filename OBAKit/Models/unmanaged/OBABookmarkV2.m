#import "OBABookmarkV2.h"

#define IDENTIFIER_SEL NSStringFromSelector(@selector(regionIdentifier))
#define NAME_SEL NSStringFromSelector(@selector(name))
#define STOP_ID_SEL NSStringFromSelector(@selector(stopID))

@implementation OBABookmarkV2

#pragma mark - NSCoder

- (id)initWithCoder:(NSCoder*)coder {
    if (self = [super init]) {
        _name = [coder decodeObjectForKey:NAME_SEL];

        // Handle legacy bookmark models.
        NSArray *stopIds = [coder decodeObjectForKey:@"stopIds"];
        if (stopIds && stopIds.count > 0) {
            _stopID = stopIds[0];
        }
        else {
            _stopID = [coder decodeObjectForKey:STOP_ID_SEL];
        }

        // Normally, we'd simply try decoding the object and use the fact that
        // nil would simply resolve to 0, but the Tampa region has the ID of 0,
        // so we're stuck trying to be clever here to work around that issue.
        if ([coder containsValueForKey:IDENTIFIER_SEL]) {
            _regionIdentifier = [coder decodeIntegerForKey:IDENTIFIER_SEL];
        }
        else {
            _regionIdentifier = NSNotFound;
        }
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder*)coder {
    [coder encodeObject:_name forKey:NAME_SEL];
    [coder encodeObject:_stopID forKey:STOP_ID_SEL];
    [coder encodeInteger:_regionIdentifier forKey:IDENTIFIER_SEL];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<%@: %p> :: {name: %@, group: %@, stopID: %@, regionIdentifier: %@}", self.class, self, self.name, self.group, self.stopID, @(self.regionIdentifier)];
}

@end
