#import "OBAServiceAlertsModel.h"



@implementation OBAServiceAlertsModel

@synthesize unreadCount;
@synthesize totalCount;
@synthesize unreadMaxSeverity;
@synthesize maxSeverity;

- (void) dealloc {
	self.unreadMaxSeverity = nil;
	self.maxSeverity = nil;
	[super dealloc];
}

@end
