#import "CPAppBannerAction.h"

@implementation CPAppBannerAction

- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self && json && ![json isKindOfClass:[NSNull class]]) {
        if ([json objectForKey:@"url"] && [[json objectForKey:@"url"] isKindOfClass:[NSString class]]) {
            self.url = [NSURL URLWithString:[json objectForKey:@"url"]];
        }
        
        if ([json objectForKey:@"urlType"] && [[json objectForKey:@"urlType"] isKindOfClass:[NSString class]]) {
            self.urlType = [json objectForKey:@"urlType"];
        }
        
        if ([json objectForKey:@"type"] && [[json objectForKey:@"type"] isKindOfClass:[NSString class]]) {
            self.type = [json objectForKey:@"type"];
        }
        
        if ([json objectForKey:@"name"] && [[json objectForKey:@"name"] isKindOfClass:[NSString class]]) {
            self.name = [json objectForKey:@"name"];
        }
        
        self.dismiss = YES;
        if ([json objectForKey:@"dismiss"]) {
            self.dismiss = [[json objectForKey:@"dismiss"] boolValue];
        }
    }
    return self;
}

@end
