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

#import "OBASphericalGeometryLibrary.h"

static const double kRadiusOfEarthInMeters = 6371.01 * 1000;

@implementation OBASphericalGeometryLibrary

+ (MKCoordinateRegion) createRegionWithCenter:(CLLocationCoordinate2D)center latRadius:(double)latRadiusInMeters lonRadius:(double)lonRadiusInMeters {

    double latRadians = center.latitude / 180 * M_PI;
	
    double latRadius = kRadiusOfEarthInMeters;
    double lonRadius = cos(latRadians) * kRadiusOfEarthInMeters;
	
    double latOffset = (latRadiusInMeters / latRadius) * 180 / M_PI;
    double lonOffset = (lonRadiusInMeters / lonRadius) * 180 / M_PI;
	
	MKCoordinateSpan span = MKCoordinateSpanMake(latOffset*2,lonOffset*2);
	return	MKCoordinateRegionMake(center, span);
}

+ (double) getDistanceFromRegion:(MKCoordinateRegion)regionA toRegion:(MKCoordinateRegion)regionB {
	CLLocation * a = [[[CLLocation alloc] initWithLatitude:regionA.center.latitude longitude:regionA.center.longitude] autorelease];
	CLLocation * b = [[[CLLocation alloc] initWithLatitude:regionB.center.latitude longitude:regionB.center.longitude] autorelease];
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

+ (NSString*) regionAsString:(MKCoordinateRegion)region {
	
	CLLocationCoordinate2D pA = region.center;
	MKCoordinateSpan spanA = region.span;
	
	return [NSString stringWithFormat:@"%f %f %f %f",
			pA.latitude - spanA.latitudeDelta / 2,
			pA.longitude - spanA.longitudeDelta / 2,
			pA.latitude + spanA.latitudeDelta / 2,
			pA.longitude + spanA.longitudeDelta / 2];
}

@end
