#import "OBAStopAccessEventV2.h"


@implementation OBAStopAccessEventV2

@synthesize title = _title;
@synthesize subtitle = _subtitle;
@synthesize stopIds = _stopIds;

- (id) initWithCoder:(NSCoder*)coder {
    self = [super init];
	if( self ) {
		self.title =  [coder decodeObjectForKey:@"title"];
		self.subtitle =  [coder decodeObjectForKey:@"subtitle"];
		self.stopIds =  [coder decodeObjectForKey:@"stopIds"];
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
