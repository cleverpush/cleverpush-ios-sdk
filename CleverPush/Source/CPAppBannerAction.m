#import "CPAppBannerAction.h"

@implementation CPAppBannerAction

#pragma mark - wrapping the data of the bannerAction in to CPAppBannerAction NSObject
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    self.blockId = @"";
    if (self && json && ![json isKindOfClass:[NSNull class]]) {
        if ([json objectForKey:@"url"] && [[json objectForKey:@"url"] isKindOfClass:[NSString class]]) {
            self.url = [NSURL URLWithString:[[json objectForKey:@"url"] stringByAddingPercentEscapesUsingEncoding:
                                                        NSUTF8StringEncoding]];
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
        
        self.dismiss = NO;
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
        
        if ([json objectForKey:@"bannerAction"] && [[json objectForKey:@"bannerAction"] isKindOfClass:[NSString class]] && [[json objectForKey:@"bannerAction"] isEqualToString:@"html"]) {
            self.customData = [json mutableCopy];
        }

        if ([json objectForKey:@"blockId"] && [[json objectForKey:@"blockId"] isKindOfClass:[NSString class]]) {
            self.blockId = [json objectForKey:@"blockId"];
        }

        self.eventData = [[NSMutableDictionary alloc] init];
        if ([json objectForKey:@"event"] != nil && ![[json objectForKey:@"event"] isKindOfClass:[NSNull class]] && [[json objectForKey:@"event"] isKindOfClass:[NSDictionary class]]) {
            self.eventData = [[json objectForKey:@"event"] mutableCopy];
        }

        self.eventProperties = [NSMutableArray new];
        if ([json objectForKey:@"eventProperties"] != nil) {
            for (NSDictionary *eventPropertyJson in [json objectForKey:@"eventProperties"]) {
                [self.eventProperties addObject:eventPropertyJson];
            }
        }
    }
    return self;
}

@end
