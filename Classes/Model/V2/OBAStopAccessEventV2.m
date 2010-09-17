#import "OBAStopAccessEventV2.h"


@implementation OBAStopAccessEventV2

@synthesize title = _title;
@synthesize subtitle = _subtitle;
@synthesize stopIds = _stopIds;

- (id) initWithCoder:(NSCoder*)coder {
	if( self = [super init] ) {
		_title =  [[coder decodeObjectForKey:@"title"] retain];
		_subtitle =  [[coder decodeObjectForKey:@"subtitle"] retain];
		_stopIds =  [[coder decodeObjectForKey:@"stopIds"] retain];
	}
	return self;
}

#pragma mark NSCoder Methods

- (void) encodeWithCoder: (NSCoder *)coder {
	[coder encodeObject:_title forKey:@"title"];
	[coder encodeObject:_subtitle forKey:@"subtitle"];
	[coder encodeObject:_stopIds forKey:@"stopIds"];
}

@end
