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

#import "OBACoordinateBounds.h"


@interface OBASphericalGeometryLibrary : NSObject {

}

+ (CLLocationCoordinate2D) makeCoordinateLat:(CLLocationDegrees)lat lon:(CLLocationDegrees)lon;
+ (MKCoordinateRegion) createRegionWithCenter:(CLLocationCoordinate2D)center latRadius:(double)latRadiusInMeters lonRadius:(double)lonRadiusInMeters;
+ (double) getDistanceFromRegion:(MKCoordinateRegion)regionA toRegion:(MKCoordinateRegion)regionB;
+ (BOOL) isRegion:(MKCoordinateRegion)regionA containedBy:(MKCoordinateRegion)regionB;
+ (BOOL) isCoordinate:(CLLocationCoordinate2D)coordinate containedBy:(MKCoordinateRegion)region;
+ (NSString*) regionAsString:(MKCoordinateRegion)region;

+ (NSArray*) decodePolylineString:(NSString*)encodedPolyline;
+ (MKPolyline*) createMKPolylineFromLocations:(NSArray*) locations;
+ (MKPolyline*) decodePolylineStringAsMKPolyline:(NSString*)polylineString;

+ (NSArray*) subsamplePoints:(NSArray*)points minDistance:(double)minDistance;

+ (OBACoordinateBounds*) boundsForLocations:(NSArray*)locations;
+ (OBACoordinateBounds*) boundsForMKPolyline:(MKPolyline*)polyline;

@end


@interface CLLocation (OBAConvenienceMethods)

- (CLLocationDistance)distanceFromLocationSafe:(const CLLocation *)location;

@end
