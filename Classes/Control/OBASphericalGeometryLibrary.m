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
	
    double latRadius = latRadiusInMeters;
    double lonRadius = cos(latRadians) * lonRadiusInMeters;
	
    double latOffset = latRadius / kRadiusOfEarthInMeters * 180 / M_PI;
    double lonOffset = lonRadius / kRadiusOfEarthInMeters * 180 / M_PI;
	
	MKCoordinateSpan span = MKCoordinateSpanMake(latOffset*2,lonOffset*2);
	return	MKCoordinateRegionMake(center, span);
}

@end
