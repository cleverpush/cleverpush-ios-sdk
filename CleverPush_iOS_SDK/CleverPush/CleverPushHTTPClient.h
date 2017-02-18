@interface CleverPushHTTPClient : NSObject

@property (readonly, nonatomic) NSURL *apiEndpoint;
- (NSMutableURLRequest*) requestWithMethod:(NSString*)method path:(NSString*)path;
@end
