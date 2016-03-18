#import "OBAAgencyV2.h"


@implementation OBAAgencyV2 

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];

    if (self) {
        _agencyId = [aDecoder decodeObjectForKey:@"agencyId"];
        _url = [aDecoder decodeObjectForKey:@"url"];
        _name = [aDecoder decodeObjectForKey:@"name"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_agencyId forKey:@"agencyId"];
    [aCoder encodeObject:_url forKey:@"url"];
    [aCoder encodeObject:_name forKey:@"name"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    OBAAgencyV2 *agency = [[self.class alloc] init];
    agency->_agencyId = [_agencyId copyWithZone:zone];
    agency->_url = [_url copyWithZone:zone];
    agency->_name = [_name copyWithZone:zone];

    return agency;
}

@end
