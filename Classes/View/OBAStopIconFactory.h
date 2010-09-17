#import "OBAStopV2.h"


@interface OBAStopIconFactory : NSObject {
	NSMutableDictionary * _stopIcons;
	UIImage * _defaultStopIcon;
}

- (UIImage*) getIconForStop:(OBAStopV2*)stop;

@end
