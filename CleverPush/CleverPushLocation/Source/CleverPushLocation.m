#import "CleverPushLocation.h"
#import "CleverPush.h"
#import "CleverPushHTTPClient.h"
#import "NSDictionary+SafeExpectations.h"

@implementation CleverPushLocation

CLLocationManager* locationManager;

+ (void)init {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
        [CleverPush getSubscriptionId:^(NSString* subscriptionId) {
            [CleverPush getChannelConfig:^(NSDictionary* channelConfig) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (channelConfig != nil && [channelConfig arrayForKey:@"geoFences"] != nil) {
                        if (!locationManager) {
                            locationManager = [CLLocationManager new];
                        }
                        locationManager.delegate = (id)self;
                        
                        NSArray* geoFencesDict = [channelConfig arrayForKey:@"geoFences"];
                        for (NSDictionary *geoFence in geoFencesDict) {
                            if (geoFence != nil) {
                                CLLocationCoordinate2D center = CLLocationCoordinate2DMake([[geoFence objectForKey:@"latitude"] doubleValue], [[geoFence objectForKey:@"longitude"] doubleValue]);
                                CLRegion *region = [[CLCircularRegion alloc]initWithCenter:center
                                                                                    radius:[[geoFence objectForKey:@"radius"] longValue]
                                                                                identifier:[geoFence valueForKey:@"_id"]];
                                [locationManager startMonitoringForRegion:region];
                            }
                        }
                    }
                });
            }];
        }];
    });
}

#pragma mark - Check the authority of location permission
- (BOOL)hasLocationPermission {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    return status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse;
}

#pragma mark - Request to access location permission
+ (void)requestLocationPermission {
    if (!locationManager) {
        locationManager = [CLLocationManager new];
    }
    [locationManager requestAlwaysAuthorization];
}

+ (void)trackGeoFence:(NSString *)geoFenceId withState:(NSString *)state {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"subscription/geo-fence"];
        NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [CleverPush channelId], @"channelId",
                                 geoFenceId, @"geoFenceId",
                                 state, @"state",
                                 [CleverPush getSubscriptionId], @"subscriptionId",
                                 nil];
        
        NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
        [request setHTTPBody:postData];
        
        [CleverPush enqueueRequest:request onSuccess:^(NSDictionary* results) {
            
        } onFailure:nil];
    });
}

#pragma mark - Location delegates
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSLog(@"CleverPush: LocationManager didChangeAuthorizationStatus %@", status);
}

+ (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    NSLog(@"CleverPush: LocationManager didStartMonitoringForRegion %@", [region identifier]);
}

+ (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    NSLog(@"CleverPush: LocationManager didDetermineState %@", [region identifier]);
    if (state == CLRegionStateInside) {
        [self locationManager:manager didEnterRegion:region];
    }
}

+ (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"CleverPush: Entered Geo Fence %@", [region identifier]);
    [self trackGeoFence:[region identifier] withState:@"enter"];
}

+ (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"CleverPush: Exited Geo Fence %@", [region identifier]);
    [self trackGeoFence:[region identifier] withState:@"exit"];
}

@end
