//
//  OBAMapRegionManager.h
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 5/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@class OBARegionChangeRequest;


@interface OBAMapRegionManager : NSObject {
    MKMapView * _mapView;
    BOOL _lastRegionChangeWasProgramatic;
    BOOL _currentlyChangingRegion;
    OBARegionChangeRequest * _pendingRegionChangeRequest;
	NSMutableArray * _appliedRegionChangeRequests;
}

- (id) initWithMapView:(MKMapView*)mapView;

@property (nonatomic) BOOL lastRegionChangeWasProgramatic;

- (void) setRegion:(MKCoordinateRegion)region;
- (void) setRegion:(MKCoordinateRegion)region changeWasProgramatic:(BOOL)changeWasProgramatic;

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated;

/**
 * @return TRUE, if applying a pending region-change request, otherwise false
 */
- (BOOL)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated;

@end
