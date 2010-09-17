#import "OBABookmarkV2.h"


@implementation OBABookmarkV2

@synthesize name = _name;
@synthesize stopIds = _stopIds;

- (id) initWithCoder:(NSCoder*)coder {
	if( self = [super init] ) {
		_name =  [[coder decodeObjectForKey:@"name"] retain];
		_stopIds =  [[coder decodeObjectForKey:@"stopIds"] retain];
	}
	return self;
}

#pragma mark NSCoder Methods

- (void) encodeWithCoder: (NSCoder *)coder {
	[coder encodeObject:_name forKey:@"name"];
	[coder encodeObject:_stopIds forKey:@"stopIds"];
}

@end
