#import "OBAAgencyWithCoverageV2.h"


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

@end
