#import "OBAStopIconFactory.h"
#import "OBARouteV2.h"


@interface OBAStopIconFactory (Private)

- (void) loadIcons;

- (NSString*) getRouteIconTypeForStop:(OBAStopV2*)stop;
- (NSString*) getRouteIconTypeForRouteTypes:(NSSet*)routeTypes;
- (NSString*) getRouteIconTypeForRoute:(OBARouteV2*)route;

@end


@implementation OBAStopIconFactory

- (id) init {
    self = [super init];
	if( self ) {
		[self loadIcons];
	}
	return self;
}


- (UIImage*) getIconForStop:(OBAStopV2*)stop {
    return [self getIconForStop:stop includeDirection:YES];
}

- (UIImage*) getIconForStop:(OBAStopV2*)stop includeDirection:(BOOL)includeDirection {
    NSString * routeIconType = [self getRouteIconTypeForStop:stop];
	NSString * direction = @"";
	
	if( includeDirection && stop.direction )
		direction = stop.direction;
	
	NSString * key = [NSString stringWithFormat:@"%@StopIcon%@",routeIconType,direction];
	
	UIImage * image = _stopIcons[key];
	
	if( ! image || [image isEqual:[NSNull null]] )
		return _defaultStopIcon;
	
	return image;
}

- (UIImage*) getModeIconForRoute:(OBARouteV2*)route {
    return [self getModeIconForRoute:route selected:NO];
}

- (UIImage*) getModeIconForRoute:(OBARouteV2*)route selected:(BOOL)selected {
    NSString * type = [self getRouteIconTypeForRoute:route];
    return [self getModeIconForRouteIconType:type selected:selected];
}

- (UIImage*) getModeIconForRouteIconType:(NSString*)routeType selected:(BOOL)selected {
    NSString * format = selected ? @"Mode-%@-Selected.png" : @"Mode-%@.png";
    return [UIImage imageNamed:[NSString stringWithFormat:format,routeType]];
}

- (NSString*) getRouteIconTypeForRoutes:(NSArray*)routes {
    NSMutableSet * routeTypes = [NSMutableSet set];
	for( OBARouteV2 * route in routes ) {
		if( route.routeType )
			[routeTypes addObject:route.routeType];
	}
	return [self getRouteIconTypeForRouteTypes:routeTypes];
}

@end


@implementation OBAStopIconFactory (Private)

- (void) loadIcons {
	
	_stopIcons = [[NSMutableDictionary alloc] init];
	
	NSArray * directionIds = @[@"",@"N",@"NE",@"E",@"SE",@"S",@"SW",@"W",@"NW"];
	NSArray * iconTypeIds = @[@"Bus",@"LightRail",@"Rail",@"Ferry"];
	
	for( int j=0; j<[iconTypeIds count]; j++) {
		NSString * iconType = iconTypeIds[j];
		for( int i=0; i<[directionIds count]; i++) {		
			NSString * directionId = directionIds[i];
			NSString * key = [NSString stringWithFormat:@"%@StopIcon%@",iconType,directionId];
			NSString * imageName = [NSString stringWithFormat:@"%@.png",key];
			UIImage * image = [UIImage imageNamed:imageName];
			_stopIcons[key] = image;
		}		
	}	
	
	_defaultStopIcon = _stopIcons[@"BusStopIcon"];
}

- (NSString*) getRouteIconTypeForStop:(OBAStopV2*)stop {
	NSMutableSet * routeTypes = [NSMutableSet set];
	for( OBARouteV2 * route in stop.routes ) {
		if( route.routeType )
			[routeTypes addObject:route.routeType];
	}
	return [self getRouteIconTypeForRouteTypes:routeTypes];
}

- (NSString*) getRouteIconTypeForRouteTypes:(NSSet*)routeTypes {
    
	// Heay rail dominations
	if( [routeTypes containsObject:@4] )
		return @"Ferry";
	else if( [routeTypes containsObject:@2] )
		return @"Rail";
	else if( [routeTypes containsObject:@0] )
		return @"LightRail";
	else
		return @"Bus";    
}

- (NSString*) getRouteIconTypeForRoute:(OBARouteV2*)route {
    switch ([route.routeType intValue]) {
        case 4:
            return @"Ferry";
        case 2:
            return @"Rail";
        case 0:
            return @"LightRail";
        default:
            return @"Bus";
    }
}

@end