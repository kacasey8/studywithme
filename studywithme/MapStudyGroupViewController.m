#import <BuiltIO/BuiltIO.h>

#import "MapStudyGroupViewController.h"
#import "MessagesViewController.h"
#import "PinAnnotationPoint.h"
#import "ViewStudyGroupTabBarController.h"
#import "Helper.h"

@interface MapStudyGroupViewController ()
@end

@implementation MapStudyGroupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];
    _mapView.showsUserLocation = YES;
    _mapView.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMap) name:@"MyDataChangedNotification" object:nil];
    
    // In case we miss the notification.
    [self updateMap];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)removeAllAnnotationsExceptUserLocation {
    MKUserLocation *userLocation = [self.mapView userLocation];
    NSMutableArray *pins = [[NSMutableArray alloc] initWithArray:[self.mapView annotations]];
    if ( userLocation != nil ) {
        [pins removeObject:userLocation]; // avoid removing user location off the map
    }
    
    [self.mapView removeAnnotations:pins];
}

- (void)updateMap {
    [self removeAllAnnotationsExceptUserLocation];
    
    ViewStudyGroupTabBarController *tabVC = (ViewStudyGroupTabBarController *)self.tabBarController;
    
    NSArray *newArray = [[tabVC.myStudyGroups arrayByAddingObjectsFromArray:tabVC.otherStudyGroups] arrayByAddingObjectsFromArray:tabVC.futureStudyGroups];
    
    for (int i = 0; i < [newArray count]; i++) {
        NSDictionary *studyGroupData = [newArray objectAtIndex:i];
        
        CLLocationCoordinate2D location;
        location.longitude = [[[studyGroupData objectForKey:@"__loc"] objectAtIndex:0] doubleValue];
        location.latitude = [[[studyGroupData objectForKey:@"__loc"] objectAtIndex:1] doubleValue];
            
        PinAnnotationPoint *point = [[PinAnnotationPoint alloc] init];
        point.coordinate = location;
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        NSDate *startDate = [dateFormatter dateFromString:[studyGroupData objectForKey:@"start_date"]];
        point.title = [NSString stringWithFormat:@"%@ - %@ %@ to %@", [studyGroupData objectForKey:@"course"], [Helper getShortWeekdayFromDate:startDate], [studyGroupData objectForKey:@"start_time"], [studyGroupData objectForKey:@"end_time"]];
        point.subtitle = [NSString stringWithFormat:@"%@", [studyGroupData objectForKey:@"location"]];
        point.studyGroup = studyGroupData;
        
        [_mapView addAnnotation:point];
    }
}

# pragma mark - MKMapView delegate

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    //if annotation is the user location, return nil to get default blue-dot...
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    //create purple pin view for all other annotations...
    static NSString *reuseId = @"purple";
    
    MKPinAnnotationView *purplePin = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseId];
    if (purplePin == nil) {
        purplePin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseId];
        purplePin.pinColor = MKPinAnnotationColorPurple;
        purplePin.canShowCallout = YES;
        purplePin.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    } else {
        //if re-using view from another annotation, point view to current annotation...
        purplePin.annotation = annotation;
    }
    
    return purplePin;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view
calloutAccessoryControlTapped:(UIControl *)control {
    PinAnnotationPoint *pin = (PinAnnotationPoint *)view.annotation;
    [self performSegueWithIdentifier:@"messages" sender:pin];
}

# pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"messages"]) {
        PinAnnotationPoint *pin = (PinAnnotationPoint *) sender;
        MessagesViewController *controller = (MessagesViewController *)segue.destinationViewController;
        controller.studyGroup = pin.studyGroup;
    }
}

# pragma mark - CLLocation delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *newLocation = [locations lastObject];
    NSTimeInterval interval = [newLocation.timestamp timeIntervalSinceNow];
    
    // Don't use cached data.
    if (abs(interval) < 30) {
        MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 800, 800);
        [_mapView setRegion:viewRegion animated:YES];
        // Give the device 1 second to normalize its location before telling it to stop zooming
        // in on current location.
        [NSTimer scheduledTimerWithTimeInterval:1.0
                                         target:locationManager
                                       selector:@selector(stopUpdatingLocation)
                                       userInfo:nil
                                        repeats:NO];
    }
}

@end
