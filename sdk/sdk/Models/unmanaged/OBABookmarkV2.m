#import "OBABookmarkV2.h"


@implementation OBABookmarkV2

- (id) initWithCoder:(NSCoder*)coder {
    if( self = [super init] ) {
        _name = [coder decodeObjectForKey:@"name"];

        // Handle legacy bookmark models.
        NSArray *stopIds = [coder decodeObjectForKey:@"stopIds"];
        if (stopIds && stopIds.count > 0) {
            _stopID = stopIds[0];
        }
        else {
            _stopID = [coder decodeObjectForKey:@"stopID"];
        }

        _routeShortName = [coder decodeObjectForKey:@"routeShortName"];
    }
    return self;
}

#pragma mark NSCoder Methods

- (void) encodeWithCoder: (NSCoder *)coder {
    [coder encodeObject:_name forKey:@"name"];
    [coder encodeObject:_stopID forKey:@"stopID"];
    [coder encodeObject:_routeShortName forKey:@"routeShortName"];
}

- (NSString*)debugDescription {
    return [NSString stringWithFormat:@"<%@: %p> :: {name: %@, group: %@, routeShortName: %@, stopID: %@}", self.class, self, self.name, self.group, self.routeShortName, self.stopID];
}

@end
