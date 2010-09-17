#import "OBAHasReferencesV2.h"
#import "OBAAgencyV2.h"


@interface OBARouteV2 :  OBAHasReferencesV2 {
	NSString * _routeId;
	NSString * _shortName;
	NSString * _longName;
	NSNumber * _routeType;
	NSString * _agencyId;
}

@property (nonatomic, retain) NSString * routeId;
@property (nonatomic, retain) NSString * shortName;
@property (nonatomic, retain) NSString * longName;
@property (nonatomic, retain) NSNumber * routeType;

@property (nonatomic, retain) NSString * agencyId;
@property (nonatomic, readonly) OBAAgencyV2 * agency;

@property (nonatomic, readonly) NSString * safeShortName;

- (NSComparisonResult) compareUsingName:(OBARouteV2*)aRoute;

@end