#import <Foundation/Foundation.h>
#import "CleverPushHTTPClient.h"

@interface CleverPushHTTPClient()

@property (readwrite, nonatomic) NSURL *apiEndpoint;

@end

@implementation CleverPushHTTPClient

@synthesize apiEndpoint;

+ (CleverPushHTTPClient *)sharedClient {
    static CleverPushHTTPClient *sharedClient = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedClient = [CleverPushHTTPClient new];
    });
    return sharedClient;
}

- (id)init {
    self = [super init];
    if (self)
        self.apiEndpoint = [NSURL URLWithString:@"https://api.cleverpush.com/"];
    return self;
}

- (NSMutableURLRequest*)requestWithMethod:(NSString*)method path:(NSString*)path {
    NSURL* url = [NSURL URLWithString:path relativeToURL:self.apiEndpoint];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:method];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    return request;
}

@end
