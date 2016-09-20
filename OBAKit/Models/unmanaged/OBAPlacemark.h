/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAPlacemark : NSObject <NSCoding,MKAnnotation> {
    NSString * _name;
    NSString * _address;
    NSString * _icon;
    CLLocationCoordinate2D _coordinate;
}

@property (nonatomic,strong) NSString * name;
@property (nonatomic,strong) NSString * address;
@property (nonatomic,strong) NSString * icon;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (weak, nonatomic,readonly) CLLocation * location;

- (instancetype)initWithAddress:(NSString*)address coordinate:(CLLocationCoordinate2D)coordinate;

@end

NS_ASSUME_NONNULL_END
