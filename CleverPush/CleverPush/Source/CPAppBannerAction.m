#import "CPAppBannerAction.h"

@implementation CPAppBannerAction

#pragma mark - wrapping the data of the bannerAction in to CPAppBannerAction NSObject
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
        if ([json objectForKey:@"screen"] && [[json objectForKey:@"screen"] isKindOfClass:[NSString class]]) {
            self.screen = [json objectForKey:@"screen"];
        }
        if ([json objectForKey:@"name"] && [[json objectForKey:@"name"] isKindOfClass:[NSString class]]) {
            self.name = [json objectForKey:@"name"];
        }
        
        self.dismiss = YES;
        if ([json objectForKey:@"dismiss"]) {
            self.dismiss = [[json objectForKey:@"dismiss"] boolValue];
        }
        
        self.openInWebview = NO;
        if ([json objectForKey:@"openInWebview"] != nil && ![[json objectForKey:@"openInWebview"] isKindOfClass:[NSNull class]] && [[json objectForKey:@"openInWebview"] boolValue]) {
            self.openInWebview = YES;
        }
        
        self.openBySystem = NO;
        if ([json objectForKey:@"openBySystem"] != nil && ![[json objectForKey:@"openBySystem"] isKindOfClass:[NSNull class]] && [[json objectForKey:@"openBySystem"] boolValue]) {
            self.openBySystem = YES;
        }
        
        if ([json objectForKey:@"tags"] && [[json objectForKey:@"tags"] isKindOfClass:[NSArray class]]) {
            self.tags = [json objectForKey:@"tags"];
        }
        if ([json objectForKey:@"topics"] && [[json objectForKey:@"topics"] isKindOfClass:[NSArray class]]) {
            self.topics = [json objectForKey:@"topics"];
        }
        if ([json objectForKey:@"attributeId"] && [[json objectForKey:@"attributeId"] isKindOfClass:[NSString class]]) {
            self.attributeId = [json objectForKey:@"attributeId"];
        }
        if ([json objectForKey:@"attributeValue"] && [[json objectForKey:@"attributeValue"] isKindOfClass:[NSString class]]) {
            self.attributeValue = [json objectForKey:@"attributeValue"];
        }

    }
    return self;
}

@end
