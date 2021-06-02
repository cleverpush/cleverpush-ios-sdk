#import <Foundation/Foundation.h>

@interface CleverPushHTTPClient : NSObject
#pragma mark - Base classs for api call.
+ (CleverPushHTTPClient *)sharedClient;
@property (readonly, nonatomic) NSURL *apiEndpoint;
- (NSMutableURLRequest*) requestWithMethod:(NSString*)method path:(NSString*)path;

@end
