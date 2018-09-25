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

#import <OBAKit/OBASphericalGeometryLibrary.h>

static const double kRadiusOfEarthInMeters = 6371.01 * 1000;

typedef struct {
    NSInteger number;
    NSInteger index;
} OBANumberAndIndex;

@implementation OBASphericalGeometryLibrary

+ (MKCoordinateRegion) createRegionWithCenter:(CLLocationCoordinate2D)center latRadius:(double)latRadiusInMeters lonRadius:(double)lonRadiusInMeters {

    double latRadians = center.latitude / 180 * M_PI;
    
    double latRadius = kRadiusOfEarthInMeters;
    double lonRadius = cos(latRadians) * kRadiusOfEarthInMeters;
    
    double latOffset = (latRadiusInMeters / latRadius) * 180 / M_PI;
    double lonOffset = (lonRadiusInMeters / lonRadius) * 180 / M_PI;
    
    MKCoordinateSpan span = MKCoordinateSpanMake(latOffset*2,lonOffset*2);
    return MKCoordinateRegionMake(center, span);
}

+ (CLLocationDistance) getDistanceFromRegion:(MKCoordinateRegion)regionA toRegion:(MKCoordinateRegion)regionB {
    CLLocation * a = [[CLLocation alloc] initWithLatitude:regionA.center.latitude longitude:regionA.center.longitude];
    CLLocation * b = [[CLLocation alloc] initWithLatitude:regionB.center.latitude longitude:regionB.center.longitude];
    return [a distanceFromLocation:b];
}

+ (BOOL) isRegion:(MKCoordinateRegion)regionA containedBy:(MKCoordinateRegion)regionB {
    CLLocationCoordinate2D pA = regionA.center;
    MKCoordinateSpan spanA = regionA.span;
    
    CLLocationCoordinate2D pB = regionB.center;
    MKCoordinateSpan spanB = regionB.span;
    
    return  pB.latitude - spanB.latitudeDelta / 2 <= pA.latitude - spanA.latitudeDelta / 2 &&
    pA.latitude + spanA.latitudeDelta / 2 <= pB.latitude + spanB.latitudeDelta / 2 &&
    pB.longitude - spanB.longitudeDelta/2 <= pA.longitude - spanA.longitudeDelta / 2 &&
    pA.longitude + spanA.longitudeDelta/2 <= pB.longitude + spanB.longitudeDelta / 2;
}

+ (BOOL) isCoordinate:(CLLocationCoordinate2D)coordinate containedBy:(MKCoordinateRegion)region {
    
    CLLocationCoordinate2D pR = region.center;
    MKCoordinateSpan spanR = region.span;

    return pR.latitude - spanR.latitudeDelta / 2 <= coordinate.latitude &&
    coordinate.latitude <= pR.latitude + spanR.latitudeDelta / 2 &&
    pR.longitude - spanR.longitudeDelta/2 <= coordinate.longitude &&
    coordinate.longitude <= pR.longitude + spanR.longitudeDelta / 2;
}

+ (NSString*) regionAsString:(MKCoordinateRegion)region {
    
    CLLocationCoordinate2D pA = region.center;
    MKCoordinateSpan spanA = region.span;
    
    return [NSString stringWithFormat:@"%f %f %f %f",
            pA.latitude - spanA.latitudeDelta / 2,
            pA.longitude - spanA.longitudeDelta / 2,
            pA.latitude + spanA.latitudeDelta / 2,
            pA.longitude + spanA.longitudeDelta / 2];
}

+ (NSArray<CLLocation*>*)decodePolylineString:(NSString*)encodedPolyline {
    double lat = 0;
    double lon = 0;
    NSInteger strIndex = 0;
    NSMutableArray * points = [NSMutableArray array];
    
    while (strIndex < encodedPolyline.length) {
        OBANumberAndIndex rLat = [self decodeSignedNumber:encodedPolyline withIndex:strIndex];
        lat = lat + rLat.number * 1e-5;
        strIndex = rLat.index;
        
        OBANumberAndIndex rLon = [self decodeSignedNumber:encodedPolyline withIndex:strIndex];
        lon = lon + rLon.number * 1e-5;
        strIndex = rLon.index;
        
        CLLocation * loc = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
        [points addObject:loc];
    }
    
    return points;
}

+ (OBACoordinateBounds*)coordinateBoundsFromPolylineString:(NSString*)polylineString {
    NSArray *points = [OBASphericalGeometryLibrary decodePolylineString:polylineString];
    OBACoordinateBounds *bounds = [OBASphericalGeometryLibrary boundsForLocations:points];

    return bounds;
}

+ (OBACoordinateBounds*) boundsForLocations:(NSArray*)locations {
    OBACoordinateBounds *bounds = [[OBACoordinateBounds alloc] init];
    
    for (CLLocation *location in locations) {
        CLLocationCoordinate2D p = location.coordinate;
        [bounds addLat:p.latitude lon:p.longitude];
    }
    
    return bounds;
}

+ (OBACoordinateBounds*)boundsForMKPolyline:(MKPolyline*)polyline {
    OBACoordinateBounds * bounds = [[OBACoordinateBounds alloc] init];
    
    MKMapPoint *points = polyline.points;
    for (NSInteger i=0; i<polyline.pointCount; i++ ) {
        MKMapPoint point = points[i];
        [bounds addLat:point.y lon:point.x];
    }
    return bounds;
}

+ (MKPolyline*)polylineFromEncodedShape:(NSString*)encodedShape {
    NSArray<CLLocation *> *points = [OBASphericalGeometryLibrary decodePolylineString:encodedShape];
    CLLocationCoordinate2D *pointArr = malloc(sizeof(CLLocationCoordinate2D) * points.count);

    for (NSInteger i = 0; i < points.count; i++) {
        CLLocation *location = points[i];
        CLLocationCoordinate2D p = location.coordinate;
        pointArr[i] = p;
    }

    MKPolyline *polyline = [MKPolyline polylineWithCoordinates:pointArr count:points.count];

    free(pointArr);

    return polyline;
}

#pragma mark - Private

+ (OBANumberAndIndex)decodeSignedNumber:(NSString*)value withIndex:(NSInteger)index {
    OBANumberAndIndex r = [self decodeNumber:value withIndex:index];
    NSInteger sgn_num = r.number;
    if ((sgn_num & 0x01) > 0) {
        sgn_num = ~(sgn_num);
    }
    r.number = sgn_num >> 1;
    return r;
}

+ (OBANumberAndIndex)decodeNumber:(NSString*)value withIndex:(NSInteger)index {
    NSInteger num = 0;
    NSInteger v = 0;
    NSInteger shift = 0;
    
    do {
        unichar c = [value characterAtIndex:index++];
        v = c - 63;
        num |= (v & 0x1f) << shift;
        shift += 5;
    } while (v >= 0x20);

    OBANumberAndIndex r;
    r.number = num;
    r.index = index;
    return r;
}

@end


