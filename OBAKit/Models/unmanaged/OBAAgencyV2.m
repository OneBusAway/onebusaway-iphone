/**
 * Copyright (C) 2009-2016 bdferris <bdferris@onebusaway.org>, University of Washington
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <OBAKit/OBAAgencyV2.h>

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
