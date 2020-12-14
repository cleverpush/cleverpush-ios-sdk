#import <Foundation/Foundation.h>

@interface CleverPushHTTPClient : NSObject

+ (CleverPushHTTPClient *)sharedClient;
@property (readonly, nonatomic) NSURL *apiEndpoint;
- (NSMutableURLRequest*) requestWithMethod:(NSString*)method path:(NSString*)path;

@end
