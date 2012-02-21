//
//  OPEViewController.m
//  OSM POI Editor
//
//  Created by David Chiles on 2/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OPEViewController.h"
#import "RMCloudMadeMapSource.h"
#import "RMCloudMadeHiResMapSource.h" 
#import "RMMarkerManager.h" 
#import "RMMarkerAdditions.h"
#import "OPENodeViewController.h"
#import "GTMOAuthViewControllerTouch.h"

@implementation OPEViewController

@synthesize osmData;
@synthesize locationManager;
@synthesize interpreter;
@synthesize infoButton,location, addOPEPoint;
@synthesize openMarker;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(addMarkers)
     name:@"DownloadComplete"
     object:nil ];
    
    interpreter = [[OPETagInterpreter alloc] init];
    [interpreter readPlist];
    
    [RMMapView class];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    id cmTilesource = [[RMCloudMadeHiResMapSource alloc] initWithAccessKey: @"0d68a3f7f77a47bc8ef3923816ebbeab" 
                                                           styleNumber: 1];
    //36079
    [[RMMapContents alloc] initWithView: mapView tilesource: cmTilesource];
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];
    
    
    CLLocationCoordinate2D initLocation;
    //NSLog(@"location Manager: %@",[locationManager location]);
    
    //initLocation.latitude  = 37.871667;
    //initLocation.longitude =  -122.272778;
   
    initLocation = [[locationManager location] coordinate];
    
    [mapView moveToLatLong: initLocation];
    
    [mapView.contents setZoom: 18];
    [self addMarkerAt:initLocation withNode:nil];
    RMSphericalTrapezium geoBox = [mapView latitudeLongitudeBoundingBoxForScreen];
    

    double bboxleft = geoBox.southwest.longitude;
    double bboxbottom = geoBox.southwest.latitude;
    double bboxright = geoBox.northeast.longitude;
    double bboxtop = geoBox.northeast.latitude;
    osmData = [[OPEOSMData alloc] initWithLeft:bboxleft bottom:bboxbottom right:bboxright top:bboxtop];
    
    [osmData getData];
    
    //[mapView moveToLatLong: initLocation];
    //[mapView.contents setZoom: 16];
    
    //[self addMarkerAt: initLocation];

    mapView.delegate = self;
    
    
        
}

-(void) addMarkerAt:(CLLocationCoordinate2D) markerPosition withNode: (OPENode *) node
{
    //NSLog(@"start addMarkerAt");
    UIImage *blueMarkerImage = [UIImage imageNamed:@"Blue_Dot.png"];
    RMMarker *newMarker = [[RMMarker alloc] initWithUIImage:blueMarkerImage anchorPoint:CGPointMake(0.5, 1.0)];
    newMarker.data = node;
    [mapView.contents.markerManager addMarker:newMarker AtLatLong:markerPosition];
    //[newMarker retain];
    //NSLog(@"Node Category: %@",[interpreter getCategory:node]);
    [interpreter getCategory:node];
    
}

- (void) setText: (NSString*) text forMarker: (RMMarker*) marker
{
    CGSize textSize = [text sizeWithFont: [RMMarker defaultFont]]; 
    
    CGPoint position = CGPointMake(  -(textSize.width/2 - marker.bounds.size.width/2), -textSize.height );
    
    [marker changeLabelUsingText: text position: position ];    
}


- (void) tapOnMarker: (RMMarker*) marker onMap: (RMMapView*) map
{
    if(openMarker) 
    {
        [openMarker hideLabel];
    }
    
    if(openMarker == marker) 
    {
        [openMarker hideLabel];
        self.openMarker = nil;
    } 
    else 
    {
        self.openMarker = marker;
        OPENode * node = (OPENode *)openMarker.data;
        [marker addAnnotationViewWithTitle:[node getName]];
        
    }    
}

- (void)pushMapAnnotationDetailedViewControllerDelegate:(id) sender
{
    NSLog(@"Arrow Pressed");
    OPENodeViewController * viewer = [[OPENodeViewController alloc] initWithNibName:@"OPENodeViewController" bundle:nil];
    
    viewer.title = @"Node Info";
    viewer.node = (OPENode *)openMarker.data;
    
    
    UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle: @"Map" style: UIBarButtonItemStyleBordered target: nil action: nil];
    
    [[self navigationItem] setBackBarButtonItem: newBackButton];
    
    [self.navigationController pushViewController:viewer animated:YES];
    
}

- (void) tapOnLabelForMarker: (RMMarker*) marker onMap: (RMMapView*) map 
{
    NSLog(@"Label Pressed");
    OPENodeViewController * viewer = [[OPENodeViewController alloc] initWithNibName:@"OPENodeViewController" bundle:nil];
    
    viewer.title = @"Node Info";
    viewer.node = (OPENode *)openMarker.data;
    
    
    UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle: @"Map" style: UIBarButtonItemStyleBordered target: nil action: nil];
    
    [[self navigationItem] setBackBarButtonItem: newBackButton];
    
    [self.navigationController pushViewController:viewer animated:YES];
}

- (BOOL) mapView:(RMMapView *)map shouldDragMarker:(RMMarker *)marker withEvent:(UIEvent *)event
{
    return NO;
}

- (void) mapView:(RMMapView *)map didDragMarker:(RMMarker *)marker withEvent:(UIEvent *)event
{
    NSSet* touches = [event allTouches];
    
    if([touches count] == 1)
    {
        UITouch* touch = [touches anyObject];
        if(touch.phase == UITouchPhaseMoved)
        {
            CGPoint position = [touch locationInView: mapView ];
            [mapView.markerManager moveMarker:marker AtXY: position];
        }
    }
}

-(void) afterMapMove:(RMMapView *)map
{
    NSLog(@"start map move");
    RMSphericalTrapezium geoBox = [mapView latitudeLongitudeBoundingBoxForScreen];
    
    osmData.bboxleft = geoBox.southwest.longitude; 
    osmData.bboxbottom = geoBox.southwest.latitude;
    osmData.bboxright = geoBox.northeast.longitude;
    osmData.bboxtop = geoBox.northeast.latitude;
    
    [osmData getData];
}

- (void) addMarkers
{
    for(id key in osmData.allNodes)
    {
        OPENode* node = [osmData.allNodes objectForKey:key];
        [self addMarkerAt:node.coordinate withNode:node];
        
    }
}

- (IBAction)addPointButtonPressed:(id)sender
{
    
}

-(IBAction)locationButtonPressed:(id)sender
{
    CLLocationCoordinate2D currentLocation = [[locationManager location] coordinate];
    
    [mapView moveToLatLong: currentLocation];
}

- (IBAction)infoButtonPressed:(id)sender
{
    NSLog(@"sent button pressed");
    OPEInfoViewController * viewer = [[OPEInfoViewController alloc] initWithNibName:@"OPEInfoViewController" bundle:nil];
    viewer.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    viewer.title = @"Info";
    [[self navigationController] pushViewController:viewer animated:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [locationManager stopUpdatingLocation];
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
