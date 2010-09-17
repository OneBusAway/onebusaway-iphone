#import "OBAStopIconFactory.h"
#import "OBARouteV2.h"


@interface OBAStopIconFactory (Private)

- (void) loadIcons;
- (NSString*) getRouteIconTypeForStop:(OBAStopV2*)stop;

@end


@implementation OBAStopIconFactory

- (id) init {
	if( self = [super init] ) {
		[self loadIcons];
	}
	return self;
}

- (void) dealloc {
	[_stopIcons release];
	[_defaultStopIcon release];
	[super dealloc];
}

- (UIImage*) getIconForStop:(OBAStopV2*)stop {

	NSString * routeIconType = [self getRouteIconTypeForStop:stop];
	NSString * direction = @"";
	
	if( stop.direction )
		direction = stop.direction;
	
	NSString * key = [NSString stringWithFormat:@"%@StopIcon%@",routeIconType,direction];
	
	UIImage * image = [_stopIcons objectForKey:key];
	
	if( ! image || [image isEqual:[NSNull null]] )
		return _defaultStopIcon;
	
	return image;
}

@end


@implementation OBAStopIconFactory (Private)

- (void) loadIcons {
	
	_stopIcons = [[NSMutableDictionary alloc] init];
	
	NSArray * directionIds = [NSArray arrayWithObjects:@"",@"N",@"NE",@"E",@"SE",@"S",@"SW",@"W",@"NW",nil];
	NSArray * iconTypeIds = [NSArray arrayWithObjects:@"Bus",@"LightRail",@"Rail",@"Ferry",nil];
	
	for( int j=0; j<[iconTypeIds count]; j++) {
		NSString * iconType = [iconTypeIds objectAtIndex:j];
		for( int i=0; i<[directionIds count]; i++) {		
			NSString * directionId = [directionIds objectAtIndex:i];
			NSString * key = [NSString stringWithFormat:@"%@StopIcon%@",iconType,directionId];
			NSString * imageName = [NSString stringWithFormat:@"%@.png",key];
			UIImage * image = [UIImage imageNamed:imageName];
			[_stopIcons setObject:image forKey:key];
		}		
	}	
	
	_defaultStopIcon = [_stopIcons objectForKey:@"BusStopIcon"];
}

- (NSString*) getRouteIconTypeForStop:(OBAStopV2*)stop {
	NSMutableSet * routeTypes = [NSMutableSet set];
	for( OBARouteV2 * route in stop.routes ) {
		if( route.routeType )
			[routeTypes addObject:route.routeType];
	}
	
	// Heay rail dominations
	if( [routeTypes containsObject:[NSNumber numberWithInt:4]] )
		return @"Ferry";
	else if( [routeTypes containsObject:[NSNumber numberWithInt:2]] )
		return @"Rail";
	else if( [routeTypes containsObject:[NSNumber numberWithInt:0]] )
		return @"LightRail";
	else
		return @"Bus";
}

@end