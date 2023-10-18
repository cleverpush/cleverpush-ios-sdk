#import "CPAppBannerEventFilters.h"

@implementation CPAppBannerEventFilters

#pragma mark - wrapping the data of the banner in to CPAppBanner NSObject
- (id)initWithJson:(NSDictionary*)json {
    self = [super init];
    if (self) {

        if ([json objectForKey:@"event"] && [[json objectForKey:@"event"] isKindOfClass:[NSString class]]) {
            self.event = [json objectForKey:@"event"];
        }

        if ([json objectForKey:@"property"] && [[json objectForKey:@"property"] isKindOfClass:[NSString class]]) {
            self.property = [json objectForKey:@"property"];
        }

        if ([json objectForKey:@"value"] && [[json objectForKey:@"value"] isKindOfClass:[NSString class]]) {
            self.value = [json objectForKey:@"value"];
        }

        if ([json objectForKey:@"relation"] && [[json objectForKey:@"relation"] isKindOfClass:[NSString class]]) {
            self.relation = [json objectForKey:@"relation"];
        }

        if ([json objectForKey:@"fromValue"] && [[json objectForKey:@"fromValue"] isKindOfClass:[NSString class]]) {
            self.fromValue = [json objectForKey:@"fromValue"];
        }

        if ([json objectForKey:@"toValue"] && [[json objectForKey:@"toValue"] isKindOfClass:[NSString class]]) {
            self.toValue = [json objectForKey:@"toValue"];
        }
    }
    return self;
}

@end
