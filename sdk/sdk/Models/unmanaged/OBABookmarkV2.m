#import "OBABookmarkV2.h"


@implementation OBABookmarkV2

- (id) initWithCoder:(NSCoder*)coder {
    if( self = [super init] ) {
        _name = [coder decodeObjectForKey:@"name"];
        _stopIds = [coder decodeObjectForKey:@"stopIds"];
    }
    return self;
}

#pragma mark NSCoder Methods

- (void) encodeWithCoder: (NSCoder *)coder {
    [coder encodeObject:_name forKey:@"name"];
    [coder encodeObject:_stopIds forKey:@"stopIds"];
}

- (NSString*)debugDescription {
    return [NSString stringWithFormat:@"<%@: %p> :: {name: %@, group: %@, stopIds: %@}", self.class, self, self.name, self.group, self.stopIds];
}

@end
