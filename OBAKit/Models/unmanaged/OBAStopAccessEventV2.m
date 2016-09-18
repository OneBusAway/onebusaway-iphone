#import <OBAKit/OBAStopAccessEventV2.h>

@implementation OBAStopAccessEventV2

- (id) initWithCoder:(NSCoder*)coder {
    self = [super init];
    if( self ) {
        _title =  [coder decodeObjectForKey:@"title"];
        _subtitle =  [coder decodeObjectForKey:@"subtitle"];
        _stopIds =  [coder decodeObjectForKey:@"stopIds"];
    }
    return self;
}

#pragma mark NSCoder Methods

- (void) encodeWithCoder: (NSCoder *)coder {
    [coder encodeObject:self.title forKey:@"title"];
    [coder encodeObject:self.subtitle forKey:@"subtitle"];
    [coder encodeObject:self.stopIds forKey:@"stopIds"];
}

@end
