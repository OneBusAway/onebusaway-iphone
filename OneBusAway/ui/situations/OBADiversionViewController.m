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

#import "OBADiversionViewController.h"
@import OBAKit;
#import "EXTScope.h"

@interface OBADiversionViewController ()
@property (nonatomic, strong) NSString *tripEncodedPolyline;

@property (nonatomic, strong) MKPolyline *routePolyline;
@property (nonatomic, strong) MKPolylineRenderer *routePolylineRenderer;

@property (nonatomic, strong) MKPolyline *reroutePolyline;
@property (nonatomic, strong) MKPolylineRenderer *reroutePolylineRenderer;

@property (nonatomic, strong) OBAModelServiceRequest *request;
@end

@implementation OBADiversionViewController

+ (OBADiversionViewController *)loadFromNibWithappDelegate:(OBAApplicationDelegate *)context {
    NSArray *wired = [[NSBundle mainBundle] loadNibNamed:@"OBADiversionViewController" owner:context options:nil];
    OBADiversionViewController *controller = wired[0];

    return controller;
}

- (void)dealloc {
    [self.request cancel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    MKMapView *mv = [self mapView];
    NSArray *points = [OBASphericalGeometryLibrary decodePolylineString:self.diversionPath];

    _reroutePolyline = [OBASphericalGeometryLibrary createMKPolylineFromLocations:points];

    [mv addOverlay:_reroutePolyline];

    OBACoordinateBounds *bounds = [OBASphericalGeometryLibrary boundsForLocations:points];

    if (![bounds empty]) {
        [mv setRegion:bounds.region];
    }

    NSString *shapeId = [[self.args[@"arrivalAndDeparture"] trip] shapeId];

    if (!self.tripEncodedPolyline && shapeId) {
        [self requestShapeForID:shapeId];
    }
}

#pragma mark - Lazy Loading

- (OBAModelService*)modelService {
    if (!_modelService) {
        _modelService = [OBAApplication sharedApplication].modelService;
    }
    return _modelService;
}

#pragma mark - Data Loading

- (void)requestShapeForID:(NSString *)shapeId {
    @weakify(self);
    self.request = [self.modelService requestShapeForId:shapeId completionBlock:^(id jsonData, NSHTTPURLResponse *response, NSError *error) {
        @strongify(self);

        if (!jsonData) {
            return;
        }

        self.tripEncodedPolyline = jsonData;
        NSArray *points = [OBASphericalGeometryLibrary decodePolylineString:self.tripEncodedPolyline];

        CLLocationCoordinate2D *pointArr = malloc(sizeof(CLLocationCoordinate2D) * points.count);

        for (NSInteger i = 0; i < points.count; i++) {
            CLLocation *location = points[i];
            CLLocationCoordinate2D p = location.coordinate;
            pointArr[i] = p;
        }

        self.routePolyline = [MKPolyline polylineWithCoordinates:pointArr count:points.count];
        free(pointArr);
        [self.mapView addOverlay:self.routePolyline];
    }];
}

#pragma mark MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[OBAPlacemark class]]) {
        static NSString *viewId = @"DiversionView";
        MKPinAnnotationView *view = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:viewId];

        if (view == nil) {
            view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:viewId];
        }

        view.canShowCallout = NO;
        return view;
    }

    return nil;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    MKOverlayRenderer *overlayView = nil;

    if (overlay == _reroutePolyline) {
        //if we have not yet created an overlay view for this overlay, create it now.
        if (_reroutePolylineRenderer == nil) {
            _reroutePolylineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:_reroutePolyline];
            _reroutePolylineRenderer.fillColor = [UIColor redColor];
            _reroutePolylineRenderer.strokeColor = [UIColor redColor];
            _reroutePolylineRenderer.lineWidth = 5;
        }

        overlayView = _reroutePolylineRenderer;
    }
    else if (overlay == _routePolyline) {
        //if we have not yet created an overlay view for this overlay, create it now.
        if (_routePolylineRenderer == nil) {
            _routePolylineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:_routePolyline];
            _routePolylineRenderer.fillColor = [UIColor blackColor];
            _routePolylineRenderer.strokeColor = [UIColor blackColor];
            _routePolylineRenderer.lineWidth = 5;
        }

        overlayView = _routePolylineRenderer;
    }
    else {
        overlayView = [[MKOverlayRenderer alloc] init];
    }

    return overlayView;
}

- (MKMapView *)mapView {
    return (MKMapView *)self.view;
}

@end
