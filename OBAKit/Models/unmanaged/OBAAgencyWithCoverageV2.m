#import <OBAKit/OBAAgencyWithCoverageV2.h>
#import <OBAKit/NSObject+OBADescription.h>

@implementation OBAAgencyWithCoverageV2

- (OBAAgencyV2*) agency {
    OBAReferencesV2 * refs = [self references];
    return [refs getAgencyForId:self.agencyId];
}

- (NSComparisonResult) compareUsingAgencyName:(OBAAgencyWithCoverageV2*)obj {
    NSString * nameA = [self.agency name];
    NSString * nameB = [obj.agency name];
    return [nameA compare:nameB options:NSNumericSearch];
}

- (OBARegionBoundsV2*)regionBounds {

    if (self.latSpan == 0 || self.lonSpan == 0) {
        return nil;
    }

    if (self.lat == 0 || self.lon == 0) {
        return nil;
    }

    OBARegionBoundsV2 *regionBounds = [[OBARegionBoundsV2 alloc] init];
    regionBounds.lat = self.lat;
    regionBounds.latSpan = self.latSpan;
    regionBounds.lon = self.lon;
    regionBounds.lonSpan = self.lonSpan;
    return regionBounds;
}

- (NSString*)description {
    return [self oba_description:@[@"agencyId", @"agency"] keyPaths:@[@"regionBounds"]];
}

@end
