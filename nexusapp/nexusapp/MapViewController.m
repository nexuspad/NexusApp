//
//  MapViewController.m
//  nexuspad
//
//  Created by Ren Liu on 9/21/12.
//
//

#import "MapViewController.h"
#import <MapKit/MapKit.h>

@interface MapViewController ()
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) MKPlacemark *placeMark;
@end


@implementation MapViewController
@synthesize myLocation = _myLocation;

- (void)setMyLocation:(NPLocation*)theLocation
{
    _myLocation = theLocation;
    
    NSString *location = [theLocation getAddressStringForMap];
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:location
        completionHandler:^(NSArray* placemarks, NSError* error){
            if (placemarks && placemarks.count > 0) {
                CLPlacemark *topResult = [placemarks objectAtIndex:0];
                self.placeMark = [[MKPlacemark alloc] initWithPlacemark:topResult];

                MKCoordinateRegion region = self.mapView.region;
                region.center = self.placeMark.region.center;
                region.span.longitudeDelta /= 128.0;
                region.span.latitudeDelta /= 128.0;

                [self.mapView setRegion:region animated:YES];
                [self.mapView addAnnotation:self.placeMark];
            }
        }
     ];
}

- (IBAction)openMapApp:(id)sender
{
    Class itemClass = [MKMapItem class];
    if (itemClass && [itemClass respondsToSelector:@selector(openMapsWithItems:launchOptions:)]) {
        // ios 6
        if (self.placeMark != nil) {
            MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:self.placeMark];
            [mapItem openInMapsWithLaunchOptions:nil];
        }

    } else {
        // Before ios 6
        NSString *urlString = [NSString stringWithFormat:@"http://maps.google.com/maps?q=%@", [self.myLocation getAddressStringForMap]];
        urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    }
}

- (IBAction)changeMapType:(id)sender
{
    if (self.mapView.mapType == MKMapTypeStandard)
        self.mapView.mapType = MKMapTypeSatellite;
    else
        self.mapView.mapType = MKMapTypeStandard;
}

- (IBAction)zoomIn:(id)sender
{
    MKCoordinateRegion region;
    //Set Zoom level using Span
    MKCoordinateSpan span;
    region.center = self.mapView.region.center;
    
    span.latitudeDelta = self.mapView.region.span.latitudeDelta /2.0002;
    span.longitudeDelta = self.mapView.region.span.longitudeDelta /2.0002;
    region.span=span;
    
    [self.mapView setRegion:region animated:TRUE];
}

- (IBAction)zoomOut:(id)sender
{
    MKCoordinateRegion region;
    //Set Zoom level using Span
    MKCoordinateSpan span;
    region.center = self.mapView.region.center;
    span.latitudeDelta = self.mapView.region.span.latitudeDelta *2;
    span.longitudeDelta = self.mapView.region.span.longitudeDelta *2;
    region.span=span;
    [self.mapView setRegion:region animated:TRUE];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [self setMapView:nil];
    [super viewDidUnload];
}
@end
