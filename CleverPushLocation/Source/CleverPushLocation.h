#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface CleverPushLocation : NSObject <CLLocationManagerDelegate>

+ (void)init;
+ (void)requestLocationPermission;

@end
